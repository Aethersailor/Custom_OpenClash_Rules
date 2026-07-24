# 🧩 OpenClash 覆写模块

本目录收录适用于 OpenClash 的远程覆写模块，用于在不直接修改订阅源的前提下，对 OpenClash 最终运行配置或插件使用的数据源进行定向调整。

目录中的资源分为三类：

- 🪶 **轻量功能模块**：只处理一项明确功能，通常可以按需组合；
- 🛡️ **增强型覆写模块**：会联动修改 DNS、规则、策略组或 OpenClash 运行参数，启用前应完整阅读说明；
- 🧰 **第三方完整覆写方案**：用于生成或重构较完整的 OpenClash 配置，影响范围较大。

> [!IMPORTANT]
>
> - 启用覆写前，建议备份当前 OpenClash 配置。
> - 覆写模块不会修改远程订阅源本身，但会影响 OpenClash 加载后的最终运行配置。
> - 多个模块修改相同配置项时，实际结果可能受模块顺序、OpenClash 版本及其他覆写内容影响。
> - 新增、停用或更换模块后，需要保存设置并应用配置重启。
> - 本目录会继续增加新的覆写模块，实际可用资源以目录内容和本文档为准。

---

## 🚀 当前可用资源

| 使用需求 | 推荐资源 | 影响范围 |
| --- | --- | --- |
| 🛡️ 综合降低 DNS 泄漏风险 | [`Prevent_DNS_Leak.conf`](Prevent_DNS_Leak.conf) | DNS、规则、策略组及 OpenClash 运行参数 |
| 🚫 阻止终端通过常见 DoH、DoT、DoQ 绕过本地 DNS | [`Block_Encrypted_DNS.conf`](Block_Encrypted_DNS.conf) | Rule Provider 与前置阻断规则 |
| 🧭 为目标 IP 类规则自动添加 `no-resolve` | [`Add_No_Resolve.conf`](Add_No_Resolve.conf) | 顶层规则与子规则 |
| 🎮 让 Steam CDN 与游戏平台下载流量直连 | [`Direct_Game_Download.conf`](Direct_Game_Download.conf) | Rule Provider 与前置直连规则 |
| 🌍 替换 GeoIP MMDB、GeoIP DAT 数据源 | [`Set_GeoIP_Database_URL.conf`](Set_GeoIP_Database_URL.conf) | OpenClash GEO 数据库地址 |
| 🇨🇳 替换大陆 IPv4、IPv6 白名单数据源 | [`Set_China_IP_Route_URL.conf`](Set_China_IP_Route_URL.conf) | OpenClash Chnroute 数据源 |
| 🧰 使用完整远程覆写方案 | [`OpenClash_Overwrite/`](OpenClash_Overwrite/) | 策略组、规则、DNS、节点选择等多项配置 |
| 📦 查看停止维护的旧版覆写文件 | [`archived/`](archived/) | 仅供历史参考 |

### 模块关系速览

| 组合 | 建议 |
| --- | --- |
| `Prevent_DNS_Leak.conf` + `Block_Encrypted_DNS.conf` | ✅ 推荐。前者负责 OpenClash 内部 DNS 路由与兜底，后者阻断终端主动使用的常见加密 DNS |
| `Prevent_DNS_Leak.conf` + `Add_No_Resolve.conf` | ⚠️ 不需要。前者已经包含后者的核心 `no-resolve` 处理逻辑 |
| `Add_No_Resolve.conf` + `Direct_Game_Download.conf` | ✅ 可以。游戏下载模块中的 IP 规则本身已带 `no-resolve`，不会产生实质冲突 |
| 数据源替换模块与其他轻量模块 | ✅ 通常可以组合，因为它们修改的配置范围不同 |
| 第三方完整覆写方案与其他模块 | ⚠️ 需逐项检查。完整方案可能已经修改相同的 DNS、规则、策略组或数据源 |

---

## ⚙️ 通用使用方法

