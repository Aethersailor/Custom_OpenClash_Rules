/**
 * Sub-Store IPv6 出站节点过滤器（Node.js + HTTP-META）
 *
 * 用途：实际通过每个代理节点访问 IPv6-only 目标，判断节点是否具备 IPv6 出站能力，
 * 并根据参数选择过滤节点，或在节点名称前添加出站能力标记。
 * 本脚本判断的是代理节点的出口网络能力，与节点服务器入口使用 IPv4、IPv6 或域名无关。
 *
 * 检测流程：先测试 IPv6 出站；仅在 IPv6 出站测试失败时进行一次 IPv4 出站对照测试，
 * 不重试。supported 缓存 12 小时，unsupported 缓存 1 小时，unknown 不缓存。
 *
 * 默认参数：
 * - http_meta_host: 127.0.0.1
 * - http_meta_port: 9876
 * - timeout: 单节点单次出站探测超时，默认 3000ms
 * - concurrency: 并发数，默认 10
 * - max_duration: 脚本总预算，默认 45000ms（为 Sub-Store 的 50000ms 限制留余量）
 * - http_meta_start_delay: Mihomo 启动等待，默认 1500ms
 * - cache: 是否使用缓存，默认 true
 * - positive_cache_ttl: 支持 IPv6 出站的结果缓存，默认 12 小时
 * - negative_cache_ttl: 确认不支持 IPv6 出站的结果缓存，默认 1 小时
 * - filter: 是否只保留确认支持 IPv6 出站的节点，默认 true
 * - mark: 是否给节点名添加出站能力标记，默认 false
 * - mark_ipv6: 支持 IPv6 出站的节点名前缀，默认 [IPv6] （兼容旧参数 mark_text）
 * - mark_ipv4: IPv4 出站可用但 IPv6 出站不可用的节点名前缀，默认 [IPv4]
 * - mark_unknown: 无法确认 IPv6 出站能力的节点名前缀，默认 [Unknown]
 * - test_url: IPv6-only 出站测试地址，默认 https://ipv6.google.com/generate_204
 * - expected_status: IPv6 出站测试预期状态码，默认 204
 * - control_url: IPv4-only 出站对照地址，默认 https://api4.ipify.org?format=json
 * - control_expected_status: IPv4 出站对照测试预期状态码，默认 200
 */

