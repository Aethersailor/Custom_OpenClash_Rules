/**
 * Sub-Store IPv6 出站过滤器（Node.js + HTTP-META）
 *
 * 只保留能够通过节点访问 IPv6-only 目标的节点。
 * IPv6 失败后才进行一次 IPv4 对照测试，不重试。
 * supported 缓存 12 小时，unsupported 缓存 1 小时，unknown 不缓存。
 *
 * 默认参数：
 * - http_meta_host: 127.0.0.1
 * - http_meta_port: 9876
 * - timeout: 单节点探测超时，默认 3000ms
 * - concurrency: 并发数，默认 10
 * - max_duration: 脚本总预算，默认 45000ms（为 Sub-Store 的 50000ms 限制留余量）
 * - http_meta_start_delay: Mihomo 启动等待，默认 1500ms
 * - cache: 是否使用缓存，默认 true
 * - positive_cache_ttl: 成功缓存，默认 12 小时
 * - negative_cache_ttl: 失败缓存，默认 1 小时
 * - test_url: 默认 https://ipv6.google.com/generate_204
 * - expected_status: 默认 204
 * - control_url: 默认 https://api4.ipify.org?format=json（仅提供 IPv4）
 * - control_expected_status: 默认 200
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
  const supportedIndexes = new Set()
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
        supportedIndexes.add(index)
        positiveCacheHits++
        continue
      }
      if (cached?.state === STATE.UNSUPPORTED) {
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
    const output = proxies.filter((_, index) => supportedIndexes.has(index))
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
  let unknown = 0
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
        if (state === STATE.SUPPORTED) {
          supportedIndexes.add(candidates[position].index)
        }
        if (state === STATE.UNKNOWN) {
          unknown++
        } else {
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

  const output = proxies.filter((_, index) => supportedIndexes.has(index))
  $.info(
    `[IPv6] 完成：输入=${proxies.length}，可测试=${candidates.length}，` +
      `IPv6测试=${tested}，IPv4对照=${controlTested}，支持=${output.length}，` +
      `unknown=${unknown}，时间预算跳过=${deadlineSkipped}，` +
      `支持缓存命中=${positiveCacheHits}，不支持缓存命中=${unsupportedCacheHits}，` +
      `不兼容=${incompatible}，耗时=${Date.now() - startedAt}ms`,
  )
  return output

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
