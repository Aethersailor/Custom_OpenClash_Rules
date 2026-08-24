import { MIRROR_CONFIG } from "./config.js";

export class MirrorRuleError extends Error {
  constructor(code, message) {
    super(message);
    this.name = "MirrorRuleError";
    this.code = code;
  }
}

function requireSecrets(env) {
  if (!env.CF_ZONE_ID || !env.CF_REDIRECT_API_TOKEN) {
    throw new MirrorRuleError(
      "missing_cloudflare_secrets",
      "CF_ZONE_ID and CF_REDIRECT_API_TOKEN must both be configured",
    );
  }
}

async function cloudflareJson(env, path, init = {}) {
  const controller = new AbortController();
  const timeout = setTimeout(
    () => controller.abort("cloudflare_api_timeout"),
    MIRROR_CONFIG.cloudflareApiTimeoutMs,
  );

  let response;
  try {
    response = await fetch(`https://api.cloudflare.com/client/v4${path}`, {
      ...init,
      signal: controller.signal,
      headers: {
        Authorization: `Bearer ${env.CF_REDIRECT_API_TOKEN}`,
        "Content-Type": "application/json",
        ...(init.headers ?? {}),
      },
    });
  } catch (error) {
    const code =
      controller.signal.aborted || error?.name === "AbortError"
        ? "cloudflare_api_timeout"
        : "cloudflare_api_unavailable";
    throw new MirrorRuleError(code, code);
  } finally {
    clearTimeout(timeout);
  }

  let payload;
  try {
    payload = await response.json();
  } catch {
    throw new MirrorRuleError(
      "cloudflare_api_invalid_response",
      `Cloudflare API returned HTTP ${response.status} without a JSON envelope`,
    );
  }

  if (!response.ok || payload?.success !== true || !payload.result) {
    const apiMessage = Array.isArray(payload?.errors)
      ? payload.errors
          .map((entry) => String(entry?.message ?? ""))
          .filter(Boolean)
          .join("; ")
      : "";
    throw new MirrorRuleError(
      "cloudflare_api_error",
      `Cloudflare API returned HTTP ${response.status}${apiMessage ? `: ${apiMessage}` : ""}`,
    );
  }

  return payload.result;
}

function entrypointPath(env) {
  return `/zones/${encodeURIComponent(env.CF_ZONE_ID)}/rulesets/phases/${MIRROR_CONFIG.redirectPhase}/entrypoint`;
}

async function getEntrypoint(env) {
  const ruleset = await cloudflareJson(env, entrypointPath(env));
  if (
    ruleset.phase !== MIRROR_CONFIG.redirectPhase ||
    !ruleset.id ||
    !Array.isArray(ruleset.rules)
  ) {
    throw new MirrorRuleError(
      "redirect_ruleset_invalid",
      "The dynamic redirect entry point is missing or malformed",
    );
  }
  return ruleset;
}

function findManagedRule(ruleset, ref) {
  const matches = ruleset.rules.filter((rule) => rule.ref === ref);
  if (matches.length !== 1) {
    throw new MirrorRuleError(
      "redirect_rule_definition_invalid",
      `Expected exactly one dynamic redirect rule with ref ${ref}`,
    );
  }
  const [rule] = matches;
  if (
    !rule.id ||
    rule.action !== "redirect" ||
    !rule.action_parameters ||
    typeof rule.expression !== "string"
  ) {
    throw new MirrorRuleError(
      "redirect_rule_definition_invalid",
      `Dynamic redirect rule ${ref} is malformed`,
    );
  }
  return rule;
}

function writableRule(rule, enabled = rule.enabled !== false) {
  return {
    action: rule.action,
    action_parameters: rule.action_parameters,
    expression: rule.expression,
    description: rule.description ?? "",
    enabled,
    ref: rule.ref,
  };
}

async function patchRule(env, ruleset, rule, definition) {
  const path = `/zones/${encodeURIComponent(env.CF_ZONE_ID)}/rulesets/${encodeURIComponent(ruleset.id)}/rules/${encodeURIComponent(rule.id)}`;
  await cloudflareJson(env, path, {
    method: "PATCH",
    body: JSON.stringify(definition),
  });
}

