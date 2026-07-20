# 🐍 Python Scripts

## 🛠️ 项目辅助与维护脚本 🛠️

这里存放项目使用的 Python 维护脚本（如规则处理、文件合并等）。

> [!CAUTION]
> **非开发人员请勿随意运行此目录下的脚本，可能会导致规则文件损坏。**

---

## 📂 目录结构

- **[generate_game_cdn.py](generate_game_cdn.py)**: 自动从 v2fly/domain-list-community 上游下载并生成 `Game_Download_CDN.list` 规则文件。
- **[generate_rules.py](generate_rules.py)**: 从仓库维护的 `.list` 源规则统一生成 Domain、IP、Classical 和端口 YAML，并可选调用 Mihomo 仅生成纯 Domain/IP MRS。使用 `--check` 可进行无修改的一致性检查。
- **[update_encrypted_dns.py](update_encrypted_dns.py)**: 从 HaGeZi、DNSCrypt 及 v2fly/domain-list-community 编译后的 `geosite:category-doh` 汇总加密 DNS 规则，精确转换 GeoSite 规则类型并更新 `Encrypted_DNS.list`。使用 `--check` 可验证现有文件，而不修改文件。
- **`archived/`**: 存放已废弃或不再使用的历史脚本。[查看详情](archived/README.md)
