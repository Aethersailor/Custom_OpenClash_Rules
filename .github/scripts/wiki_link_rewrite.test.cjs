const assert = require('node:assert/strict')
const fs = require('node:fs')
const path = require('node:path')
const test = require('node:test')
const vm = require('node:vm')

const scriptPath = path.resolve(__dirname, '../../wiki/assets/wiki-link-rewrite.js')
const scriptSource = fs.readFileSync(scriptPath, 'utf8')


function createElement(attributes) {
  const values = new Map(Object.entries(attributes))
  return {
    getAttribute(name) {
      return values.get(name) ?? null
    },
    setAttribute(name, value) {
      values.set(name, value)
    },
  }
}


function runRewrite({
  links = [],
  images = [],
  location = 'https://aethersailor.github.io/Custom_OpenClash_Rules/',
  scope = 'https://aethersailor.github.io/Custom_OpenClash_Rules/',
} = {}) {
  const pageURL = new URL(location)
  const document = {
    readyState: 'complete',
    querySelectorAll(selector) {
      if (selector === 'a[href]') return links
      if (selector === 'img[src]') return images
      return []
    },
    addEventListener() {
      throw new Error('unexpected event listener registration')
    },
  }
  const context = {
    URL,
    __md_scope: new URL(scope),
    document,
    window: {
      location: {
        href: pageURL.href,
        origin: pageURL.origin,
      },
    },
  }

  vm.runInNewContext(scriptSource, context, { filename: scriptPath })
}


test('rewrites GitHub wiki links to numbered Pages links and preserves fragments', () => {
  const localPage = createElement({
    href: '/Custom_OpenClash_Rules/1.Home/',
  })
  const wikiLink = createElement({
    href: 'https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/Home#getting-started',
  })

  runRewrite({ links: [localPage, wikiLink] })

  assert.equal(
    wikiLink.getAttribute('href'),
    '/Custom_OpenClash_Rules/1.Home/#getting-started',
  )
})


test('rewrites supported doc image paths relative to the MkDocs site root', () => {
  const paths = [
    'doc/direct.png',
    './doc/current.png',
    '../doc/parent.png',
    '/doc/root.png',
  ]
  const images = paths.map(src => createElement({ src }))

  runRewrite({ images })

  assert.deepEqual(
    images.map(image => image.getAttribute('src')),
    [
      'https://aethersailor.github.io/Custom_OpenClash_Rules/doc/direct.png',
      'https://aethersailor.github.io/Custom_OpenClash_Rules/doc/current.png',
      'https://aethersailor.github.io/Custom_OpenClash_Rules/doc/parent.png',
      'https://aethersailor.github.io/Custom_OpenClash_Rules/doc/root.png',
    ],
  )
})


test('leaves external and unrelated image paths unchanged', () => {
  const paths = [
    'https://example.com/image.png',
    '//cdn.example.com/image.png',
    'assets/image.png',
    'data:image/png;base64,AAAA',
  ]
  const images = paths.map(src => createElement({ src }))

  runRewrite({ images })

  assert.deepEqual(images.map(image => image.getAttribute('src')), paths)
})


test('ignores malformed links without aborting the rewrite pass', () => {
  const malformedLink = createElement({ href: 'https://[invalid' })

  assert.doesNotThrow(() => runRewrite({ links: [malformedLink] }))
  assert.equal(malformedLink.getAttribute('href'), 'https://[invalid')
})
