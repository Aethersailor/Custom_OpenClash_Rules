/**
 * Sub-Store IPv6 出站过滤器（Node.js + HTTP-META）
 *
 * 用法：添加为「脚本操作」，脚本会返回仅包含已验证支持 IPv6 出站的节点列表。
 *
 * 默认检测流程：
 * 1. 经节点请求 api6.ipify.org，并验证响应中的出口地址确实是 IPv6；
 * 2. 若失败，再请求 ipv6.google.com/generate_204 复核；
 * 3. 两个 IPv6 目标都失败时，请求 IPv4 控制地址：
 *    - IPv4 成功：确认节点可用但不支持 IPv6 出站；
 *    - IPv4 也失败：状态为 unknown（节点失效、超时或测试环境异常）。
 *
 * 常用参数：
 * - http_meta_host: HTTP-META 地址，默认 127.0.0.1
 * - http_meta_port: HTTP-META 端口，默认 9876
 * - http_meta_authorization: HTTP-META Authorization，默认空
 * - timeout: 单次请求超时，默认 5000ms
 * - retries: 每个测试地址的重试次数，默认 1
 * - retry_delay: 重试间隔，默认 700ms
 * - concurrency: 并发节点数，默认 8
 * - http_meta_start_delay: Mihomo 启动等待时间，默认 3000ms
 * - cache: 是否缓存确定结果，默认 true
 * - positive_cache_ttl: 成功缓存时长，默认 12 小时
 * - negative_cache_ttl: 确认不支持的缓存时长，默认 1 小时
 * - keep_unknown: 是否保留无法确认的节点，默认 false
 * - fail_open: HTTP-META 整体故障时是否返回原列表，默认 true
 * - mark: 是否给保留节点名添加标记，默认 false
 * - mark_text: 节点名前缀，默认 [IPv6]
 *
 * 可覆盖的测试地址：
 * - primary_url: 默认 https://api6.ipify.org?format=json
 * - fallback_url: 默认 https://ipv6.google.com/generate_204
 * - control_url: 默认 https://www.gstatic.com/generate_204
 */

