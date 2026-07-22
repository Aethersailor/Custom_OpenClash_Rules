const assert = require('node:assert/strict')
const test = require('node:test')

const { operator } = require('../../script/sub-store/sub-store-ipv6-egress-filter.js')


function installGlobals({ args = {}, get, post, cachedStates = new Map() } = {}) {
  const writes = []
  global.$arguments = args
  global.ProxyUtils = {
    produce(nodes) {
      return nodes
    },
    hex_md5(value) {
      return value
    },
    isIPv4(value) {
      return /^\d{1,3}(?:\.\d{1,3}){3}$/.test(value)
    },
  }
  global.scriptResourceCache = {
    get(key) {
      for (const [needle, state] of cachedStates) {
        if (key.includes(needle)) return { state }
      }
      return null
    },
    set(key, value, ttl) {
      writes.push({ key, value, ttl })
    },
  }
  global.$substore = {
    http: {
      get: get || (async () => {
        throw new Error('unexpected GET')
      }),
      post: post || (async () => {
        throw new Error('unexpected POST')
      }),
    },
    wait: async () => {},
    info: () => {},
    warn: () => {},
    error: () => {},
  }
  return writes
}


test.afterEach(() => {
  delete global.$arguments
  delete global.$substore
  delete global.ProxyUtils
  delete global.scriptResourceCache
})


test('default filter keeps only positively cached IPv6 egress nodes', async () => {
  installGlobals({
    cachedStates: new Map([
      ['server-v6', 'supported'],
      ['server-v4', 'unsupported'],
    ]),
  })
  const proxies = [
    { name: 'v6', server: 'server-v6' },
    { name: 'v4', server: 'server-v4' },
  ]

  assert.deepEqual(await operator(proxies), [proxies[0]])
})


test('live probes preserve supported unsupported and unknown states', async () => {
  const stopped = []
  const writes = installGlobals({
    args: {
      filter: false,
      mark: true,
      http_meta_start_delay: 0,
      positive_cache_ttl: 7200000,
      negative_cache_ttl: 600000,
    },
    post: async request => {
      if (request.url.endsWith('/start')) {
        return { body: JSON.stringify({ pid: 42, ports: [10001, 10002, 10003] }) }
      }
      stopped.push(JSON.parse(request.body).pid)
      return { body: '{}' }
    },
    get: async request => {
      if (request.proxy.endsWith(':10001')) return { statusCode: 204, body: '' }
      if (request.proxy.endsWith(':10002') && request.url.includes('api4.ipify.org')) {
        return { statusCode: 200, body: JSON.stringify({ ip: '192.0.2.1' }) }
      }
      throw new Error('probe unavailable')
    },
  })

  const output = await operator([
    { name: '[IPv4] alpha', server: 'alpha' },
    { name: '[Unknown] beta', server: 'beta' },
    { name: 'gamma', server: 'gamma' },
  ])

  assert.deepEqual(output.map(proxy => proxy.name), [
    '[IPv6] alpha',
    '[IPv4] beta',
    '[Unknown] gamma',
  ])
  assert.deepEqual(writes.map(write => [write.value.state, write.ttl]), [
    ['supported', 7200000],
    ['unsupported', 600000],
  ])
  assert.deepEqual(stopped, [[42]])
})


test('HTTP-META startup failure remains unknown and is never cached', async () => {
  const writes = installGlobals({
    args: { filter: false, mark: true },
    post: async () => {
      throw new Error('HTTP-META unavailable')
    },
  })

  const output = await operator([{ name: 'node', server: 'node.example' }])

  assert.equal(output[0].name, '[Unknown] node')
  assert.deepEqual(writes, [])
})
