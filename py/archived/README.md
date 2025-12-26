# 📦 归档脚本

该目录存放已停止维护或不再被工作流使用的 Python 脚本。

## 📜 文件列表

### `merge_rules.py`

- **功能**: 用于下载并合并多个来源的 LAN 规则列表，并使用 `netaddr` 库对 IP-CIDR 进行聚合优化。
- **状态**: **已归档**。
- **原因**: 经核查，该脚本未被任何 GitHub Actions 工作流引用，且目前有其他替代方案或不再需要手动运行此逻辑。

### `generate_mainland.py`

- **功能**: 将 `cfg/Custom_Clash.ini` 的内容复制到 `cfg/Custom_Clash_Mainland.ini`。
- **状态**: **已归档**。
- **原因**: 该逻辑过于简单，已在 `auto-update-mainland.yml` 工作流中被 `cp` 命令直接替代，不再需要 Python 环境支持，从而提升了 CI 运行效率。
