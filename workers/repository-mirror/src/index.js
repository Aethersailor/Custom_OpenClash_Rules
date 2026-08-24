import { DurableObject } from "cloudflare:workers";

import { reconcileRedirectRules, MirrorRuleError } from "./cloudflare-rules.js";
import { MIRROR_CONFIG } from "./config.js";
import { runHealthChecks } from "./probes.js";

const STATE_ID = 1;
const DURABLE_OBJECT_NAME = "custom-openclash-rules-main";

function jsonResponse(payload, status = 200, method = "GET") {
  const headers = new Headers({
    "Access-Control-Allow-Origin": "*",
    "Cache-Control": "no-store, max-age=0",
    "Content-Type": "application/json; charset=utf-8",
    "X-Content-Type-Options": "nosniff",
  });
  return new Response(method === "HEAD" ? null : JSON.stringify(payload, null, 2), {
    status,
    headers,
  });
}

function textResponse(body, status, extraHeaders = {}) {
  return new Response(body, {
    status,
    headers: {
      "Cache-Control": "no-store, max-age=0",
      "Content-Type": "text/plain; charset=utf-8",
      "X-Content-Type-Options": "nosniff",
      ...extraHeaders,
    },
  });
}

function stateStub(env) {
  const id = env.MIRROR_STATE.idFromName(DURABLE_OBJECT_NAME);
  return env.MIRROR_STATE.get(id);
}

function safeParseProbes(serialized) {
  try {
    const probes = JSON.parse(serialized);
    return Array.isArray(probes) ? probes : [];
  } catch {
    return [];
  }
}

function safeParseObject(serialized) {
  try {
    const value = JSON.parse(serialized);
    return value && typeof value === "object" && !Array.isArray(value)
      ? value
      : {};
  } catch {
    return {};
  }
}

function configuredSnapshotRevision(env) {
  const revision = String(env.SNAPSHOT_SHA ?? "").toLowerCase();
  return /^[0-9a-f]{40}$/u.test(revision) ? revision : "unknown";
}

export class RepositoryMirrorState extends DurableObject {
  constructor(ctx, env) {
    super(ctx, env);
    this.ctx = ctx;
    this.env = env;
    this.sql = ctx.storage.sql;
    this.monitorPromise = null;
    this.initializeState();
  }

  initializeState() {
    this.sql.exec(`
      CREATE TABLE IF NOT EXISTS mirror_state (
        id INTEGER PRIMARY KEY CHECK (id = 1),
        snapshot_revision TEXT NOT NULL,
        redirect_enabled INTEGER,
        success_streak INTEGER NOT NULL DEFAULT 0,
        failure_streak INTEGER NOT NULL DEFAULT 0,
        last_check_at TEXT,
        last_check_result TEXT NOT NULL DEFAULT 'never',
        last_check_reason TEXT,
        last_check_duration_ms INTEGER,
        last_healthy_at TEXT,
        last_unhealthy_at TEXT,
        last_rule_sync_at TEXT,
        last_transition_at TEXT,
        last_rule_error TEXT,
        snapshot_json TEXT NOT NULL DEFAULT '{}',
        probes_json TEXT NOT NULL DEFAULT '[]'
      );
    `);
    this.sql.exec(
      `INSERT OR IGNORE INTO mirror_state (
        id,
        snapshot_revision,
        redirect_enabled,
        success_streak,
        failure_streak,
        last_check_result,
        snapshot_json,
        probes_json
      ) VALUES (?, ?, NULL, 0, 0, 'never', '{}', '[]')`,
      STATE_ID,
      configuredSnapshotRevision(this.env),
    );

    const state = this.readState();
    const configuredRevision = configuredSnapshotRevision(this.env);
    if (
      configuredRevision !== "unknown" &&
      state.snapshot_revision !== configuredRevision
    ) {
      this.sql.exec(
        `UPDATE mirror_state SET
          snapshot_revision = ?,
          success_streak = 0,
          failure_streak = 0,
          last_check_at = NULL,
          last_check_result = 'never',
          last_check_reason = NULL,
          last_check_duration_ms = NULL,
          last_rule_error = NULL,
          snapshot_json = '{}',
          probes_json = '[]'
        WHERE id = ?`,
        configuredRevision,
        STATE_ID,
      );
    }
  }

