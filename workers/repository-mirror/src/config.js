export const MIRROR_CONFIG = Object.freeze({
  repository: "Aethersailor/Custom_OpenClash_Rules",
  branch: "main",
  publicPrefix: "/Custom_OpenClash_Rules/main/",
  canaryPath: "rule/Custom_Direct.list",
  manifestPath: "/_mirror/Custom_OpenClash_Rules/main.json",
  githubApiUrl:
    "https://api.github.com/repos/Aethersailor/Custom_OpenClash_Rules/commits/main",
  githubPageUrl:
    "https://github.com/Aethersailor/Custom_OpenClash_Rules/tree/main",
  githubRawUrl:
    "https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/rule/Custom_Direct.list",
  jsdelivrUrl:
    "https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/rule/Custom_Direct.list",
  redirectRuleRefs: Object.freeze(["cor_main_page", "cor_main_files"]),
  redirectPhase: "http_request_dynamic_redirect",
  debounceThreshold: 2,
  probeTimeoutMs: 10_000,
  cloudflareApiTimeoutMs: 15_000,
  maxCanaryBytes: 5 * 1024 * 1024,
});
