# OpenClash 覆写资源

本目录收录 OpenClash 覆写模块及相关说明。请先根据需求选择资源；不要同时启用功能重叠的完整覆写方案，以免规则、策略组或 DNS 设置相互覆盖。

## 资源一览

| 资源 | 用途 | 维护状态 |
| --- | --- | --- |
| [`Block_Encrypted_DNS.conf`](Block_Encrypted_DNS.conf) | 在现有配置顶部加入加密 DNS 拦截规则 | 本项目维护 |
| [`OpenClash_Overwrite/`](OpenClash_Overwrite/) | 完整的第三方远程覆写方案，包含主路由、旁路由、Smart 和无 IPv6 等版本 | [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite) 维护，本目录以 Git 子模块同步 |
| [`archived/`](archived/) | 本项目早期的完整远程覆写配置 | 已归档，不再维护 |

如果准备从头配置 OpenClash，建议优先按照本项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 操作，并配合 [`cfg/Custom_Clash.ini`](../cfg/Custom_Clash.ini) 使用。完整 YAML 示例可参考 [`cfg/yaml/Custom_Clash.yaml`](../cfg/yaml/Custom_Clash.yaml)。

## 阻断加密 DNS

[`Block_Encrypted_DNS.conf`](Block_Encrypted_DNS.conf) 是一个可独立启用的轻量覆写模块，用于限制客户端绕过本地 DNS 设置：

- 拒绝目标端口为 TCP/UDP 853 的连接，即常见的 DoT 和 DoQ 标准端口；
- 通过远程 MRS 规则集拒绝已知加密 DNS 域名与 IP；
- 使用 `+rules` 将规则插入现有规则列表顶部，不替换原有规则；
- 规则集每 24 小时检查一次更新。

### 使用方法

在 OpenClash 的覆写模块页面新增并启用一个 HTTP 类型的远程覆写，订阅链接填写：

```text
https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Block_Encrypted_DNS.conf
```

如果所在网络无法访问 jsDelivr，可改用 GitHub 原始链接：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Block_Encrypted_DNS.conf
```

保存设置并应用配置重启后，可在最终运行配置中确认以下三条规则位于原有规则之前：

```yaml
- DST-PORT,853,REJECT
- RULE-SET,Encrypted-DNS-Domain,REJECT
- RULE-SET,Encrypted-DNS-IP,REJECT,no-resolve
```

### 使用须知

- 此模块只负责拒绝匹配到的加密 DNS 流量，不会自动完成 DNS 劫持、转发或防泄漏配置；相关设置仍需按照 Wiki 完成。
- 使用非标准端口、未知域名或尚未收录 IP 的加密 DNS 服务可能不会被拦截。
- 企业、校园或家庭网络中如有必须使用的 DoT、DoQ 或 DoH 服务，请先评估影响，再决定是否启用。
- 模块依赖 Mihomo 对 MRS 规则集和 OpenClash 覆写合并语法的支持，请使用较新的 OpenClash 与 Mihomo 内核。

## 第三方完整覆写方案

如需完整的远程覆写配置，可使用 [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)。本目录下的 [`OpenClash_Overwrite/`](OpenClash_Overwrite/) 是该项目的 Git 子模块入口，由自动化任务跟踪其 `main` 分支；具体版本、环境变量、适用场景和订阅链接均以上游 README 为准。

该方案会对配置进行较完整的覆写。启用前请备份现有配置，并确认所选版本与主路由、旁路由、IPv6 和 Smart 内核等实际使用场景一致。

## 已归档配置

`Custom_Overwrite.conf` 和 `Custom_Overwrite_NoIPv6.conf` 已于 2025-12-24 移至 [`archived/`](archived/)，不再更新，不建议用于新部署。保留这些文件仅用于历史查阅和旧配置迁移。