1. 进入 OpenClash 的 **覆写设置** 或 **覆写模块** 页面；
2. 新增一个远程覆写模块；
3. 模块类型选择 `HTTP`；
4. 填写便于识别的模块名称；
5. 将本文档提供的订阅地址粘贴到模块地址栏；
6. 根据模块说明设置可选参数；
7. 启用模块，保存设置并应用配置重启；
8. 按照各模块的验证方法检查最终运行配置或 OpenClash 日志。

不同 OpenClash 版本的菜单名称可能略有差异，但基本操作方式一致。

> [!TIP]
>
> 排查模块问题时，可以暂时停用其他覆写，只保留目标模块，重新应用配置后确认其能否独立生效。

---

# 🛡️ 综合 DNS 防泄漏

[`Prevent_DNS_Leak.conf`](Prevent_DNS_Leak.conf) 是一个增强型覆写模块，通过 DNS 劫持、DNS 上游规则跟随、IP 规则 `no-resolve` 和最终代理兜底，降低客户端及路由器自身出现 DNS 泄漏的风险。

## ✨ 主要功能

启用后，模块会：

- 强制 OpenClash 使用 `rule` 模式；
- 启用路由器自身代理；
- 启用 OpenClash DNS 劫持，拦截客户端与路由器自身的 TCP/UDP 53 端口查询；
- 启用 Mihomo `dns.respect-rules`，使 DNS 上游连接遵循分流规则；
- 禁止 OpenClash 自动追加 WAN DNS 和自动补充 `default-nameserver`；
- 移除 DNS 列表中的 `system` 解析器；
- 关闭 DNS 的 HTTP/3 优先选项；
- 为 `IP-CIDR`、`IP-CIDR6`、`GEOIP` 规则添加 `no-resolve`；
- 为引用 `behavior: ipcidr` Rule Provider 的 `RULE-SET` 规则添加 `no-resolve`；
- 同时处理顶层 `rules` 与 `sub-rules`；
- 将最终 `MATCH` 或 `FINAL` 改为代理策略；
- 默认创建 `COCR-DNS-Leak-Guard` 策略组，并自动引入全部非直连代理节点和代理集合；
- 当专用策略组为空时回退到 `REJECT`，避免流量意外直连。

## 🔧 可选参数

| 参数 | 用途 | 默认行为 |
| --- | --- | --- |
| `EN_KEY1` | 指定最终 `MATCH` 使用的现有代理组或代理节点 | 留空时创建并使用 `COCR-DNS-Leak-Guard` |
| `EN_KEY2` | 指定 `proxy-server-nameserver`，多个地址使用英文分号 `;` 分隔 | 留空且原配置缺少该项时，尝试复用 `default-nameserver` |

`EN_KEY1` 不能使用 `DIRECT`、`REJECT`、`REJECT-DROP`、`PASS`、`COMPATIBLE` 等非代理目标。参数无效时，模块会回退到 `COCR-DNS-Leak-Guard`。

`EN_KEY2` 示例：

```text
https://1.1.1.1/dns-query;https://8.8.8.8/dns-query
```

## 🔗 订阅链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Prevent_DNS_Leak.conf
```

GitHub 原始链接：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Prevent_DNS_Leak.conf
```

## ⚠️ 使用须知

该模块影响范围较大，会主动改写 DNS、规则、策略组及 OpenClash 运行参数。

启用前请确认：

- 你接受最终 `MATCH` 或 `FINAL` 被改为代理策略；
- 当前代理节点或代理集合可供 `COCR-DNS-Leak-Guard` 使用；
- `proxy-server-nameserver` 使用可访问且适合解析代理节点域名的 DNS；
- 局域网 IPv6 DNS 流量已经由 OpenClash 接管，或另有可靠的 IPv6 DNS 防泄漏方案；
- 没有其他覆写模块同时强制修改 `MATCH`、DNS 劫持、`respect-rules` 或同名策略组。

该模块不会：

- 自动替你选择或更换具体 DNS 上游；
- 处理 `AND`、`OR`、`NOT` 等逻辑规则内部嵌套的 IP 规则；
- 阻断终端自身发起的 DoH、DoT 或 DoQ；
- 解决未被 OpenClash 接管的 IPv6 DNS 流量。

