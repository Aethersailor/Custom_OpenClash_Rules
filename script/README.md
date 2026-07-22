# 脚本目录

此目录收录与项目主配置相互独立的辅助脚本。除非 README 明确说明，否则这些内容不会被 OpenClash 配置、规则生成流程或 GitHub Actions 自动加载。

## 目录索引

| 路径 | 状态 | 用途 |
| --- | --- | --- |
| [`sub-store/`](sub-store/README.md) | 维护中 | 供 Sub-Store 的 HTTP-META 运行环境使用的节点 IPv6 出站能力过滤器。 |
| [`archived/`](archived/README.md) | 归档 | 已停止维护的历史脚本与广告规则拉取示例；仅供查阅。 |

## 使用提示

- 请先阅读目标子目录的 README，确认运行环境、依赖和副作用。
- 脚本不会替代本仓库的 OpenClash 配置教程；OpenClash 的部署与配置请以项目 Wiki 为准。
- `archived/` 中的内容不保证可用、完整或仍适配当前 OpenWrt、Dnsmasq、OpenClash 或上游规则格式，切勿直接用于生产环境。
