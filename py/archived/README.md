# 📦 归档脚本

该目录存放已停止维护或不再被工作流使用的 Python 脚本。

## 📜 文件列表

### `merge_rules.py`

- **功能：** 下载并合并多个来源的 LAN 规则列表，并使用 `netaddr` 库聚合 IP-CIDR。
- **状态：** 已归档。
- **原因：** 当前 GitHub Actions 不再引用该脚本，项目也不再维护这套合并流程。

### `generate_mainland.py`

- **功能：** 将 `cfg/Custom_Clash.ini` 复制为 `cfg/Custom_Clash_Mainland.ini`。
- **状态：** 已归档。
- **原因：** 当前由 `auto-update-mainland.yml` 直接完成同步，不再需要独立 Python 脚本。

> [!WARNING]
> 归档脚本仅用于追溯旧实现，不应参与当前生成或发布流程。