async function operator(proxies = [], targetPlatform, context) {
  const $ = $substore
  const args = $arguments || {}

  if (!Array.isArray(proxies) || proxies.length === 0) return []

  const startedAt = Date.now()
  const maxDuration = numberArg(args.max_duration, 45000, 10000, 48000)
  const stopReserve = numberArg(args.stop_reserve, 2500, 1000, 5000)
  const deadline = startedAt + maxDuration

  const httpMetaProtocol = String(args.http_meta_protocol || 'http')
  const httpMetaHost = String(args.http_meta_host || '127.0.0.1')
  const httpMetaPort = numberArg(args.http_meta_port, 9876, 1, 65535)
  const httpMetaAuthorization = String(args.http_meta_authorization || '')
  const httpMetaApi = `${httpMetaProtocol}://${httpMetaHost}:${httpMetaPort}`

  const timeout = numberArg(args.timeout, 3000, 500, 10000)
  const concurrency = numberArg(args.concurrency, 10, 1, 100)
  const startDelay = numberArg(args.http_meta_start_delay, 1500, 0, 10000)
  const expectedStatus = numberArg(args.expected_status, 204, 100, 599)
  const cacheEnabled = booleanArg(args.cache, true)
  const positiveCacheTTL = numberArg(
    args.positive_cache_ttl,
    12 * 60 * 60 * 1000,
    60 * 1000,
    30 * 24 * 60 * 60 * 1000,
  )
  const negativeCacheTTL = numberArg(
    args.negative_cache_ttl,
    60 * 60 * 1000,
    60 * 1000,
    7 * 24 * 60 * 60 * 1000,
  )
  const filterEnabled = booleanArg(args.filter, true)
  const markEnabled = booleanArg(args.mark, false)
  const markIPv6 = decodeArg(args.mark_ipv6 ?? args.mark_text, '[IPv6] ')
  const markIPv4 = decodeArg(args.mark_ipv4, '[IPv4] ')
  const markUnknown = decodeArg(args.mark_unknown, '[Unknown] ')
  const includeUnsupportedProxy = booleanArg(
    args.include_unsupported_proxy,
    false,
  )
  const testURL = decodeArg(
    args.test_url,
    'https://ipv6.google.com/generate_204',
  )
  const controlURL = decodeArg(
    args.control_url,
    'https://api4.ipify.org?format=json',
  )
  const controlExpectedStatus = numberArg(
    args.control_expected_status,
    200,
    100,
    599,
  )

  const STATE = {
    SUPPORTED: 'supported',
    UNSUPPORTED: 'unsupported',
    UNKNOWN: 'unknown',
  }

  const candidates = []
  const states = Array(proxies.length).fill(STATE.UNKNOWN)
  let incompatible = 0
  let positiveCacheHits = 0
  let unsupportedCacheHits = 0

  for (let index = 0; index < proxies.length; index++) {
    try {
      const cloned = JSON.parse(JSON.stringify(proxies[index]))
      const node = ProxyUtils.produce([cloned], 'ClashMeta', 'internal', {
        'include-unsupported-proxy': includeUnsupportedProxy,
        'delete-underscore-fields': true,
      })?.[0]

      // HTTP-META 会重命名节点，无法安全保留 dialer-proxy 引用。
      if (!node || node['dialer-proxy']) {
        incompatible++
        continue
      }

      const cacheKey = createCacheKey(node)
      const cached = getCachedResult(cacheKey)
      if (cached?.state === STATE.SUPPORTED) {
        states[index] = STATE.SUPPORTED
        positiveCacheHits++
        continue
      }
      if (cached?.state === STATE.UNSUPPORTED) {
        states[index] = STATE.UNSUPPORTED
        unsupportedCacheHits++
        continue
      }

      candidates.push({ index, node, cacheKey })
    } catch (error) {
      incompatible++
      $.warn(
        `[IPv6] 节点转换失败 ${proxies[index]?.name || index}: ${error.message ?? error}`,
      )
    }
  }

  if (candidates.length === 0) {
    const output = buildOutput()
    $.info(
      `[IPv6] 无需测试：输入=${proxies.length}，支持缓存=${positiveCacheHits}，` +
        `不支持缓存=${unsupportedCacheHits}，不兼容=${incompatible}，输出=${output.length}`,
    )
    return output
  }

  const metaHeaders = { 'Content-Type': 'application/json' }
  if (httpMetaAuthorization) metaHeaders.Authorization = httpMetaAuthorization

  let httpMetaPID
  let tested = 0
  let controlTested = 0
  let deadlineSkipped = 0

  try {
    const startRequestBudget = remainingProbeBudget()
    if (startRequestBudget < 1000) {
      throw new Error('准备节点已耗尽执行时间预算')
    }

    const started = await $.http.post({
      url: `${httpMetaApi}/start`,
      headers: metaHeaders,
      body: JSON.stringify({
        proxies: candidates.map(item => item.node),
        // 即使脚本异常退出，HTTP-META 也会自动回收临时 Mihomo。
        timeout: maxDuration + 10000,
      }),
      timeout: Math.min(10000, startRequestBudget),
    })

    const body = parseJSON(started.body)
    httpMetaPID = body?.pid
    const ports = Array.isArray(body?.ports) ? body.ports : []

    if (!httpMetaPID || ports.length !== candidates.length) {
      throw new Error(
        `HTTP-META 启动结果无效：期望 ${candidates.length} 个端口，实际 ${ports.length}`,
      )
    }

    const waitTime = Math.min(startDelay, Math.max(0, remainingProbeBudget()))
    if (waitTime > 0) await $.wait(waitTime)

    let next = 0
    const workerCount = Math.min(concurrency, candidates.length)

    async function worker() {
      while (true) {
        const position = next++
        if (position >= candidates.length) return

        const requestBudget = remainingProbeBudget()
        if (requestBudget < 500) {
          deadlineSkipped += candidates.length - position
          next = candidates.length
          return
        }

        tested++
        const state = await classifyNode(ports[position], requestBudget)
        states[candidates[position].index] = state
        if (state !== STATE.UNKNOWN) {
          setCachedResult(
            candidates[position].cacheKey,
            state,
            state === STATE.SUPPORTED ? positiveCacheTTL : negativeCacheTTL,
          )
        }
      }
    }

    await Promise.all(Array.from({ length: workerCount }, () => worker()))
  } catch (error) {
    $.error(`[IPv6] 检测失败：${error.message ?? error}`)
  } finally {
    if (httpMetaPID) {
      try {
        await $.http.post({
          url: `${httpMetaApi}/stop`,
          headers: metaHeaders,
          body: JSON.stringify({ pid: [httpMetaPID] }),
          timeout: Math.max(500, Math.min(2000, deadline - Date.now())),
        })
      } catch (error) {
        $.warn(`[IPv6] HTTP-META 回收失败：${error.message ?? error}`)
      }
    }
  }

  const output = buildOutput()
  const supportedCount = states.filter(state => state === STATE.SUPPORTED).length
  const unsupportedCount = states.filter(
    state => state === STATE.UNSUPPORTED,
  ).length
  const unknownCount = states.length - supportedCount - unsupportedCount
  $.info(
    `[IPv6] 完成：输入=${proxies.length}，可测试=${candidates.length}，` +
      `IPv6测试=${tested}，IPv4对照=${controlTested}，支持=${supportedCount}，` +
      `不支持=${unsupportedCount}，unknown=${unknownCount}，输出=${output.length}，` +
      `时间预算跳过=${deadlineSkipped}，` +
      `支持缓存命中=${positiveCacheHits}，不支持缓存命中=${unsupportedCacheHits}，` +
      `不兼容=${incompatible}，耗时=${Date.now() - startedAt}ms`,
  )
  return output

  function buildOutput() {
    const markers = [
      ...new Set([
        markIPv6,
        markIPv4,
        markUnknown,
        '[IPv6] ',
        '[IPv4] ',
        '[Unknown] ',
      ]),
    ]
      .filter(Boolean)
      .sort((a, b) => b.length - a.length)

    return proxies.reduce((output, proxy, index) => {
      const state = states[index]
      if (filterEnabled && state !== STATE.SUPPORTED) return output
      if (!markEnabled) {
        output.push(proxy)
        return output
      }

      const marker =
        state === STATE.SUPPORTED
          ? markIPv6
          : state === STATE.UNSUPPORTED
            ? markIPv4
            : markUnknown
      const name = stripKnownMarkers(String(proxy.name ?? ''), markers)
      output.push({ ...proxy, name: `${marker}${name}` })
      return output
    }, [])
  }

  function stripKnownMarkers(name, markers) {
    let result = name
    let changed = true
    while (changed) {
      changed = false
      for (const marker of markers) {
        if (result.startsWith(marker)) {
          result = result.slice(marker.length)
          changed = true
          break
        }
      }
    }
    return result
  }

  async function classifyNode(port, requestBudget) {
    if (await requestExpectedStatus(port, testURL, expectedStatus, requestBudget)) {
      return STATE.SUPPORTED
    }

    const controlBudget = remainingProbeBudget()
    if (controlBudget < 500) return STATE.UNKNOWN

    controlTested++
    if (await requestIPv4Control(port, controlBudget)) {
      return STATE.UNSUPPORTED
    }
    return STATE.UNKNOWN
  }

  async function requestIPv4Control(port, requestBudget) {
    try {
      const response = await $.http.get({
        url: controlURL,
        proxy: `http://${httpMetaHost}:${port}`,
        timeout: Math.min(timeout, requestBudget),
        headers: { 'Cache-Control': 'no-cache' },
      })
      const status = Number(response?.statusCode ?? response?.status ?? 0)
      const body = parseJSON(response?.body)
      return (
        status === controlExpectedStatus &&
        typeof body?.ip === 'string' &&
        ProxyUtils.isIPv4(body.ip.trim())
      )
    } catch {
      return false
    }
  }

  async function requestExpectedStatus(port, url, status, requestBudget) {
    try {
      const response = await $.http.get({
        url,
        proxy: `http://${httpMetaHost}:${port}`,
        timeout: Math.min(timeout, requestBudget),
        headers: { 'Cache-Control': 'no-cache' },
      })
      return Number(response?.statusCode ?? response?.status ?? 0) === status
    } catch {
      return false
    }
  }

  function remainingProbeBudget() {
    return Math.max(0, deadline - Date.now() - stopReserve)
  }

  function createCacheKey(node) {
    const copy = JSON.parse(JSON.stringify(node))
    delete copy.name
    const nodeFingerprint = ProxyUtils.hex_md5(stableStringify(copy))
    const targetFingerprint = ProxyUtils.hex_md5(
      `${testURL}|${expectedStatus}|${controlURL}|${controlExpectedStatus}`,
    )
    return `http-meta:ipv6-egress:v3:${targetFingerprint}:${nodeFingerprint}`
  }

  function getCachedResult(cacheKey) {
    if (!cacheEnabled) return null
    try {
      return scriptResourceCache.get(cacheKey)
    } catch (error) {
      $.warn(`[IPv6] 读取缓存失败：${error.message ?? error}`)
      return null
    }
  }

  function setCachedResult(cacheKey, state, ttl) {
    if (!cacheEnabled) return
    try {
      scriptResourceCache.set(cacheKey, { state, checkedAt: Date.now() }, ttl)
    } catch (error) {
      $.warn(`[IPv6] 写入缓存失败：${error.message ?? error}`)
    }
  }

  function stableStringify(value) {
    if (Array.isArray(value)) {
      return `[${value.map(stableStringify).join(',')}]`
    }
    if (value && typeof value === 'object') {
      return `{${Object.keys(value)
        .sort()
        .map(key => `${JSON.stringify(key)}:${stableStringify(value[key])}`)
        .join(',')}}`
    }
    return JSON.stringify(value)
  }

  function parseJSON(value) {
    if (value && typeof value === 'object') return value
    try {
      return JSON.parse(value)
    } catch {
      return null
    }
  }

  function numberArg(value, fallback, min, max) {
    const number = Number(value)
    if (!Number.isFinite(number)) return fallback
    return Math.min(max, Math.max(min, Math.trunc(number)))
  }

  function booleanArg(value, fallback) {
    if (value == null || value === '') return fallback
    if (typeof value === 'boolean') return value
    return !/^(0|false|no|off)$/i.test(String(value).trim())
  }

  function decodeArg(value, fallback) {
    if (value == null || value === '') return fallback
    try {
      return decodeURIComponent(String(value))
    } catch {
      return String(value)
    }
  }
}