function readEnabledStates(ruleset) {
  return Object.fromEntries(
    MIRROR_CONFIG.redirectRuleRefs.map((ref) => [
      ref,
      findManagedRule(ruleset, ref).enabled !== false,
    ]),
  );
}

async function rollbackDefinitions(env, originals) {
  const rollbackErrors = [];
  for (const ref of [...MIRROR_CONFIG.redirectRuleRefs].reverse()) {
    try {
      const currentRuleset = await getEntrypoint(env);
      const currentRule = findManagedRule(currentRuleset, ref);
      const expectedEnabled = originals.get(ref).enabled;
      if ((currentRule.enabled !== false) !== expectedEnabled) {
        // Reuse the latest rule definition so a concurrent expression edit is
        // not overwritten while compensating only the enabled-state change.
        await patchRule(
          env,
          currentRuleset,
          currentRule,
          writableRule(currentRule, expectedEnabled),
        );
      }
    } catch (error) {
      rollbackErrors.push(error instanceof Error ? error.message : String(error));
    }
  }

  try {
    const readback = await getEntrypoint(env);
    for (const ref of MIRROR_CONFIG.redirectRuleRefs) {
      const expected = originals.get(ref).enabled;
      const actual = findManagedRule(readback, ref).enabled !== false;
      if (actual !== expected) {
        rollbackErrors.push(`readback mismatch for ${ref}`);
      }
    }
  } catch (error) {
    rollbackErrors.push(error instanceof Error ? error.message : String(error));
  }
  return rollbackErrors;
}

export async function reconcileRedirectRules(env, desiredEnabled) {
  requireSecrets(env);
  const initialRuleset = await getEntrypoint(env);
  const originals = new Map(
    MIRROR_CONFIG.redirectRuleRefs.map((ref) => {
      const rule = findManagedRule(initialRuleset, ref);
      return [ref, writableRule(rule)];
    }),
  );
  const initialStates = readEnabledStates(initialRuleset);
  const refsToChange = MIRROR_CONFIG.redirectRuleRefs.filter(
    (ref) => initialStates[ref] !== desiredEnabled,
  );

  if (refsToChange.length === 0) {
    return {
      enabled: desiredEnabled,
      changed: false,
      changedRefs: [],
      rulesetVersion: initialRuleset.version ?? null,
    };
  }

  try {
    for (const ref of refsToChange) {
      // Every PATCH creates a new ruleset version. Refresh first so the next
      // stable ref is resolved against the latest version and rule IDs.
      const currentRuleset = await getEntrypoint(env);
      const currentRule = findManagedRule(currentRuleset, ref);
      await patchRule(
        env,
        currentRuleset,
        currentRule,
        writableRule(currentRule, desiredEnabled),
      );
    }

    const readback = await getEntrypoint(env);
    const states = readEnabledStates(readback);
    if (
      MIRROR_CONFIG.redirectRuleRefs.some(
        (ref) => states[ref] !== desiredEnabled,
      )
    ) {
      throw new MirrorRuleError(
        "redirect_rule_state_mismatch",
        "Redirect rules did not converge to the requested state",
      );
    }

    return {
      enabled: desiredEnabled,
      changed: true,
      changedRefs: refsToChange,
      rulesetVersion: readback.version ?? null,
    };
  } catch (error) {
    // Cloudflare does not expose a transactional multi-rule PATCH endpoint.
    // Restore both original definitions because a timed-out PATCH may still
    // have reached the API even when the response was not observed.
    const rollbackErrors = await rollbackDefinitions(env, originals);
    const originalMessage = error instanceof Error ? error.message : String(error);
    const rollbackMessage =
      rollbackErrors.length === 0
        ? "compensating rollback succeeded"
        : `compensating rollback errors: ${rollbackErrors.join("; ")}`;
    throw new MirrorRuleError(
      "redirect_rule_sync_failed",
      `${originalMessage}; ${rollbackMessage}`,
    );
  }
}