> [!WARNING]
>
> 如果 `default-nameserver` 使用普通 UDP/TCP DNS，代理节点域名的引导解析仍可能被网络侧观察。建议明确设置可靠的 `proxy-server-nameserver`。

> [!TIP]
>
> 建议同时启用 [`Block_Encrypted_DNS.conf`](Block_Encrypted_DNS.conf)，阻止终端通过常见加密 DNS 绕过路由器 DNS。
>
> 无需同时启用 [`Add_No_Resolve.conf`](Add_No_Resolve.conf)，因为本模块已经包含对应功能。

## 🔍 验证方法

应用配置后，检查最终运行配置：

```yaml
dns:
  enable: true
  respect-rules: true
  prefer-h3: false
```

同时确认：

- 存在有效的 `proxy-server-nameserver`；
- DNS 列表中没有 `system`；
- 目标 IP 类规则带有 `no-resolve`；
- 最终规则为 `MATCH,<代理目标>`；
- 未指定 `EN_KEY1` 时存在 `COCR-DNS-Leak-Guard` 策略组；
- OpenClash 日志中没有模块参数、Ruby 覆写或配置校验错误。

---

# 🚫 阻断加密 DNS

[`Block_Encrypted_DNS.conf`](Block_Encrypted_DNS.conf) 用于阻止局域网终端通过常见 DoH、DoT 或 DoQ 绕过路由器配置的 DNS 服务。

## ✨ 主要功能

启用后，模块会：

- 阻断 TCP/UDP 目标端口 `853`，即 DoT 与 DoQ 的标准端口；
- 添加加密 DNS 域名 MRS Rule Provider；
- 添加加密 DNS IP MRS Rule Provider；
- 将三条阻断规则插入现有规则列表顶部；
- 保留用户原有的 `rules` 与 `rule-providers`；
- 每 24 小时检查一次远程规则更新。

## 🔗 订阅链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Block_Encrypted_DNS.conf
```

GitHub 原始链接：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Block_Encrypted_DNS.conf
```

## ⚠️ 使用须知

该模块只能阻断标准端口和规则集已经收录的目标，无法保证识别所有加密 DNS 流量。

以下方式仍可能绕过阻断：

- 使用非标准端口；
- 使用尚未收录的域名或 IP；
- 使用共享 CDN IP；
- 通过代理、VPN 或其他隧道访问；
- 将 DoH 混入未被识别的普通 HTTPS 流量。

该模块不会自动完成：

- DNS 劫持或 53 端口重定向；
- OpenClash DNS 上游设置；
- IPv6 DNS 防泄漏；
- OpenWrt 防火墙配置。

> [!WARNING]
>
> 企业、校园、自建服务或特定终端可能必须使用 DoH、DoT 或 DoQ。启用前应评估对这些服务的影响。

## 🔍 验证方法

最终运行配置中应存在：

```text
COCR-Encrypted-DNS-Domain
COCR-Encrypted-DNS-IP
```

规则列表顶部应出现：

```yaml
- DST-PORT,853,REJECT
- RULE-SET,COCR-Encrypted-DNS-Domain,REJECT
- RULE-SET,COCR-Encrypted-DNS-IP,REJECT,no-resolve
```

---

# 🧭 自动添加 no-resolve

[`Add_No_Resolve.conf`](Add_No_Resolve.conf) 用于为目标 IP 类规则自动添加 `no-resolve`，避免这些规则为了匹配域名连接而主动触发 DNS 解析。

## ✨ 主要功能

模块会处理：

- `IP-CIDR`；
- `IP-CIDR6`；
- `GEOIP`；
- 引用 `behavior: ipcidr` Rule Provider 的 `RULE-SET`；
- 顶层 `rules`；
- `sub-rules` 中的直接规则。

处理过程中会：

- 保留原有规则顺序和策略；
- 保留其他附加参数；
- 跳过已经包含 `no-resolve` 的规则；
- 跳过包含 `src` 参数的规则。

## 🔗 订阅链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Add_No_Resolve.conf
```

GitHub 原始链接：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Add_No_Resolve.conf
```

## ⚠️ 使用须知

该模块不会：

