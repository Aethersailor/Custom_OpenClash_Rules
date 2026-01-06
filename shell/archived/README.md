# 归档的 Shell 脚本

本文件夹包含已弃用但保留用于历史参考的 Shell 脚本文件。

## 文件说明

| 文件名 | 说明 | 弃用原因 |
| :--- | :--- | :--- |
| `edit_custom_firewall_rules.sh` | 选择性写入去广告命令脚本 | 已整合到新版脚本中 |
| `edit_custom_firewall_rules_adblockfilters+github520.sh` | AdblockFilters + GitHub520 规则写入脚本 | 维护成本高，使用频率低 |
| `edit_custom_firewall_rules_adblockfilters-modified+github520.sh` | 修改版 AdblockFilters + GitHub520 规则写入脚本 | 维护成本高，使用频率低 |
| `edit_custom_firewall_rules_anti-ad+github520.sh` | Anti-AD + GitHub520 规则写入脚本 | 维护成本高，使用频率低 |
| `edit_custom_firewall_rules_github520.sh` | GitHub520 Hosts 写入脚本 | 维护成本高，使用频率低 |
| `one-key-setup_test.sh` | 一键配置测试脚本 | 测试脚本，功能已稳定 |

## 历史功能说明

### 防火墙规则脚本系列

这些脚本曾用于自动向 OpenClash 的"开发者选项"中写入自定义防火墙规则，实现以下功能：

- **广告过滤**: 通过 DNS 拦截广告域名
- **GitHub 加速**: 写入 GitHub520 的 Hosts 规则，加速 GitHub 访问

### 工作原理

脚本会下载最新的规则文件，并写入到 OpenClash 的自定义防火墙规则配置中，在防火墙启动时自动加载。

## 使用建议

这些脚本已不再主动维护。如果您需要类似功能，建议：

1. 使用主目录中维护的活跃脚本
2. 手动配置 OpenClash 的自定义规则
3. 使用第三方广告过滤解决方案

> **注意**: 使用这些归档脚本前，请确保它们适用于您当前的系统环境和 OpenClash 版本。
