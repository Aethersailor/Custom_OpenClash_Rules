import { createHash } from "node:crypto";
import { lstat, readFile, readdir } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const workerRoot = path.resolve(
  path.dirname(fileURLToPath(import.meta.url)),
  "..",
);
const distRoot = path.resolve(workerRoot, "dist");
const manifestPath = path.resolve(
  distRoot,
  "_mirror",
  "Custom_OpenClash_Rules",
  "main.json",
);
const assetPrefix = path.resolve(
  distRoot,
  "Custom_OpenClash_Rules",
  "main",
);

function assertSafeRepoPath(value) {
  if (
    typeof value !== "string" ||
    !value ||
    value.includes("\\") ||
    value.startsWith("/") ||
    value.split("/").some((part) => part === "" || part === "." || part === "..")
  ) {
    throw new Error(`Unsafe manifest path: ${JSON.stringify(value)}`);
  }
}

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

async function regularFile(filePath) {
  const metadata = await lstat(filePath);
  if (!metadata.isFile() || metadata.isSymbolicLink()) {
    throw new Error(`Expected a regular file: ${filePath}`);
  }
  return metadata;
}

async function listRegularFiles(root, current = root) {
  const files = [];
  for (const entry of await readdir(current, { withFileTypes: true })) {
    const entryPath = path.resolve(current, entry.name);
    if (entry.isSymbolicLink()) {
      throw new Error(`Unexpected symbolic link in dist: ${entryPath}`);
    }
    if (entry.isDirectory()) {
      files.push(...(await listRegularFiles(root, entryPath)));
    } else if (entry.isFile()) {
      files.push(path.relative(root, entryPath).split(path.sep).join("/"));
    } else {
      throw new Error(`Unexpected filesystem entry in dist: ${entryPath}`);
    }
  }
  return files.sort();
}

async function main() {
  await regularFile(manifestPath);
  let manifest;
  try {
    manifest = JSON.parse(await readFile(manifestPath, "utf8"));
  } catch (error) {
    throw new Error(`Invalid Worker snapshot manifest: ${error.message}`);
  }

  if (
    manifest.repository !== "Aethersailor/Custom_OpenClash_Rules" ||
    manifest.branch !== "main" ||
    !/^[0-9a-f]{40}$/u.test(manifest.commit ?? "") ||
    !manifest.files ||
    typeof manifest.files !== "object" ||
    Array.isArray(manifest.files)
  ) {
    throw new Error("Worker snapshot manifest identity is invalid");
  }

  const entries = Object.entries(manifest.files).sort(([left], [right]) =>
    left.localeCompare(right, "en"),
  );
  if (entries.length !== manifest.file_count) {
    throw new Error(
      `Manifest file_count ${manifest.file_count} does not match ${entries.length} entries`,
    );
  }

  let totalBytes = 0;
  for (const [repoPath, expected] of entries) {
    assertSafeRepoPath(repoPath);
    if (
      !expected ||
      !Number.isSafeInteger(expected.bytes) ||
      expected.bytes < 0 ||
      !/^[0-9a-f]{64}$/u.test(expected.sha256 ?? "")
    ) {
      throw new Error(`Invalid manifest entry: ${repoPath}`);
    }
    const assetPath = path.resolve(assetPrefix, ...repoPath.split("/"));
    const relative = path.relative(assetPrefix, assetPath);
    if (relative.startsWith("..") || path.isAbsolute(relative)) {
      throw new Error(`Asset escapes the project prefix: ${repoPath}`);
    }
    const metadata = await regularFile(assetPath);
    const bytes = await readFile(assetPath);
    if (metadata.size !== expected.bytes || sha256(bytes) !== expected.sha256) {
      throw new Error(`Asset does not match manifest: ${repoPath}`);
    }
    totalBytes += metadata.size;
  }

  if (totalBytes !== manifest.total_bytes) {
    throw new Error(
      `Manifest total_bytes ${manifest.total_bytes} does not match ${totalBytes}`,
    );
  }

  const canary = manifest.canary;
  if (
    canary?.path !== "rule/Custom_Direct.list" ||
    manifest.files[canary.path]?.bytes !== canary.bytes ||
    manifest.files[canary.path]?.sha256 !== canary.sha256
  ) {
    throw new Error("Worker snapshot canary is invalid");
  }

  await regularFile(path.resolve(assetPrefix, "index.html"));
  await regularFile(path.resolve(distRoot, "_headers"));
  const expectedDistFiles = new Set([
    "_headers",
    "_mirror/Custom_OpenClash_Rules/main.json",
    "Custom_OpenClash_Rules/main/index.html",
    ...entries.map(([repoPath]) => `Custom_OpenClash_Rules/main/${repoPath}`),
  ]);
  const actualDistFiles = await listRegularFiles(distRoot);
  const unexpected = actualDistFiles.filter(
    (filePath) => !expectedDistFiles.has(filePath),
  );
  const missing = [...expectedDistFiles].filter(
    (filePath) => !actualDistFiles.includes(filePath),
  );
  if (unexpected.length || missing.length) {
    throw new Error(
      `dist file set mismatch; unexpected=${JSON.stringify(unexpected)}, ` +
        `missing=${JSON.stringify(missing)}`,
    );
  }
  console.log(
    `Validated ${entries.length} snapshot files for ${manifest.commit}.`,
  );
}

await main();
