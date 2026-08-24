import { MIRROR_CONFIG } from "./config.js";

const DEFINITIVE_UNAVAILABLE_STATUSES = new Set([404, 410, 451]);

class ProbeRequestError extends Error {
  constructor(code) {
    super(code);
    this.name = "ProbeRequestError";
    this.code = code;
  }
}

function classifyHttpFailure(status) {
  return DEFINITIVE_UNAVAILABLE_STATUSES.has(status)
    ? "unhealthy"
    : "unknown";
}

function result(name, status, code, startedAt, extra = {}) {
  return {
    name,
    status,
    code,
    durationMs: Date.now() - startedAt,
    ...extra,
  };
}

async function fetchWithTimeout(url, init = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort("probe_timeout"),
    MIRROR_CONFIG.probeTimeoutMs,
  );

  try {
    return await fetch(url, {
      ...init,
      signal: controller.signal,
      redirect: "follow",
    });
  } catch (error) {
    if (controller.signal.aborted || error?.name === "AbortError") {
      throw new ProbeRequestError("timeout");
    }
    throw new ProbeRequestError("network_error");
  } finally {
    clearTimeout(timeout);
  }
}

async function readBytes(response, maximumBytes) {
  const declaredLength = Number(response.headers.get("content-length"));
  if (Number.isFinite(declaredLength) && declaredLength > maximumBytes) {
    await response.body?.cancel();
    throw new ProbeRequestError("response_too_large");
  }

  if (!response.body) {
    return new Uint8Array();
  }

  const reader = response.body.getReader();
  const chunks = [];
  let length = 0;

  while (true) {
    const { done, value } = await reader.read();
    if (done) {
      break;
    }
    length += value.byteLength;
    if (length > maximumBytes) {
      await reader.cancel();
      throw new ProbeRequestError("response_too_large");
    }
    chunks.push(value);
  }

  const bytes = new Uint8Array(length);
  let offset = 0;
  for (const chunk of chunks) {
    bytes.set(chunk, offset);
    offset += chunk.byteLength;
  }
  return bytes;
}

