from __future__ import annotations

import base64
import hashlib
import io
import json
import re
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]
FILES = [
    Path("cfg/Custom_Clash.ini"),
    Path("cfg/Custom_Clash_Lite.ini"),
    Path("cfg/Custom_Clash_Full.ini"),
    Path("cfg/yaml/Custom_Clash.yaml"),
    Path("cfg/yaml/Custom_Clash_Lite.yaml"),
    Path("cfg/yaml/Custom_Clash_Full.yaml"),
]
EXPECTED_BLOBS = {
    "cfg/Custom_Clash.ini": "33937c37aced5837fde3aea70af22cbb117259c6",
    "cfg/Custom_Clash_Lite.ini": "d55027ff81d08b2958d5567c5c274736b8f1ba7c",
    "cfg/Custom_Clash_Full.ini": "1890cecb4f607c6bd4bc128784b796b5d5f8390c",
    "cfg/yaml/Custom_Clash.yaml": "7dbcdd408470f691b860fcf0b49f0120a555f832",
    "cfg/yaml/Custom_Clash_Lite.yaml": "ee0261c4db5fbf0986b27a27de015262bed4439a",
    "cfg/yaml/Custom_Clash_Full.yaml": "7b09dec464119493c0159f1bfab3e9ea75e9589b",
}


def git_blob_sha(data: bytes) -> str:
    return hashlib.sha1(f"blob {len(data)}\0".encode("ascii") + data).hexdigest()


def split_line(line: str) -> tuple[str, str]:
    if line.endswith("\r\n"):
        return line[:-2], "\r\n"
    if line.endswith("\n"):
        return line[:-1], "\n"
    return line, ""


def transform_ini(text: str, path: str) -> str:
    lines = text.splitlines(keepends=True)
    indexes = [i for i, line in enumerate(lines) if line.startswith("custom_proxy_group=🎮 游戏平台`select`")]
    if len(indexes) != 1:
        raise AssertionError(f"{path}: expected one active game-platform group, got {len(indexes)}")
    index = indexes[0]
    old, newline = split_line(lines[index])
    if old.rsplit("`", 1)[1] == ".*":
        raise AssertionError(f"{path}: game-platform group already exposes all nodes")
    new = old.rsplit("`", 1)[0] + "`.*"
    replacement = [
        "; 🎮 游戏平台：旧版去重配置，保留用于快速回退。" + newline,
        "; 如需恢复，请注释下方当前配置，并取消注释此行。" + newline,
        "; " + old + newline,
        "; 当前配置：显示订阅 Provider 中的全部有效节点。" + newline,
        new + newline,
    ]
    result = "".join(lines[:index] + replacement + lines[index + 1 :])
    active = [line for line in result.splitlines() if line.startswith("custom_proxy_group=🎮 游戏平台`select`")]
    if len(active) != 1 or not active[0].endswith("`.*"):
        raise AssertionError(f"{path}: active line validation failed")
    if result.count("; custom_proxy_group=🎮 游戏平台`select`") != 1:
        raise AssertionError(f"{path}: rollback line validation failed")
    return result


def transform_yaml(text: str, path: str) -> str:
    lines = text.splitlines(keepends=True)
    starts = [i for i, line in enumerate(lines) if line.startswith("  -") and line.strip() == '- name: "🎮 游戏平台"']
    if len(starts) != 1:
        raise AssertionError(f"{path}: expected one active game-platform group, got {len(starts)}")
    start = starts[0]
    next_starts = [i for i in range(start + 1, len(lines)) if lines[i].startswith("  - name: ")]
    if not next_starts:
        raise AssertionError(f"{path}: could not locate group end")
    next_start = next_starts[0]
    core_end = next_start
    while core_end > start and not lines[core_end - 1].strip():
        core_end -= 1
    core = lines[start:core_end]
    separator = lines[core_end:next_start]
    excludes = [i for i, line in enumerate(core) if re.match(r"^\s+exclude-filter:", line)]
    if len(excludes) != 1:
        raise AssertionError(f"{path}: expected one exclude-filter")
    if not any(line.strip() == "- provider1" for line in core):
        raise AssertionError(f"{path}: game-platform group does not use provider1")
    _, newline = split_line(core[0])
    commented = []
    for line in core:
        raw, line_newline = split_line(line)
        commented.append(("  # " + raw[2:] if raw.startswith("  ") else "# " + raw) + line_newline)
    active = [line for i, line in enumerate(core) if i not in excludes]
    replacement = [
        "  # 🎮 游戏平台：旧版去重配置，保留用于快速回退。" + newline,
        "  # 如需恢复，请注释下方当前配置，并取消注释此块。" + newline,
        *commented,
        "  #" + newline,
        "  # 当前配置：显示 provider1 中的全部有效节点。" + newline,
        *active,
        *separator,
    ]
    result = "".join(lines[:start] + replacement + lines[next_start:])
    if result.count('# - name: "🎮 游戏平台"') != 1:
        raise AssertionError(f"{path}: rollback block validation failed")
    return result


