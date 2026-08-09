<div align="center">

# 🧩 OpenClash 远程覆写模块

**按需增强现有配置，不必重写整份 YAML**

[快速选择](#-快速选择) · [使用方法](#overwrite-usage) · [模块说明](#-模块说明) · [组合建议](#-组合与冲突) · [故障排查](#-故障排查)

</div>

---

本目录主要存放由本项目维护的 **OpenClash 远程覆写模块**。这些模块用于在 OpenClash 加载配置时，按需修改规则、DNS、Rule Provider 或插件数据源。

> [!IMPORTANT]
> 覆写模块只能调整其声明的配置项，不能替代 OpenClash LuCI 页面中的插件设置。
>
> 建议先按照项目 Wiki 的 [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)，结合自身网络环境完成插件设置，再选择需要的覆写模块。

## 📁 目录说明

| 位置 | 用途 |
| --- | --- |
| 本目录直接存放的 `.conf` | 本项目维护的单功能远程覆写模块，本文重点介绍 |
| [`yaml/`](./yaml/) | 存放用于远程调用本项目 YAML 配置文件的覆写模块；文件区别、变量和订阅地址请查看 [`yaml/`](./yaml/) |
| [`OpenClash_Overwrite/`](./OpenClash_Overwrite/) | 第三方完整覆写方案，具体用法以上游 README 为准 |
| [`archived/`](./archived/) | 已停止维护的旧版文件，仅供历史参考 |

> [!NOTE]
> `yaml/` 目录中的模块用于下载、填写并切换本项目的 YAML 配置，与本目录直接存放的单功能增强模块用途不同。此处不再展开介绍。

## 🚀 快速选择

| 模块 | 主要作用 | 影响范围 | 是否需要参数 |
| --- | --- | --- | :---: |
| [`Prevent_DNS_Leak.conf`](./Prevent_DNS_Leak.conf) | 综合降低 DNS 泄漏风险 | DNS、规则、最终策略及专用策略组 | 可选 |
| [`Block_Encrypted_DNS.conf`](./Block_Encrypted_DNS.conf) | 阻断常见 DoH、DoT、DoQ 绕过 | Rule Provider 与前置阻断规则 | 否 |
| [`Add_No_Resolve.conf`](./Add_No_Resolve.conf) | 为目标 IP 类规则补充 `no-resolve` | `rules` 与 `sub-rules` | 否 |
| [`Rule_Provider_Format_Fix.conf`](./Rule_Provider_Format_Fix.conf) | 根据文件扩展名补全或修正 Rule Provider 的 `format` | `rule-providers.*.format` | 否 |
| [`Direct_Game_Download.conf`](./Direct_Game_Download.conf) | 让 Steam CDN 和游戏平台下载流量直连 | Rule Provider 与前置直连规则 | 否 |
| [`Set_GeoIP_Database_URL.conf`](./Set_GeoIP_Database_URL.conf) | 替换 GeoIP MMDB 与 DAT 数据源 | OpenClash GEO 数据库地址 | 否 |
| [`Set_China_IP_Route_URL.conf`](./Set_China_IP_Route_URL.conf) | 替换大陆 IPv4、IPv6 白名单数据源 | OpenClash Chnroute 数据源 | 否 |

### 按需求选择

- 想系统降低 DNS 泄漏风险：使用 `Prevent_DNS_Leak.conf`。
- 只想阻止终端使用常见加密 DNS 绕过本地 DNS：使用 `Block_Encrypted_DNS.conf`。
- 只需要给 IP 类规则补充 `no-resolve`：使用 `Add_No_Resolve.conf`。
- Rule Provider 因缺少或写错 `format` 导致加载失败：使用 `Rule_Provider_Format_Fix.conf`。
- 希望游戏下载和更新尽量走直连：使用 `Direct_Game_Download.conf`。
- 只想替换 OpenClash 使用的数据源：选择对应的 `Set_*.conf` 模块。

<a id="overwrite-usage"></a>

## ⚙️ 通用使用方法

1. 进入「服务」→「OpenClash」→「覆写设置」→「覆写模块」。
2. 新增远程覆写模块。
3. 模块类型选择「HTTP」。
4. 填写便于识别的模块名称。
5. 从本文复制 testingcf 或 GitHub Raw 订阅地址。
6. 仅在模块说明要求时填写 `EN_KEY` 参数。
7. 启用模块并保存设置。
8. 重新应用配置并启动 OpenClash。
9. 检查 OpenClash 日志及最终运行配置，确认模块已经生效。

不同 OpenClash 版本的菜单名称可能略有差异。

> [!TIP]
> testingcf 与 GitHub Raw 指向同一个仓库文件，只需要选择其中一个。testingcf 通常更适合 GitHub Raw 访问质量不佳的网络环境。

<!-- -->

> [!WARNING]
> 新增、停用或更换模块后，必须重新应用配置。仅显示「模块订阅成功」不代表最终 YAML 校验和 Mihomo 内核启动一定成功。

## 📦 模块说明

### 🛡️ Prevent DNS Leak

[`Prevent_DNS_Leak.conf`](./Prevent_DNS_Leak.conf) 是本项目自行维护且影响范围最大的模块，用于通过 DNS 劫持、DNS 上游规则跟随、`no-resolve` 以及将最终规则指向代理目标等方式降低 DNS 泄漏风险。

主要操作：

- 强制使用 `rule` 模式；
- 启用路由器自身代理和 OpenClash DNS 劫持；
- 启用 `dns.respect-rules`；
- 禁止自动追加 WAN DNS 和自动补充 `default-nameserver`；
- 清除 DNS 列表中的 `system`，关闭 DNS HTTP/3 偏好；
- 为目标 IP 类规则补充 `no-resolve`；
- 将最终 `MATCH` 或 `FINAL` 指向代理目标；
- 未指定代理目标时创建 `COCR-DNS-Leak-Guard` 策略组。

可选参数：

| 参数 | 作用 | 留空行为 |
| --- | --- | --- |
| `EN_KEY1` | 指定最终规则使用的现有代理组或代理节点 | 创建并使用 `COCR-DNS-Leak-Guard` |
| `EN_KEY2` | 指定 `proxy-server-nameserver`，多个地址用英文分号分隔 | 尝试复用有效的 `default-nameserver` |

jsDelivr CDN：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Prevent_DNS_Leak.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Prevent_DNS_Leak.conf
```

验收重点：

- `dns.respect-rules: true`；
- 存在有效的 `proxy-server-nameserver`；
- DNS 列表中没有 `system`；
- 目标 IP 类规则带有 `no-resolve`；
- 最终规则指向预期代理目标；
- 日志中没有 Ruby 覆写或配置校验错误。

> [!CAUTION]
> 本模块会强制修改 DNS、规则和最终代理策略。启用前应备份当前可用配置，并确认不会与其他 DNS 或最终规则覆写重复。

---

### 🚫 Block Encrypted DNS

[`Block_Encrypted_DNS.conf`](./Block_Encrypted_DNS.conf) 用于阻止局域网终端通过常见 DoH、DoT 或 DoQ 绕过路由器配置的 DNS 服务。

主要操作：

- 阻断 TCP/UDP 目标端口 `853`；
- 添加加密 DNS 域名 MRS Rule Provider；
- 添加加密 DNS IP MRS Rule Provider；
- 将三条阻断规则插入现有规则列表顶部；
- 保留原有 `rules` 和 `rule-providers`。

jsDelivr CDN：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Block_Encrypted_DNS.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Block_Encrypted_DNS.conf
```

验收重点：

```yaml
- DST-PORT,853,REJECT
- RULE-SET,COCR-Encrypted-DNS-Domain,REJECT
- RULE-SET,COCR-Encrypted-DNS-IP,REJECT,no-resolve
```

限制：

- 无法识别所有非标准端口或尚未收录的加密 DNS；
- 无法可靠区分共享 CDN 上的全部 DoH 流量；
- 不负责 DNS 劫持、IPv6 DNS 管理或 OpenWrt 防火墙设置；
- 可能影响确实需要使用加密 DNS 的企业、校园或自建服务。

---

### 🧭 Add No Resolve

[`Add_No_Resolve.conf`](./Add_No_Resolve.conf) 用于为以下目标 IP 类规则添加 `no-resolve`：

- `IP-CIDR`；
- `IP-CIDR6`；
- `GEOIP`；
- 引用 `behavior: ipcidr` Rule Provider 的 `RULE-SET`；
- 顶层 `rules` 和 `sub-rules` 中的直接规则。

模块会保留原有规则顺序、策略和其他附加参数，并跳过已经含有 `no-resolve` 或 `src` 的规则。

jsDelivr CDN：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Add_No_Resolve.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Add_No_Resolve.conf
```

限制：

- 不修改 Rule Provider 文件内部的规则；
- 不处理 `behavior: domain` 或 `behavior: classical` 的 Provider；
- 不解析 `AND`、`OR`、`NOT` 内部嵌套规则；
- 不处理 `IP-ASN`、`IP-SUFFIX`、`SRC-IP-CIDR` 或 `SRC-GEOIP`。

> [!NOTE]
> `Prevent_DNS_Leak.conf` 已经包含本模块的核心功能。启用前者时，不需要再启用本模块。

---

### 🧩 Rule Provider Format Fix

[`Rule_Provider_Format_Fix.conf`](./Rule_Provider_Format_Fix.conf) 用于根据 Rule Provider 的实际文件扩展名补全或修正 `format` 字段，以解决传统 subconverter 转换出的配置文件缺少 `format:` 字段的问题。

判断规则：

| 文件扩展名 | 写入的 `format` |
| --- | --- |
| `.mrs` | `mrs` |
| `.yaml`、`.yml` | `yaml` |

处理逻辑：

- 普通远程 Provider 优先检查 `url`，再检查 `path`；
- `type: file` 优先检查 `path`，再检查 `url`；
- 自动忽略 URL 查询参数和 `#fragment`；
- 扩展名匹配不区分大小写；
- 识别到受支持扩展名时，会修正已有的错误 `format`；
- 未识别到 `.mrs`、`.yaml` 或 `.yml` 时保持原配置不变。

jsDelivr CDN：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Rule_Provider_Format_Fix.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Rule_Provider_Format_Fix.conf
```

验收示例：

```yaml
rule-providers:
  Example-MRS:
    url: https://example.com/rules/example.mrs
    format: mrs

  Example-YAML:
    url: https://example.com/rules/example.yaml?token=example
    format: yaml
```

限制：

- 只处理顶层 `rule-providers`；
- 只识别 `.mrs`、`.yaml` 和 `.yml`；
- 不修改 `type`、`behavior`、`url` 或 `path`；
- 不下载并验证文件实际内容；
- 如果文件扩展名本身与内容不一致，模块仍会按扩展名设置 `format`。

---

### 🎮 Direct Game Download

[`Direct_Game_Download.conf`](./Direct_Game_Download.conf) 用于将游戏下载与更新流量优先设为直连。

主要操作：

- 添加本项目维护的 Steam CDN 域名 Rule Provider；
- 添加 Steam CDN IP Rule Provider；
- 将对应域名和 IP 规则设为直连；
- 添加 `GEOSITE,category-game-platforms-download,DIRECT`；
- 将相关规则插入现有规则列表顶部。

jsDelivr CDN：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Direct_Game_Download.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Direct_Game_Download.conf
```

限制：

- 只处理游戏下载和更新流量；
- 不会将登录、商店、社区、云存档或游戏联机全部改为直连；
- 依赖 Mihomo GeoSite 数据包含 `category-game-platforms-download`；
- 直连速度仍取决于运营商、DNS 和 CDN 调度结果。

---

### 🌍 Set GeoIP Database URL

[`Set_GeoIP_Database_URL.conf`](./Set_GeoIP_Database_URL.conf) 用于替换 OpenClash 使用的：

- GeoIP MMDB：`Country.mmdb`；
- GeoIP DAT：`geoip.dat`。

jsDelivr CDN：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Set_GeoIP_Database_URL.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Set_GeoIP_Database_URL.conf
```

模块会同时影响 OpenClash 启动时生成的 `geox-url` 和插件自身的数据库更新流程。

限制：

- 不会自动启用 GeoIP DAT 模式；
- 不会自动开启数据库定时更新；
- 不修改 GeoSite、GeoASN、规则或策略组；
- 会覆盖 OpenClash 页面中已有的 GeoIP MMDB 与 DAT 自定义地址。

---

### 🇨🇳 Set China IP Route URL

[`Set_China_IP_Route_URL.conf`](./Set_China_IP_Route_URL.conf) 用于替换 OpenClash 大陆白名单使用的 IPv4 和 IPv6 Chnroute 数据源。

jsDelivr CDN：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Set_China_IP_Route_URL.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Set_China_IP_Route_URL.conf
```

限制：

- 不会自动开启「绕过中国大陆 IP」或「回国」模式；
- 不会自动开启大陆白名单定时更新；
- 不修改配置文件中的 GeoIP、GeoSite、Rule Provider 或 `geox-url`；
- 只有相关大陆 IP 白名单功能已经启用时，新数据源才会被实际使用。

## 🔗 组合与冲突

| 组合 | 建议 |
| --- | --- |
| `Prevent_DNS_Leak.conf` 与 `Block_Encrypted_DNS.conf` | ✅ 可组合，分别处理 OpenClash 内部 DNS 路由和终端常见加密 DNS |
| `Prevent_DNS_Leak.conf` 与 `Add_No_Resolve.conf` | ❌ 不需要组合，前者已包含 `no-resolve` 处理 |
| `Rule_Provider_Format_Fix.conf` 与其他单功能模块 | ✅ 通常可以组合，但需确认没有故意使用与扩展名不一致的 `format` |
| `Direct_Game_Download.conf` 与数据源替换模块 | ✅ 通常可以组合，两者修改范围不同 |
| `yaml/` 中的远程 YAML 模块与根目录单功能模块 | ⚠️ 可以组合，但应检查模块顺序和最终运行配置 |
| 第三方完整覆写方案与本目录模块 | ⚠️ 必须逐项检查，避免重复修改 DNS、规则、策略组或数据源 |
| 多个完整覆写方案 | ❌ 不建议同时启用 |

当两个模块修改同一字段、同一规则数组或同一策略组时，后执行的模块可能覆盖先执行的结果。不要依赖执行顺序长期维持冲突配置。

## ✅ 最终验收

应用模块后，至少检查：

- 远程模块下载成功；
- OpenClash 配置校验通过；
- Mihomo 内核启动成功；
- Rule Provider 下载和解析成功；
- 最终运行配置中出现模块预期写入的字段或规则；
- DNS、IPv4、IPv6 和流量接管仍符合预期；
- 常用服务的规则命中符合预期；
- 日志中没有 Ruby、YAML、Provider 或内核错误。

## 🔍 故障排查

模块没有生效时，依次检查：

1. 模块是否已经启用；
2. testingcf 或 GitHub Raw 地址是否能够正常下载；
3. 是否已保存设置并重新应用配置；
4. `EN_KEY` 参数格式是否正确；
5. OpenClash 是否支持模块使用的 `[General]`、`[YAML]`、`[Overwrite]` 或 `ruby_edit`；
6. 是否有其他模块修改同一配置项；
7. 最终运行配置中是否出现预期结果；
8. OpenClash 日志是否存在下载、解析、Ruby、配置校验或内核启动错误。

排查冲突时，建议暂时停用其他覆写模块，只保留目标模块重新测试。

## 📚 相关文档

- [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)
- [YAML 配置远程覆写模块](./yaml/)
- [YAML 配置文件说明](../cfg/yaml/)
- [订阅转换模板说明](../cfg/)
- [已归档覆写模块](./archived/)

---

<div align="center">

模块功能和兼容性可能随 OpenClash 与 Mihomo 更新而调整，请以仓库 `main` 分支中的最新文件为准。

</div>