async function operator(proxies = [], targetPlatform, context) {
  const $ = $substore
  const args = $arguments || {}

  if (!Array.isArray(proxies) || proxies.length === 0) return []

  const httpMetaProtocol = String(args.http_meta_protocol || 'http')
  const httpMetaHost = String(args.http_meta_host || '127.0.0.1')
  const httpMetaPort = numberArg(args.http_meta_port, 9876, 1, 65535)
  const httpMetaAuthorization = String(args.http_meta_authorization || '')
  const httpMetaApi = `${httpMetaProtocol}://${httpMetaHost}:${httpMetaPort}`

  const timeout = numberArg(args.timeout, 5000, 1000, 60000)
  const retries = numberArg(args.retries, 1, 0, 5)
  const retryDelay = numberArg(args.retry_delay, 700, 0, 10000)
  const concurrency = numberArg(args.concurrency, 8, 1, 50)
  const startDelay = numberArg(args.http_meta_start_delay, 3000, 0, 30000)
  const proxyLifetime = numberArg(args.http_meta_proxy_timeout, 15000, 5000, 120000)

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
  const keepUnknown = booleanArg(args.keep_unknown, false)
  const failOpen = booleanArg(args.fail_open, true)
  const mark = booleanArg(args.mark, false)
  const markText = String(args.mark_text || '[IPv6] ')
  const includeUnsupportedProxy = booleanArg(args.include_unsupported_proxy, false)

  const primaryURL = decodeArg(
    args.primary_url,
    'https://api6.ipify.org?format=json',
  )
  const fallbackURL = decodeArg(
    args.fallback_url,
    'https://ipv6.google.com/generate_204',
  )
  const controlURL = decodeArg(
    args.control_url,
    'https://www.gstatic.com/generate_204',
  )

  const STATE = {
    SUPPORTED: 'supported',
    UNSUPPORTED: 'unsupported',
    UNKNOWN: 'unknown',
  }
  const states = Array(proxies.length).fill(STATE.UNKNOWN)
  const details = Array(proxies.length).fill(null)
  const pending = []
  let cacheHits = 0
  let incompatibleCount = 0

  for (let index = 0; index < proxies.length; index++) {
    const original = proxies[index]
    try {
      const cloned = JSON.parse(JSON.stringify(original))
      const node = ProxyUtils.produce([cloned], 'ClashMeta', 'internal', {
        'include-unsupported-proxy': includeUnsupportedProxy,
        'delete-underscore-fields': true,
      })?.[0]

      if (!node) {
        incompatibleCount++
        continue
      }

      // HTTP-META 会把节点重命名为 proxy-N，无法安全重写前置代理引用。
      // 与其改变节点语义后误判，不如把这类节点标为 unknown。
      if (node['dialer-proxy']) {
        incompatibleCount++
        $.warn(`[IPv6] 跳过带前置代理的节点：${original.name}`)
        continue
      }

      const cacheKey = createCacheKey(node)
      if (cacheEnabled) {
        const cached = scriptResourceCache.get(cacheKey)
        if (
          cached &&
          [STATE.SUPPORTED, STATE.UNSUPPORTED].includes(cached.state)
        ) {
          states[index] = cached.state
          details[index] = cached
          cacheHits++
          continue
        }
      }

      pending.push({ index, node, cacheKey })
    } catch (error) {
      incompatibleCount++
      $.error(`[IPv6] 节点转换失败 ${original.name}: ${error.message ?? error}`)
    }
  }

  if (pending.length === 0) {
    const definitive = states.some(state => state !== STATE.UNKNOWN)
    if (!definitive && failOpen) {
      $.warn('[IPv6] 没有可测试节点，为避免清空订阅，返回原节点列表')
      return proxies
    }
    return buildOutput()
  }

  const metaHeaders = { 'Content-Type': 'application/json' }
  if (httpMetaAuthorization) {
    metaHeaders.Authorization = httpMetaAuthorization
  }

  const httpMetaTimeout = startDelay + pending.length * proxyLifetime
  let httpMetaPID
  let httpMetaPorts = []
  let globalFailure

  try {
    const started = await request({
      method: 'post',
      url: `${httpMetaApi}/start`,
      headers: metaHeaders,
      body: JSON.stringify({
        proxies: pending.map(item => item.node),
        timeout: httpMetaTimeout,
      }),
      timeout: Math.max(timeout, 10000),
      retries: 0,
    })

    const body = parseJSON(started.body)
    httpMetaPID = body?.pid
    httpMetaPorts = Array.isArray(body?.ports) ? body.ports : []

    if (!httpMetaPID || httpMetaPorts.length !== pending.length) {
      throw new Error(
        `HTTP-META 启动结果无效：期望 ${pending.length} 个端口，实际 ${httpMetaPorts.length}`,
      )
    }

    $.info(
      `[IPv6] HTTP-META 已启动：PID=${httpMetaPID}，待测=${pending.length}，并发=${concurrency}`,
    )
    if (startDelay > 0) await $.wait(startDelay)

    await runWithConcurrency(
      pending.map((item, position) => async () => {
        const result = await probeNode(httpMetaPorts[position])
        states[item.index] = result.state
        details[item.index] = result

        if (cacheEnabled && result.state === STATE.SUPPORTED) {
          scriptResourceCache.set(item.cacheKey, result, positiveCacheTTL)
        } else if (cacheEnabled && result.state === STATE.UNSUPPORTED) {
          scriptResourceCache.set(item.cacheKey, result, negativeCacheTTL)
        }

        const label =
          result.state === STATE.SUPPORTED
            ? `支持${result.ip ? `，出口 ${result.ip}` : ''}`
            : result.state === STATE.UNSUPPORTED
              ? '不支持（IPv4 控制请求正常）'
              : '未知（节点或测试目标不可用）'
        $.info(`[IPv6] ${proxies[item.index].name}: ${label}`)
      }),
      concurrency,
    )
  } catch (error) {
    globalFailure = error
    $.error(`[IPv6] 检测流程失败：${error.message ?? error}`)
  } finally {
    if (httpMetaPID) {
      try {
        await request({
          method: 'post',
          url: `${httpMetaApi}/stop`,
          headers: metaHeaders,
          body: JSON.stringify({ pid: [httpMetaPID] }),
          timeout: Math.max(timeout, 10000),
          retries: 0,
        })
        $.info(`[IPv6] HTTP-META 已关闭：PID=${httpMetaPID}`)
      } catch (error) {
        $.error(`[IPv6] HTTP-META 关闭失败：${error.message ?? error}`)
      }
    }
  }

  if (globalFailure && failOpen) {
    $.warn('[IPv6] fail_open=true，为避免测试器故障清空订阅，返回原节点列表')
    return proxies
  }

  if (
    failOpen &&
    !states.some(
      state => state === STATE.SUPPORTED || state === STATE.UNSUPPORTED,
    )
  ) {
    $.warn('[IPv6] 全部节点均为 unknown，视为检测环境异常并返回原节点列表')
    return proxies
  }

  return buildOutput()

  async function probeNode(port) {
    const localProxy = `http://${httpMetaHost}:${port}`
    const errors = []

    // 强判定：IPv6-only IP 查询服务必须返回一个真正的 IPv6 地址。
    try {
      const startedAt = Date.now()
      const response = await request({
        method: 'get',
        url: primaryURL,
        proxy: localProxy,
        headers: { Accept: 'application/json,text/plain;q=0.9,*/*;q=0.8' },
        timeout,
        retries,
      })
      const status = getStatus(response)
      const ip = extractIPv6(response.body)
      if (status >= 200 && status < 300 && ip) {
        return {
          state: STATE.SUPPORTED,
          ip,
          latency: Date.now() - startedAt,
          via: 'api6-ipify',
          checkedAt: Date.now(),
        }
      }
      errors.push(`primary status=${status} ip=${ip || 'none'}`)
    } catch (error) {
      errors.push(`primary ${error.message ?? error}`)
    }

    // 复核：严格要求 Google IPv6-only generate_204 返回 204。
    try {
      const startedAt = Date.now()
      const response = await request({
        method: 'head',
        url: fallbackURL,
        proxy: localProxy,
        timeout,
        retries,
      })
      const status = getStatus(response)
      if (status === 204) {
        return {
          state: STATE.SUPPORTED,
          latency: Date.now() - startedAt,
          via: 'google-ipv6-204',
          checkedAt: Date.now(),
        }
      }
      errors.push(`fallback status=${status}`)
    } catch (error) {
      errors.push(`fallback ${error.message ?? error}`)
    }

    // IPv4 控制请求成功，说明节点本身可用，IPv6 失败才有资格判为 unsupported。
    try {
      const response = await request({
        method: 'head',
        url: controlURL,
        proxy: localProxy,
        timeout,
        retries,
      })
      const status = getStatus(response)
      if (status >= 200 && status < 400) {
        return {
          state: STATE.UNSUPPORTED,
          reason: errors.join('; '),
          checkedAt: Date.now(),
        }
      }
      errors.push(`control status=${status}`)
    } catch (error) {
      errors.push(`control ${error.message ?? error}`)
    }

    return {
      state: STATE.UNKNOWN,
      reason: errors.join('; '),
      checkedAt: Date.now(),
    }
  }

  function buildOutput() {
    const output = []
    let supported = 0
    let unsupported = 0
    let unknown = 0

    proxies.forEach((proxy, index) => {
      const state = states[index]
      if (state === STATE.SUPPORTED) {
        supported++
        proxy._ipv6Egress = true
        if (details[index]?.ip) proxy._ipv6EgressIP = details[index].ip
        if (details[index]?.latency != null) {
          proxy._ipv6EgressLatency = details[index].latency
        }
        if (mark && markText && !String(proxy.name).startsWith(markText)) {
          proxy.name = `${markText}${proxy.name}`
        }
        output.push(proxy)
      } else if (state === STATE.UNSUPPORTED) {
        unsupported++
      } else {
        unknown++
        if (keepUnknown) {
          proxy._ipv6Egress = null
          output.push(proxy)
        }
      }
    })

    $.info(
      `[IPv6] 完成：支持=${supported}，确认不支持=${unsupported}，未知=${unknown}，` +
        `不兼容=${incompatibleCount}，缓存命中=${cacheHits}，输出=${output.length}/${proxies.length}`,
    )
    return output
  }

  function createCacheKey(node) {
    const copy = JSON.parse(JSON.stringify(node))
    delete copy.name
    const fingerprint = ProxyUtils.hex_md5(stableStringify(copy))
    const targetFingerprint = ProxyUtils.hex_md5(
      `${primaryURL}|${fallbackURL}|${controlURL}`,
    )
    return `http-meta:ipv6-egress:v1:${targetFingerprint}:${fingerprint}`
  }

  async function request(options = {}) {
    const method = String(options.method || 'get').toLowerCase()
    const maxRetries = numberArg(options.retries, retries, 0, 10)
    const requestTimeout = numberArg(options.timeout, timeout, 100, 120000)
    const requestOptions = { ...options, timeout: requestTimeout }
    delete requestOptions.method
    delete requestOptions.retries

    let lastError
    for (let attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        return await $.http[method](requestOptions)
      } catch (error) {
        lastError = error
        if (attempt < maxRetries && retryDelay > 0) {
          await $.wait(retryDelay * (attempt + 1))
        }
      }
    }
    throw lastError
  }

  function getStatus(response) {
    return Number(response?.statusCode ?? response?.status ?? 0)
  }

  function extractIPv6(body) {
    let value = body
    if (typeof value !== 'string') value = String(value ?? '')
    const parsed = parseJSON(value)
    const candidate =
      parsed && typeof parsed === 'object' ? parsed.ip : value.trim()
    if (typeof candidate !== 'string') return ''
    const normalized = candidate.trim().replace(/^\[|\]$/g, '')
    return ProxyUtils.isIPv6(normalized) ? normalized : ''
  }

  function parseJSON(value) {
    if (value && typeof value === 'object') return value
    try {
      return JSON.parse(value)
    } catch {
      return null
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

  function booleanArg(value, fallback) {
    if (value == null || value === '') return fallback
    if (typeof value === 'boolean') return value
    return !/^(0|false|no|off)$/i.test(String(value).trim())
  }

  function numberArg(value, fallback, min, max) {
    const number = Number(value)
    if (!Number.isFinite(number)) return fallback
    return Math.min(max, Math.max(min, Math.trunc(number)))
  }

  function decodeArg(value, fallback) {
    if (value == null || value === '') return fallback
    try {
      return decodeURIComponent(String(value))
    } catch {
      return String(value)
    }
  }

  function runWithConcurrency(tasks, limit) {
    return new Promise((resolve, reject) => {
      let next = 0
      let running = 0
      let completed = 0
      let settled = false

      const schedule = () => {
        if (settled) return
        if (completed === tasks.length) {
          settled = true
          resolve()
          return
        }

        while (running < limit && next < tasks.length) {
          const task = tasks[next++]
          running++
          Promise.resolve()
            .then(task)
            .then(() => {
              running--
              completed++
              schedule()
            })
            .catch(error => {
              settled = true
              reject(error)
            })
        }
      }

      schedule()
    })
  }
}
