# 归档广告规则拉取示例

本目录保存旧版 Shell 脚本示例。这些脚本会拉取广告过滤规则，并附加 GitHub520 `hosts` 加速条目。所有文件均已归档，不再由本项目维护、测试或自动执行。

## 文件说明

| 文件 | 旧版规则来源 |
| --- | --- |
| `AWAvenue-Ads+github520.txt` | AWAvenue-Ads-Rule + GitHub520 |
| `adblockfilters+github520.txt` | 217heidai/adblockfilters + GitHub520 |
| `adblockfilters-modified+github520.txt` | Aethersailor/adblockfilters-modified + GitHub520 |
| `anti-ad+github520.txt` | privacy-protection-tools/anti-AD + GitHub520 |

## 为什么归档

- 项目的广告过滤功能目前已停用，旧流程不再是推荐配置。
- 规则上游、dnsmasq 的行为及 OpenWrt 环境均会随时间变化，历史脚本无法保证继续适用。
- 自动修改 `hosts` 文件或生成 dnsmasq 规则可能影响域名解析和网络可用性，直接运行前必须自行完整审计。

这些 `.txt` 文件虽然使用文本扩展名，但内容是历史 Shell 脚本，不是可直接导入 OpenClash 的规则集。