  readState() {
    return this.sql
      .exec("SELECT * FROM mirror_state WHERE id = ?", STATE_ID)
      .one();
  }

  publicStatus() {
    const state = this.readState();
    const snapshot = safeParseObject(state.snapshot_json);
    const redirectEnabled =
      state.redirect_enabled === null
        ? null
        : Number(state.redirect_enabled) === 1;

    return {
      service: "custom-openclash-rules-repository-mirror",
      repository: MIRROR_CONFIG.repository,
      branch: MIRROR_CONFIG.branch,
      mode:
        redirectEnabled === null
          ? "unknown"
          : redirectEnabled
            ? "redirect"
            : "static_assets",
      redirectRules: {
        enabled: redirectEnabled,
        refs: MIRROR_CONFIG.redirectRuleRefs,
        lastSyncAt: state.last_rule_sync_at,
        lastTransitionAt: state.last_transition_at,
        lastError: state.last_rule_error,
      },
      debounce: {
        threshold: MIRROR_CONFIG.debounceThreshold,
        consecutiveHealthy: Number(state.success_streak),
        consecutiveUnhealthy: Number(state.failure_streak),
      },
      snapshot: {
        expectedRevision: configuredSnapshotRevision(this.env),
        revision: snapshot.commit ?? state.snapshot_revision,
        publishedAt: snapshot.publishedAt ?? null,
        fileCount: snapshot.fileCount ?? null,
        totalBytes: snapshot.totalBytes ?? null,
        canaryPath: snapshot.canary?.path ?? MIRROR_CONFIG.canaryPath,
        canarySha256: snapshot.canary?.sha256 ?? null,
      },
      lastCheck: state.last_check_at
        ? {
            at: state.last_check_at,
            result: state.last_check_result,
            reason: state.last_check_reason,
            durationMs: state.last_check_duration_ms,
            probes: safeParseProbes(state.probes_json),
          }
        : null,
      lastHealthyAt: state.last_healthy_at,
      lastUnhealthyAt: state.last_unhealthy_at,
    };
  }

