import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import { SourceTextModule, SyntheticModule } from "node:vm";
import { MIRROR_CONFIG } from "../src/config.js";

async function load(file, timeout = 20) {
  const source = await readFile(
    new URL(`../src/${file}`, import.meta.url),
    "utf8",
  );
  const module = new SourceTextModule(source);
  const config = {
    ...MIRROR_CONFIG,
    probeTimeoutMs: timeout,
    cloudflareApiTimeoutMs: timeout,
  };
  await module.link(
    () =>
      new SyntheticModule(["MIRROR_CONFIG"], function () {
        this.setExport("MIRROR_CONFIG", config);
      }),
  );
  await module.evaluate();
  return module.namespace;
}

function responseWithUrl(body, url) {
  const response = new Response(body);
  Object.defineProperty(response, "url", { value: String(url) });
  return response;
}

function stalledBody(signal) {
  return new ReadableStream({
    start(controller) {
      signal.addEventListener(
        "abort",
        () => controller.error(new DOMException("timeout", "AbortError")),
        { once: true },
      );
    },
  });
}

async function within(promise) {
  let timer;
  try {
    return await Promise.race([
      promise,
      new Promise((_, reject) => {
        timer = setTimeout(
          () => reject(new Error("body deadline was not enforced")),
          500,
        );
      }),
    ]);
  } finally {
    clearTimeout(timer);
  }
}

test("probe deadlines include a response body stalled after successful headers", async (t) => {
  const probes = await load("probes.js");
  t.mock.method(globalThis, "fetch", async (url, options) =>
    responseWithUrl(
      options.method === "HEAD" ? null : stalledBody(options.signal),
      url,
    ),
  );
  const result = await within(
    probes.runHealthChecks({
      ASSETS: {
        async fetch() {
          return new Response(null, { status: 404 });
        },
      },
    }),
  );
  for (const name of ["github_api", "github_raw", "jsdelivr"]) {
    assert.equal(
      result.probes.find((probe) => probe.name === name).code,
      "timeout",
    );
  }
  assert.equal(result.outcome, "unknown");
});

test("ordinary response bodies still produce healthy availability results", async (t) => {
  const probes = await load("probes.js", 1000);
  t.mock.method(globalThis, "fetch", async (url, options) =>
    responseWithUrl(
      options.method === "HEAD"
        ? null
        : String(url) === MIRROR_CONFIG.githubApiUrl
          ? JSON.stringify({ sha: "a".repeat(40) })
          : "example.com\n",
      url,
    ),
  );
  const result = await probes.runHealthChecks({
    ASSETS: {
      async fetch() {
        return new Response(null, { status: 404 });
      },
    },
  });
  assert.equal(result.outcome, "healthy");
});

test("Cloudflare reconciliation also bounds a stalled JSON envelope", async (t) => {
  const rules = await load("cloudflare-rules.js");
  t.mock.method(globalThis, "fetch", async (url, options) =>
    responseWithUrl(stalledBody(options.signal), url),
  );
  await assert.rejects(
    within(
      rules.reconcileRedirectRules(
        { CF_ZONE_ID: "test", CF_REDIRECT_API_TOKEN: "test-only" },
        true,
      ),
    ),
    (error) => error.code === "cloudflare_api_timeout",
  );
});