- 修改 Rule Provider 文件内部的规则；
- 处理 `behavior: domain` 或 `behavior: classical` 的 Rule Provider；
- 解析 `AND`、`OR`、`NOT` 等逻辑规则内部嵌套的 IP 规则；
- 处理 `IP-ASN`、`IP-SUFFIX`、`SRC-IP-CIDR` 或 `SRC-GEOIP`；
- 阻止其他规则或 DNS 模块提前完成域名解析。

`no-resolve` 会改变部分依赖“域名先解析为 IP、再由 IP 规则命中”的分流行为。启用后应检查常用服务的实际命中结果。

> [!NOTE]
>
> [`Prevent_DNS_Leak.conf`](Prevent_DNS_Leak.conf) 已经包含本模块的核心功能。启用前者时，不需要再启用本模块。

## 🔍 验证方法

在 OpenClash 最终运行配置中检查目标规则，例如：

```yaml
- IP-CIDR,1.1.1.0/24,DIRECT,no-resolve
- IP-CIDR6,2606:4700::/32,Proxy,no-resolve
- GEOIP,CN,DIRECT,no-resolve
- RULE-SET,Example-IP,DIRECT,no-resolve
```

---

# 🎮 游戏下载直连

[`Direct_Game_Download.conf`](Direct_Game_Download.conf) 用于将 Steam 下载 CDN 与 Mihomo GeoSite 中的游戏平台下载分类设为直连。

## ✨ 主要功能

启用后，模块会：

- 添加本项目维护的 Steam CDN 域名 Rule Provider；
- 添加本项目维护的 Steam CDN IP Rule Provider；
- 将 Steam CDN 域名流量设为 `DIRECT`；
- 将 Steam CDN IP 流量设为 `DIRECT,no-resolve`；
- 将 `GEOSITE,category-game-platforms-download` 设为 `DIRECT`；
- 将上述规则插入现有规则列表顶部；
- 保留用户原有规则与 Rule Provider；
- 每 8 小时检查一次远程规则更新。

## 🔗 订阅链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Direct_Game_Download.conf
```

GitHub 原始链接：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Direct_Game_Download.conf
```

## ⚠️ 使用须知

该模块仅针对游戏下载与更新流量，不会将以下流量全部改为直连：

- 游戏平台登录；
- 商店页面；
- 社区与聊天；
- 云存档；
- 游戏联机；
- 其他未被规则识别的业务流量。

模块依赖当前 Mihomo GeoSite 数据包含：

```text
category-game-platforms-download
```

如果运营商对特定游戏平台的国内下载线路质量较差，直连不一定比代理更快。出现下载失败、速度异常或 CDN 调度不理想时，应检查规则命中、DNS 结果及实际下载节点。

## 🔍 验证方法

最终运行配置中应存在：

```text
COCR-Steam-CDN-Domain
COCR-Steam-CDN-IP
```

规则列表顶部应出现：

```yaml
- RULE-SET,COCR-Steam-CDN-Domain,DIRECT
- RULE-SET,COCR-Steam-CDN-IP,DIRECT,no-resolve
- GEOSITE,category-game-platforms-download,DIRECT
```

---

# 🌍 替换 GeoIP 数据库地址

