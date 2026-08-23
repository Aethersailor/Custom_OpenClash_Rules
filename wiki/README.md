# Custom_OpenClash_Rules 文档

本 Wiki 面向使用 OpenWrt、OpenClash 和 Mihomo 的访客，提供配置入门、资源说明、规则贡献和故障排查文档。第一次使用时，先阅读「OpenClash 设置方案」；已有配置时，可按下方任务入口直接查找内容。

> [!IMPORTANT]
> **本 GitHub Wiki 是 Wiki 内容的权威来源。** 主仓库中的 `wiki/` 目录由自动化流程生成，仅用于备份和静态站点发布，请勿直接编辑。提交文档修正时，请在本 Wiki 对应页面或主仓库的文档反馈入口说明问题。

## 快速开始

### [OpenClash 设置方案](1.OpenClash-设置方案.md)

从准备工作开始，依次完成 OpenClash 的 LuCI 设置、配置来源选择、启动和结果验证。首次配置时从这里开始。

### [OpenWrt IPv6 设置方案](2.OpenWrt-IPv6-设置方案.md)

在双栈网络中配置 IPv6 地址分配、DNS 路径和防火墙，并说明与 OpenClash 分流相关的边界。

## 获取和使用项目资源

### [其他说明](3.其他说明.md)

查找 OpenClash `dev` 版安装器入口、个性化规则方法和直连域名收录说明。模板、YAML、规则、覆写模块和脚本的文件级说明，以主仓库各目录中的 `README.md` 为准。

### 四个关联项目如何配合

四个项目可以独立使用，并非必须全部部署：

```text
配置使用：Custom_OpenClash_Rules
              └─ 可选：SubConverter-Extended 转换模板与订阅
                       └─ OpenClash / Mihomo 加载最终配置

规则反馈：OpenClash / Mihomo 的 MATCH 连接
              └─ Rule-Bot Client（默认仅保存到本地）
                       └─ 用户主动启用发送
                                └─ Rule-Bot 检查并处理
                                         └─ 公共实例将符合策略的域名提交到 Custom_OpenClash_Rules
```

- [Custom_OpenClash_Rules](https://github.com/Aethersailor/Custom_OpenClash_Rules) 提供配置文档、模板、YAML、规则和覆写资源。
- [SubConverter-Extended](https://github.com/Aethersailor/SubConverter-Extended) 是可选的增强型订阅转换后端；使用远程 YAML 覆写模块或手动 YAML 时不需要部署它。
- [Rule-Bot Client](https://github.com/Aethersailor/Rule-Bot-Client) 从 Mihomo 的 `MATCH` 连接中收集域名；本地收集不依赖 Rule-Bot，发送功能默认不启用。
- [Rule-Bot](https://github.com/Aethersailor/Rule-Bot) 检查和处理域名提交。项目公共实例以本仓库为目标；自建实例可以使用其他目标仓库。

## 贡献配置与规则

先根据提交内容选择入口：

| 需求 | 建议入口 |
| --- | --- |
| 手动查询或提交少量直连域名 | 使用 [Rule-Bot 公共实例](https://t.me/asailor_rulebot) |
| 持续收集 Mihomo 最终由 `MATCH` 处理的域名 | 按照 [Rule-Bot Client 接入公共 Rule-Bot](https://github.com/Aethersailor/Rule-Bot-Client/wiki/%E6%8E%A5%E5%85%A5%E5%85%AC%E5%85%B1-Rule-Bot) 完成配置；客户端默认仅保存到本地 |
| 批量提交已经核实的规则 | 修改主仓库中的规则来源文件并提交 Pull Request |
| 无法使用 Rule-Bot，或需要附带完整证据 | 使用 [大陆直连域名 Issue 表单](https://github.com/Aethersailor/Custom_OpenClash_Rules/issues/new?template=02_direct_domain_submission.yml) |
| 报告模板、YAML、覆写模块或文档问题 | 使用 [主仓库 Issue 选择页](https://github.com/Aethersailor/Custom_OpenClash_Rules/issues/new/choose) |
| 报告 OpenClash 插件自身问题 | 使用 [OpenClash 官方 Issue 选择页](https://github.com/vernesong/OpenClash/issues/new/choose) |

提交前请先搜索现有规则、Issues 和 Pull Requests，并提供实际命中的规则、策略和可复核证据。不要在公开页面提交订阅地址、Token、节点凭据或其他敏感信息。

## 故障排查

### [故障排除](4.故障排除.md)

按现象收集版本、日志、实际命中规则和配置来源，再区分本项目资源、转换后端、OpenClash、固件或上游规则问题。

## 进阶阅读

### [一些零碎的教程](5.一些零碎的教程.md)

包括本地传统 subconverter、固件扩容和 Tailscale 子网互通等独立教程。执行命令前，先核对每节的适用环境和风险说明。

### [关于「旁路由」的一些吐槽](6.关于“旁路由”的一些吐槽.md)

说明本文所称「旁路由」的网络结构、维护成本和常见故障边界，以及本项目为何以主路由环境为文档基准。

### [其他推荐项目](7.其他推荐项目.md)

列出可作为补充或替代方案的相关项目。使用前请阅读对应项目自己的文档和许可。

## 历史归档

归档页面仅用于说明历史背景，不代表当前能力，也不建议按旧页面部署。

### [Smart 内核相关说明（已归档）](8.OpenClash-零碎教程.md)

OpenClash 已提供当前 Smart 覆写设置；本页只保留历史说明。

### [无插件广告拦截方案（已归档）](9.无插件广告拦截功能设置方案.md)

旧方案已经停止维护，页面中的可执行部署内容已移除。需要广告过滤时，请选择仍在维护的方案，并以其当前文档为准。

---

项目交流与更新通知：[Custom OpenClash Rules Telegram 讨论群组](https://t.me/custom_openclash_rules_group)。