  async performMonitor() {
    const startedAt = Date.now();
    const checkedAt = new Date().toISOString();
    const health = await runHealthChecks(this.env);
    const previous = this.readState();

    let successStreak = 0;
    let failureStreak = 0;
    if (health.outcome === "healthy") {
      successStreak = Math.min(
        Number(previous.success_streak) + 1,
        MIRROR_CONFIG.debounceThreshold,
      );
    } else if (health.outcome === "unhealthy") {
      failureStreak = Math.min(
        Number(previous.failure_streak) + 1,
        MIRROR_CONFIG.debounceThreshold,
      );
    }

    let desiredRedirectState = null;
    if (successStreak >= MIRROR_CONFIG.debounceThreshold) {
      desiredRedirectState = true;
    } else if (failureStreak >= MIRROR_CONFIG.debounceThreshold) {
      desiredRedirectState = false;
    }

    let redirectEnabled = previous.redirect_enabled;
    let lastRuleSyncAt = previous.last_rule_sync_at;
    let lastTransitionAt = previous.last_transition_at;
    let lastRuleError = previous.last_rule_error;

    if (desiredRedirectState !== null) {
      try {
        const synchronization = await reconcileRedirectRules(
          this.env,
          desiredRedirectState,
        );
        redirectEnabled = synchronization.enabled ? 1 : 0;
        lastRuleSyncAt = checkedAt;
        if (synchronization.changed) {
          lastTransitionAt = checkedAt;
        }
        lastRuleError = null;
      } catch (error) {
        const errorCode =
          error instanceof MirrorRuleError
            ? error.code
            : "redirect_rule_sync_failed";
        lastRuleError = errorCode;
        console.error("Redirect rule reconciliation failed", {
          code: errorCode,
          message: error instanceof Error ? error.message : String(error),
        });
      }
    }

    const lastHealthyAt =
      health.outcome === "healthy" ? checkedAt : previous.last_healthy_at;
    const lastUnhealthyAt =
      health.outcome === "unhealthy" ? checkedAt : previous.last_unhealthy_at;

    this.sql.exec(
      `UPDATE mirror_state SET
        snapshot_revision = ?,
        snapshot_json = ?,
        redirect_enabled = ?,
        success_streak = ?,
        failure_streak = ?,
        last_check_at = ?,
        last_check_result = ?,
        last_check_reason = ?,
        last_check_duration_ms = ?,
        last_healthy_at = ?,
        last_unhealthy_at = ?,
        last_rule_sync_at = ?,
        last_transition_at = ?,
        last_rule_error = ?,
        probes_json = ?
      WHERE id = ?`,
      health.snapshot?.commit ?? configuredSnapshotRevision(this.env),
      JSON.stringify(health.snapshot ?? {}),
      redirectEnabled,
      successStreak,
      failureStreak,
      checkedAt,
      health.outcome,
      health.reason,
      Date.now() - startedAt,
      lastHealthyAt,
      lastUnhealthyAt,
      lastRuleSyncAt,
      lastTransitionAt,
      lastRuleError,
      JSON.stringify(health.probes),
      STATE_ID,
    );

    return this.publicStatus();
  }

  async runMonitor() {
    if (!this.monitorPromise) {
      this.monitorPromise = this.performMonitor().finally(() => {
        this.monitorPromise = null;
      });
    }
    return this.monitorPromise;
  }

  async fetch(request) {
    const url = new URL(request.url);

    if (url.pathname === "/status") {
      if (request.method !== "GET" && request.method !== "HEAD") {
        return textResponse("Method Not Allowed\n", 405, { Allow: "GET, HEAD" });
      }
      return jsonResponse(this.publicStatus(), 200, request.method);
    }

    if (url.pathname === "/monitor" && request.method === "POST") {
      try {
        return jsonResponse(await this.runMonitor());
      } catch (error) {
        console.error("Scheduled repository monitor failed", {
          message: error instanceof Error ? error.message : String(error),
        });
        return jsonResponse({ ok: false, error: "monitor_failed" }, 500);
      }
    }

    return textResponse("Not Found\n", 404);
  }
}

async function servePublicStatus(request, env) {
  try {
    const response = await stateStub(env).fetch("https://mirror-state.internal/status", {
      method: request.method,
    });
    return response;
  } catch (error) {
    console.error("Mirror status is unavailable", {
      message: error instanceof Error ? error.message : String(error),
    });
    return jsonResponse(
      { error: "status_unavailable" },
      503,
      request.method,
    );
  }
}

async function runScheduledMonitor(env) {
  const response = await stateStub(env).fetch(
    "https://mirror-state.internal/monitor",
    { method: "POST" },
  );
  if (!response.ok) {
    throw new Error(`Scheduled monitor returned HTTP ${response.status}`);
  }
  await response.body?.cancel();
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    if (url.pathname === "/__mirror/status") {
      if (request.method !== "GET" && request.method !== "HEAD") {
        return textResponse("Method Not Allowed\n", 405, { Allow: "GET, HEAD" });
      }
      return servePublicStatus(request, env);
    }
    return textResponse("Not Found\n", 404);
  },

  async scheduled(_controller, env, ctx) {
    ctx.waitUntil(
      runScheduledMonitor(env).catch((error) => {
        console.error("Scheduled repository monitor invocation failed", {
          message: error instanceof Error ? error.message : String(error),
        });
      }),
    );
  },
};
