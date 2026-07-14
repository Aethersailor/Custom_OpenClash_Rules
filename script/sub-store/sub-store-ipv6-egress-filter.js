/**
 * Sub-Store IPv6 出站过滤器（Node.js + HTTP-META）
 *
 * 只保留当前能够通过节点访问 IPv6-only 目标的节点。
 * 不检测 IPv4、不重试、不使用缓存；任何失败、超时或未完成测试的节点都会被过滤。
 *
 * 默认参数：
 * - http_meta_host: 127.0.0.1
 * - http_meta_port: 9876
 * - timeout: 单节点探测超时，默认 3000ms
 * - concurrency: 并发数，默认 10
 * - max_duration: 脚本总预算，默认 45000ms（为 Sub-Store 的 50000ms 限制留余量）
 * - http_meta_start_delay: Mihomo 启动等待，默认 1500ms
 * - test_url: 默认 https://ipv6.google.com/generate_204
 * - expected_status: 默认 204
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
  const includeUnsupportedProxy = booleanArg(
    args.include_unsupported_proxy,
    false,
  )
  const testURL = decodeArg(
    args.test_url,
    'https://ipv6.google.com/generate_204',
  )

  const candidates = []
  const supportedIndexes = new Set()
  let incompatible = 0

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

      candidates.push({ index, node })
    } catch (error) {
      incompatible++
      $.warn(
        `[IPv6] 节点转换失败 ${proxies[index]?.name || index}: ${error.message ?? error}`,
      )
    }
  }

  if (candidates.length === 0) {
    $.warn('[IPv6] 没有兼容 HTTP-META 的待测节点，输出 0 个节点')
    return []
  }

  const metaHeaders = { 'Content-Type': 'application/json' }
  if (httpMetaAuthorization) metaHeaders.Authorization = httpMetaAuthorization

  let httpMetaPID
  let tested = 0
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
        if (await supportsIPv6(ports[position], requestBudget)) {
          supportedIndexes.add(candidates[position].index)
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
      `已测试=${tested}，支持=${output.length}，时间预算跳过=${deadlineSkipped}，` +
      `不兼容=${incompatible}，耗时=${Date.now() - startedAt}ms`,
  )
  return output

  async function supportsIPv6(port, requestBudget) {
    try {
      const response = await $.http.get({
        url: testURL,
        proxy: `http://${httpMetaHost}:${port}`,
        timeout: Math.min(timeout, requestBudget),
        headers: { 'Cache-Control': 'no-cache' },
      })
      return Number(response?.statusCode ?? response?.status ?? 0) === expectedStatus
    } catch {
      return false
    }
  }

  function remainingProbeBudget() {
    return Math.max(0, deadline - Date.now() - stopReserve)
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