[`Set_GeoIP_Database_URL.conf`](Set_GeoIP_Database_URL.conf) 用于将 OpenClash 的 GeoIP MMDB 与 GeoIP DAT 下载地址替换为 [`Aethersailor/geoip`](https://github.com/Aethersailor/geoip) 提供的数据。

## ✨ 主要功能

模块会替换：

- `Country.mmdb`；
- `geoip.dat`。

使用的数据源：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/geoip@release/Country.mmdb
https://testingcf.jsdelivr.net/gh/Aethersailor/geoip@release/geoip.dat
```

该设置同时作用于：

- OpenClash 启动时生成的 Mihomo `geox-url`；
- OpenClash 自身的 GEO 数据库更新流程。

## 🔗 订阅链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Set_GeoIP_Database_URL.conf
```

GitHub 原始链接：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Set_GeoIP_Database_URL.conf
```

## ⚠️ 使用须知

该模块会覆盖 OpenClash 页面或其他配置中已经设置的 GeoIP MMDB 与 GeoIP DAT 自定义下载地址。

该模块不会：

- 自动启用 GeoIP DAT 模式；
- 自动开启 MMDB 或 DAT 数据库定时更新；
- 修改 GeoSite、GeoASN 或其他 GEO 数据库地址；
- 修改分流规则或策略组。

## 🔍 验证方法

应用配置后，可以通过以下方式确认：

- 查看最终运行配置中的 `geox-url.mmdb` 与 `geox-url.geoip`；
- 查看 OpenClash 数据库更新日志；
- 手动执行一次 GeoIP 数据库更新，确认下载成功。

---

# 🇨🇳 替换大陆 IP 白名单数据源

[`Set_China_IP_Route_URL.conf`](Set_China_IP_Route_URL.conf) 用于替换 OpenClash 大陆 IPv4 与 IPv6 白名单使用的 Chnroute 数据源。

## ✨ 主要功能

模块会替换：

- 大陆 IPv4 白名单数据源；
- 大陆 IPv6 白名单数据源。

使用的数据源：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/geoip@release/text/cn-ipv4.txt
https://testingcf.jsdelivr.net/gh/Aethersailor/geoip@release/text/cn-ipv6.txt
```

这些数据由 OpenClash 下载后，用于生成相应的 nftables 或 ipset 数据。

## 🔗 订阅链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Set_China_IP_Route_URL.conf
```

GitHub 原始链接：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Set_China_IP_Route_URL.conf
```

## ⚠️ 使用须知

该模块会覆盖 OpenClash 页面中已经设置的大陆 IPv4 与 IPv6 白名单自定义下载地址。

该模块不会：

- 自动开启“绕过中国大陆 IP”；
- 自动开启“回国”模式；
- 自动启用大陆白名单定时更新；
- 修改订阅配置中的分流规则；
- 修改 GeoIP、GeoSite、Rule Provider 或 Mihomo `geox-url`。

> [!NOTE]
>
> 只有在 OpenClash 已启用相关大陆 IP 白名单功能时，替换后的数据源才会被实际使用。

## 🔍 验证方法

手动更新大陆 IP 白名单，并在 OpenClash 日志中确认：

- IPv4 Chnroute 下载成功；
- IPv6 Chnroute6 下载成功；
- 数据解析和 nftables 或 ipset 生成过程没有报错。

---

# 🧰 第三方完整覆写方案

[`OpenClash_Overwrite/`](OpenClash_Overwrite/) 是 [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite) 的 Git 子模块镜像入口。

该项目提供面向不同网络结构和节点选择方式的完整覆写方案，例如：

- 主路由与旁路由；
- 启用或不使用 IPv6；
- URL-Test 节点选择；
- Smart 节点选择。

完整覆写方案通常会同时生成或调整：

- 策略组；
- 分流规则；
- DNS；
- Rule Provider；
- 节点选择；
- 订阅地址或环境参数；
- 其他 Mihomo 配置项。

具体文件、订阅链接、环境变量、兼容版本和使用要求，均以上游项目 README 的最新说明为准。

> [!WARNING]
>
> 完整覆写方案与本项目维护的单功能模块不同，会对最终配置产生较大范围的修改。
>
> 不建议同时启用多个完整覆写方案。与本目录其他模块组合时，也必须确认没有重复修改 DNS、策略组、最终规则或数据源。

---

# 🧭 推荐使用方式

## ✅ 已经有可正常使用的配置

只希望增加某项功能时，优先使用本项目维护的单功能模块：

- 防止终端绕过本地 DNS；
- 为 IP 类规则添加 `no-resolve`；
- 让游戏下载流量直连；
- 替换 OpenClash 数据库或白名单来源。

无需为了单项功能改用完整覆写方案。

## 🛡️ 希望强化 DNS 防泄漏

建议组合：

```text
Prevent_DNS_Leak.conf
Block_Encrypted_DNS.conf
```

前者负责 OpenClash 内部的 DNS 劫持、上游规则跟随、`no-resolve` 和最终代理兜底；后者负责阻断终端主动发起的常见加密 DNS。

该组合仍不能替代完整的 IPv6 DNS 管理、终端安全策略或网络侧审计。

## 🆕 准备重新配置 OpenClash

建议先按照本项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 完成基础设置，再按需使用：

- [`cfg/`](../cfg/) 中的订阅转换模板；
- [`cfg/yaml/`](../cfg/yaml/) 中的 YAML 配置示例；
- 本目录中的功能覆写模块。

> [!TIP]
>
> 本项目订阅转换模板的远程链接已收录于 OpenClash 内置模板选择列表中，OpenClash 用户通常无需手动填写模板地址。

## 🧰 希望通过远程覆写生成完整配置

阅读并使用 [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)，根据实际网络结构选择对应方案，不要同时启用其他功能重叠的完整覆写。

---

# ❓ 常见问题

## 多个功能模块可以同时启用吗？

多数情况下可以，但应先检查模块修改范围。

通常可以直接组合的模块包括：

- 数据源替换模块与规则模块；
- 游戏下载直连与 DNS 阻断模块；
- `Add_No_Resolve.conf` 与不包含同类处理逻辑的其他轻量模块。

不建议重复启用：

- `Prevent_DNS_Leak.conf` 与 `Add_No_Resolve.conf`；
- 多个会重写最终 `MATCH` 或 `FINAL` 的模块；
- 多个会创建或替换同名策略组的模块；
- 多个完整覆写方案。

## 覆写模块会修改我的订阅源吗？

不会修改远程订阅源本身。

模块会在 OpenClash 加载配置时修改最终运行配置，或者替换 OpenClash 使用的数据源地址。停用模块并重新应用配置后，相应覆写通常会消失。

## 模块顺序重要吗？

可能重要。

当多个模块修改相同数组、字段或最终规则时，后执行的覆写可能覆盖前面的结果。具体行为还取决于 OpenClash 对覆写模块的加载顺序和模块使用的覆写方式。

模块之间存在功能重叠时，不应依赖顺序解决冲突，而应停用重复模块。

## 停用模块后如何恢复？

1. 停用或删除对应覆写模块；
2. 保存 OpenClash 设置；
3. 重新应用配置并重启；
4. 检查最终运行配置；
5. 如果模块替换过数据源地址，确认 OpenClash 页面中的原始自定义地址仍然正确。

## 模块没有生效怎么办？

依次检查：

1. 模块是否已经启用；
2. 订阅地址是否可以正常下载；
3. 是否已经保存并应用配置重启；
4. OpenClash 是否支持模块使用的 `[General]`、`[YAML]`、`[Overwrite]` 或 `ruby_edit` 能力；
5. Mihomo 是否支持模块所需的 MRS、Rule Provider、GeoSite、`respect-rules` 或 `no-resolve`；
6. 是否存在其他覆写模块修改了相同设置；
7. OpenClash 日志中是否存在下载、解析、Ruby 执行、配置校验或内核启动错误；
8. 最终运行配置中是否出现模块预期写入的字段、规则或策略组。

## jsDelivr 地址无法访问怎么办？

可以临时改用对应的 GitHub 原始链接。

但 GitHub 原始链接在部分网络环境中的访问质量可能不稳定。建议优先解决网络或 DNS 问题，不要长期依赖来源不明的第三方转发地址。

---

# 📦 已归档资源

[`archived/`](archived/) 保存已经停止维护的旧版远程覆写配置：

- `Custom_Overwrite.conf`；
- `Custom_Overwrite_NoIPv6.conf`。

这些文件已于 2025-12-24 归档，仅供历史参考，不建议继续部署。

需要完整配置时，请优先使用：

- 本项目 Wiki 与订阅转换模板；
- [`cfg/yaml/`](../cfg/yaml/) 中的配置示例；
- [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)。

---

## 📄 许可证与维护

本目录中的自维护模块随本仓库一并维护。第三方子模块遵循其上游项目的许可证与维护策略。

发现模块失效、规则冲突、OpenClash 兼容性变化或文档错误时，请通过本仓库的 Issue 反馈，并提供：

- OpenClash 版本；
- Mihomo 内核版本；
- 使用的模块列表；
- 相关环境参数；
- 最终运行配置中的相关片段；
- OpenClash 日志中的具体错误。
