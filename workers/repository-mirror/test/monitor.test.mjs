import assert from "node:assert/strict";
import { readFile } from "node:fs/promises";
import { test } from "node:test";
import { SourceTextModule, SyntheticModule } from "node:vm";
import { MIRROR_CONFIG } from "../src/config.js";

const source = await readFile(
  new URL("../src/index.js", import.meta.url),
  "utf8",
);
const module = new SourceTextModule(source);
await module.link((specifier) => {
  const exports =
    specifier === "cloudflare:workers"
      ? { DurableObject: class {} }
      : specifier === "./config.js"
        ? { MIRROR_CONFIG }
        : specifier === "./probes.js"
          ? {
              runHealthChecks() {
                throw new Error("unexpected external work");
              },
            }
          : {
              reconcileRedirectRules() {
                throw new Error("unexpected external work");
              },
              MirrorRuleError: class extends Error {},
            };
  return new SyntheticModule(Object.keys(exports), function () {
    for (const [name, value] of Object.entries(exports))
      this.setExport(name, value);
  });
});
await module.evaluate();

function object(storage, performMonitor) {
  const instance = Object.create(
    module.namespace.RepositoryMirrorState.prototype,
  );
  instance.ctx = {
    storage: {
      async get(key) {
        return storage.get(key);
      },
      async put(key, value) {
        storage.set(key, value);
      },
    },
  };
  instance.monitorPromise = null;
  instance.publicStatus = () => ({ cached: true });
  instance.performMonitor = performMonitor;
  return instance;
}

test("duplicate checks and object recreation reuse the persisted interval", async (t) => {
  let now = 1_000_000;
  t.mock.method(Date, "now", () => now);
  const storage = new Map();
  let checks = 0;
  const monitor = async () => ({ check: ++checks });
  const first = object(storage, monitor);
  assert.deepEqual(await first.runMonitor(), { check: 1 });
  assert.deepEqual(await first.runMonitor(), { cached: true });
  assert.deepEqual(await object(storage, monitor).runMonitor(), {
    cached: true,
  });
  now += MIRROR_CONFIG.minMonitorIntervalMs;
  assert.deepEqual(await object(storage, monitor).runMonitor(), { check: 2 });
  assert.equal(checks, 2);
});

test("a failed check cannot immediately retry after object recreation", async (t) => {
  t.mock.method(Date, "now", () => 1_000_000);
  const storage = new Map();
  await assert.rejects(
    object(storage, async () => {
      throw new Error("network failure");
    }).runMonitor(),
  );
  assert.deepEqual(
    await object(storage, async () => {
      throw new Error("must not run");
    }).runMonitor(),
    { cached: true },
  );
});

test("overlapping checks share one in-flight operation", async (t) => {
  t.mock.method(Date, "now", () => 1_000_000);
  let checks = 0;
  const instance = object(new Map(), async () => ({ check: ++checks }));
  assert.deepEqual(
    await Promise.all([instance.runMonitor(), instance.runMonitor()]),
    [{ check: 1 }, { check: 1 }],
  );
  assert.equal(checks, 1);
});

test("public status rejects missing, failed, and depleted protection before accessing the object", async () => {
  const request = new Request("https://example.com/__mirror/status");
  const worker = module.namespace.default;
  assert.equal((await worker.fetch(request, {})).status, 503);
  assert.equal(
    (
      await worker.fetch(request, {
        REQUEST_LIMITER: {
          async limit() {
            throw new Error("offline");
          },
        },
      })
    ).status,
    503,
  );
  const depleted = {
    REQUEST_LIMITER: {
      async limit() {
        return { success: false };
      },
    },
  };
  assert.equal((await worker.fetch(request, depleted)).status, 429);
});