async function sha256Hex(bytes) {
  const digest = await crypto.subtle.digest("SHA-256", bytes);
  return [...new Uint8Array(digest)]
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function requestErrorResult(name, startedAt, error) {
  const code = error instanceof ProbeRequestError ? error.code : "probe_error";
  return result(name, "unknown", code, startedAt);
}

function normalizeSnapshot(payload, expectedRevision) {
  if (
    payload?.repository !== MIRROR_CONFIG.repository ||
    payload.branch !== MIRROR_CONFIG.branch ||
    !/^[0-9a-f]{40}$/u.test(payload.commit ?? "") ||
    !Number.isSafeInteger(payload.file_count) ||
    payload.file_count < 1 ||
    !Number.isSafeInteger(payload.total_bytes) ||
    payload.total_bytes < 0 ||
    payload.canary?.path !== MIRROR_CONFIG.canaryPath ||
    !Number.isSafeInteger(payload.canary?.bytes) ||
    payload.canary.bytes < 0 ||
    !/^[0-9a-f]{64}$/u.test(payload.canary?.sha256 ?? "")
  ) {
    return { snapshot: null, code: "invalid_manifest" };
  }

  const configuredRevision = String(expectedRevision ?? "").toLowerCase();
  if (configuredRevision && !/^[0-9a-f]{40}$/u.test(configuredRevision)) {
    return { snapshot: null, code: "invalid_snapshot_sha_binding" };
  }
  if (configuredRevision && configuredRevision !== payload.commit) {
    return { snapshot: null, code: "deployment_identity_mismatch" };
  }

  return {
    code: "ok",
    snapshot: {
      commit: payload.commit,
      publishedAt: payload.published_at ?? null,
      fileCount: payload.file_count,
      totalBytes: payload.total_bytes,
      canary: {
        path: payload.canary.path,
        bytes: payload.canary.bytes,
        sha256: payload.canary.sha256,
      },
    },
  };
}

async function loadSnapshotManifest(env) {
  const name = "snapshot_manifest";
  const startedAt = Date.now();
  try {
    if (!env.ASSETS || typeof env.ASSETS.fetch !== "function") {
      return {
        snapshot: null,
        probe: result(name, "unknown", "assets_binding_missing", startedAt),
      };
    }
    const response = await env.ASSETS.fetch(
      new Request(`https://assets.internal${MIRROR_CONFIG.manifestPath}`),
    );
    if (!response.ok) {
      await response.body?.cancel();
      return {
        snapshot: null,
        probe: result(
          name,
          "unknown",
          `http_${response.status}`,
          startedAt,
          { httpStatus: response.status },
        ),
      };
    }

    const bytes = await readBytes(response, 4 * 1024 * 1024);
    let payload;
    try {
      payload = JSON.parse(new TextDecoder().decode(bytes));
    } catch {
      return {
        snapshot: null,
        probe: result(name, "unknown", "invalid_json", startedAt),
      };
    }

    const normalized = normalizeSnapshot(payload, env.SNAPSHOT_SHA);
    return {
      snapshot: normalized.snapshot,
      probe: result(
        name,
        normalized.snapshot ? "healthy" : "unknown",
        normalized.code,
        startedAt,
        normalized.snapshot
          ? {
              commit: normalized.snapshot.commit,
              canarySha256: normalized.snapshot.canary.sha256,
            }
          : {},
      ),
    };
  } catch (error) {
    return {
      snapshot: null,
      probe: requestErrorResult(name, startedAt, error),
    };
  }
}

async function probeGithubApi() {
  const name = "github_api";
  const startedAt = Date.now();
  try {
    const response = await fetchWithTimeout(MIRROR_CONFIG.githubApiUrl, {
      headers: {
        Accept: "application/vnd.github+json",
        "Cache-Control": "no-cache",
        "User-Agent": "custom-openclash-rules-repository-mirror/1.0",
        "X-GitHub-Api-Version": "2022-11-28",
      },
    });

    if (!response.ok) {
      await response.body?.cancel();
      return result(
        name,
        classifyHttpFailure(response.status),
        `http_${response.status}`,
        startedAt,
        { httpStatus: response.status },
      );
    }

    const bytes = await readBytes(response, 1024 * 1024);
    let payload;
    try {
      payload = JSON.parse(new TextDecoder().decode(bytes));
    } catch {
      return result(name, "unknown", "invalid_json", startedAt, {
        httpStatus: response.status,
      });
    }

    const observedRevision = String(payload?.sha ?? "").toLowerCase();
    if (!/^[0-9a-f]{40}$/u.test(observedRevision)) {
      return result(name, "unknown", "invalid_revision", startedAt, {
        httpStatus: response.status,
      });
    }

    return result(name, "healthy", "ok", startedAt, {
      httpStatus: response.status,
      observedRevision,
    });
  } catch (error) {
    return requestErrorResult(name, startedAt, error);
  }
}

async function probeGithubPage() {
  const name = "github_page";
  const startedAt = Date.now();
  try {
    const response = await fetchWithTimeout(MIRROR_CONFIG.githubPageUrl, {
      method: "HEAD",
      headers: {
        Accept: "text/html",
        "Cache-Control": "no-cache",
        "User-Agent": "custom-openclash-rules-repository-mirror/1.0",
      },
    });

    if (!response.ok) {
      await response.body?.cancel();
      return result(
        name,
        classifyHttpFailure(response.status),
        `http_${response.status}`,
        startedAt,
        { httpStatus: response.status },
      );
    }

    const finalUrl = new URL(response.url);
    const expectedPath = "/Aethersailor/Custom_OpenClash_Rules/tree/main";
    if (
      finalUrl.hostname.toLowerCase() !== "github.com" ||
      finalUrl.pathname.toLowerCase() !== expectedPath.toLowerCase()
    ) {
      return result(name, "unknown", "unexpected_redirect", startedAt, {
        httpStatus: response.status,
      });
    }

    return result(name, "healthy", "ok", startedAt, {
      httpStatus: response.status,
    });
  } catch (error) {
    return requestErrorResult(name, startedAt, error);
  }
}

async function probeHashedFile(name, url) {
  const startedAt = Date.now();
  try {
    const response = await fetchWithTimeout(url, {
      headers: {
        Accept: "text/plain, application/octet-stream;q=0.9, */*;q=0.1",
        "Cache-Control": "no-cache",
        "User-Agent": "custom-openclash-rules-repository-mirror/1.0",
      },
    });

    if (!response.ok) {
      await response.body?.cancel();
      return result(
        name,
        classifyHttpFailure(response.status),
        `http_${response.status}`,
        startedAt,
        { httpStatus: response.status },
      );
    }

    const bytes = await readBytes(response, MIRROR_CONFIG.maxCanaryBytes);
    return result(name, "healthy", "ok", startedAt, {
      httpStatus: response.status,
      bytes: bytes.byteLength,
      observedSha256: await sha256Hex(bytes),
    });
  } catch (error) {
    return requestErrorResult(name, startedAt, error);
  }
}

function decideOutcome(snapshot, githubApi, githubPage, githubRaw, _jsdelivr) {
  const publicRepositoryReady =
    githubPage.status === "healthy" && githubRaw.status === "healthy";

  // Mutable jsDelivr branch URLs can lag behind GitHub. Availability, rather
  // than byte freshness, controls redirect mode. When GitHub's public page
  // and Raw file are reachable, visitors should use the configured jsDelivr
  // redirect even if its current response is stale or temporarily unknown.
  if (publicRepositoryReady) {
    return { outcome: "healthy", reason: "github_repository_available" };
  }

  if (snapshot) {
    const definitiveRepositoryFailures = [
      githubApi,
      githubPage,
      githubRaw,
    ].filter((probe) => probe.status === "unhealthy").length;
    if (definitiveRepositoryFailures >= 2) {
      return { outcome: "unhealthy", reason: "repository_unavailable" };
    }

  }

  return { outcome: "unknown", reason: "insufficient_evidence" };
}

export async function runHealthChecks(env) {
  const [manifestResult, githubApi, githubPage, githubRaw, jsdelivr] =
    await Promise.all([
      loadSnapshotManifest(env),
      probeGithubApi(),
      probeGithubPage(),
      probeHashedFile("github_raw", MIRROR_CONFIG.githubRawUrl),
      probeHashedFile("jsdelivr", MIRROR_CONFIG.jsdelivrUrl),
    ]);
  const decision = decideOutcome(
    manifestResult.snapshot,
    githubApi,
    githubPage,
    githubRaw,
    jsdelivr,
  );

  return {
    ...decision,
    snapshot: manifestResult.snapshot,
    probes: [
      manifestResult.probe,
      githubApi,
      githubPage,
      githubRaw,
      jsdelivr,
    ],
  };
}