def build_package() -> tuple[bytes, dict[str, str]]:
    outputs: dict[str, bytes] = {}
    for rel in FILES:
        key = rel.as_posix()
        source = (ROOT / rel).read_bytes()
        if git_blob_sha(source) != EXPECTED_BLOBS[key]:
            raise AssertionError(f"{key}: source Git Blob SHA does not match locked remote version")
        text = source.decode("utf-8")
        changed = transform_ini(text, key) if rel.suffix == ".ini" else transform_yaml(text, key)
        outputs[key] = changed.encode("utf-8")

    hashes = {key: hashlib.sha256(data).hexdigest() for key, data in outputs.items()}
    validation = """# 游戏平台全部节点修改校验报告

## 范围

仅修改标准、Lite、Full 三套非故障转移 INI/YAML，共 6 个文件。GFW、Fallback、自建节点模板未修改。

## 修改

- `🎮 游戏平台` 当前活动配置显示 Provider 中全部有效节点。
- INI 当前活动行使用 `.*`，旧去重行完整注释保留。
- YAML 当前活动组移除 `exclude-filter`、保留 `use: provider1`，旧组块完整注释保留。
- 其他策略组、规则、顺序、Provider 和正则不变。

## 校验

- 源文件 Git Blob SHA 与锁定的远程仓库版本一致。
- 输出 YAML 将由仓库现有 CI 使用 Mihomo 原生配置检查继续验证。
- 每个文件均只存在一个活动的 `🎮 游戏平台` 配置，并完整保留一份注释化旧配置。
"""
    source_blobs = (
        "Repository: Aethersailor/Custom_OpenClash_Rules\n"
        "Locked commit: 91e61549535d05c835b943f102d404072f217489\n\n"
        + "\n".join(f"{EXPECTED_BLOBS[key]}  {key}" for key in sorted(EXPECTED_BLOBS))
        + "\n"
    )
    sums = "\n".join(f"{hashes[key]}  {key}" for key in sorted(hashes)) + "\n"
    manifest = json.dumps(
        {
            "repository": "Aethersailor/Custom_OpenClash_Rules",
            "locked_commit": "91e61549535d05c835b943f102d404072f217489",
            "source_blobs": EXPECTED_BLOBS,
            "output_sha256": hashes,
        },
        ensure_ascii=False,
        indent=2,
    ) + "\n"

    memory = io.BytesIO()
    with zipfile.ZipFile(memory, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        members = dict(outputs)
        members["VALIDATION_REPORT.md"] = validation.encode("utf-8")
        members["SOURCE_BLOBS.txt"] = source_blobs.encode("utf-8")
        members["SHA256SUMS.txt"] = sums.encode("utf-8")
        members["manifest.json"] = manifest.encode("utf-8")
        for name in sorted(members):
            info = zipfile.ZipInfo(name, date_time=(2026, 7, 26, 0, 0, 0))
            info.compress_type = zipfile.ZIP_DEFLATED
            info.external_attr = 0o100644 << 16
            archive.writestr(info, members[name], compress_type=zipfile.ZIP_DEFLATED, compresslevel=9)
    return memory.getvalue(), hashes


class ArtifactBuildTest(unittest.TestCase):
    def test_generate_package(self) -> None:
        package, hashes = build_package()
        self.assertGreater(len(package), 1000)
        digest = hashlib.sha256(package).hexdigest()
        encoded = base64.b64encode(package).decode("ascii")
        print(f"CHATGPT_ARTIFACT_BEGIN sha256={digest} bytes={len(package)} chunks={(len(encoded) + 3999) // 4000}")
        for index in range(0, len(encoded), 4000):
            print(f"CHATGPT_ARTIFACT_CHUNK {index // 4000 + 1:03d} {encoded[index:index + 4000]}")
        print("CHATGPT_ARTIFACT_END")
        print("CHATGPT_OUTPUT_HASHES " + json.dumps(hashes, sort_keys=True))


if __name__ == "__main__":
    unittest.main()
