# 归档的 Shell 脚本

本目录存放已停止维护的 OpenClash 防火墙修改脚本和早期测试脚本。它们不会被当前安装器或 GitHub Actions 调用。

## 文件说明

| 文件 | 历史用途 | 当前状态 |
| --- | --- | --- |
| `edit_custom_firewall_rules.sh` | 选择并写入广告过滤或 GitHub520 相关命令 | 已归档 |
| `edit_custom_firewall_rules_adblockfilters+github520.sh` | 写入 AdblockFilters 与 GitHub520 规则 | 已归档 |
| `edit_custom_firewall_rules_adblockfilters-modified+github520.sh` | 写入修改版 AdblockFilters 与 GitHub520 规则 | 已归档 |
| `edit_custom_firewall_rules_anti-ad+github520.sh` | 写入 Anti-AD 与 GitHub520 规则 | 已归档 |
| `edit_custom_firewall_rules_github520.sh` | 写入 GitHub520 `hosts` 规则 | 已归档 |
| `one-key-setup_test.sh` | 早期一键配置测试 | 已归档 |

这些脚本会修改 OpenClash 自定义防火墙配置，并依赖旧版上游地址、规则格式以及 OpenWrt 和 OpenClash 的行为。

> [!WARNING]
> 不要在当前系统中直接运行归档脚本。确需研究或迁移时，应先在隔离环境中审计下载来源、写入路径、恢复方式以及对 DNS 和防火墙的影响。

当前维护中的安装与更新脚本位于 [`../`](../)。
