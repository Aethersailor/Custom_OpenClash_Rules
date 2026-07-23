# 🧩 OpenClash 覆写模块

本目录提供可直接添加到 OpenClash 的远程覆写模块，用于在现有配置基础上，按需增加功能或替换特定数据源。

这里的资源主要分为两类：

- 🪶 **轻量覆写模块**：由本项目维护，每个模块只处理一项明确功能，可单独启用，也可按需组合。
- 🧰 **完整覆写方案**：由第三方项目维护，会统一生成或调整策略组、规则、DNS 等多项配置，适合希望快速建立完整配置的用户。

> [!IMPORTANT]
>
> - 💾 启用覆写前，建议备份当前 OpenClash 配置。
> - 🧩 轻量模块通常可以按需组合；如多个模块修改相同配置项，请以各模块的说明为准。
> - ⚠️ 不要同时启用多个功能相近的完整覆写方案。
> - 🔄 新增、停用或更换覆写模块后，需要保存设置并应用配置重启。

---

## 🚀 当前可用资源

| 使用需求 | 推荐资源 |
| --- | --- |
| 🛡️ 阻止局域网设备通过 DoH、DoT 或 DoQ 绕过本地 DNS | [`Block_Encrypted_DNS.conf`](Block_Encrypted_DNS.conf) |
| 🌍 将 GeoIP MMDB 和 GeoIP DAT 数据库替换为本项目维护的数据源 | [`Set_GeoIP_Database_URL.conf`](Set_GeoIP_Database_URL.conf) |
| 🇨🇳 将大陆 IPv4、IPv6 白名单替换为本项目维护的数据源 | [`Set_China_IP_Route_URL.conf`](Set_China_IP_Route_URL.conf) |
| 🧰 使用包含策略组、规则和 DNS 设置的完整远程覆写方案 | [`OpenClash_Overwrite/`](OpenClash_Overwrite/) |

> [!TIP]
>
> 本目录将根据实际需求持续补充新的覆写模块。当前可用资源及其用途以本节表格为准。
>
> 如果准备从头配置 OpenClash，建议优先阅读本项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)，并根据需要使用 [`cfg/`](../cfg/) 目录中的订阅转换模板或 YAML 配置示例。

---

## ⚙️ 通用使用方法

1. 进入 OpenClash 的 **覆写模块** 页面。
2. 新增一个远程覆写模块。
3. 类型选择 `HTTP`。
4. 填写任意便于识别的模块名称。
5. 将对应模块的订阅链接粘贴到地址栏。
6. 启用模块，保存设置并应用配置重启。

不同 OpenClash 版本的页面名称可能略有差异，但操作方式基本一致。

---

# 🛡️ 阻断加密 DNS

[`Block_Encrypted_DNS.conf`](Block_Encrypted_DNS.conf) 用于限制局域网设备绕过路由器配置的 DNS 服务。

## ✨ 主要功能

启用后，模块会：

- 🚫 拒绝目标端口为 TCP 或 UDP `853` 的连接，即 DoT 和 DoQ 使用的标准端口；
- 🌐 拒绝规则集已经收录的加密 DNS 域名；
- 📍 拒绝规则集已经收录的加密 DNS IP；
- ⬆️ 将阻断规则插入现有规则列表顶部；
- 🧩 保留用户原有的规则和规则集；
- 🔄 每 24 小时检查一次远程规则更新。

## 🔗 订阅链接

### 推荐链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Block_Encrypted_DNS.conf
```

### GitHub 原始链接

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Block_Encrypted_DNS.conf
```

## ⚠️ 使用须知

该模块只能阻断标准端口以及规则集已经收录的目标，无法保证拦截所有加密 DNS 流量。

使用以下方式的加密 DNS 服务仍有可能绕过阻断：

- 使用非标准端口；
- 使用尚未收录的域名或 IP；
- 使用共享 CDN IP；
- 通过代理、VPN 或其他隧道访问；
- 直接使用普通 HTTPS 流量访问尚未被识别的 DoH 服务。

该模块也不会自动完成以下配置：

- DNS 劫持或 53 端口重定向；
- OpenClash DNS 上游设置；
- IPv6 DNS 防泄漏；
- OpenWrt 防火墙规则。

> [!WARNING]
>
> 如果企业、校园、家庭网络或自建服务必须使用 DoH、DoT 或 DoQ，请评估影响后再启用。

## 🔍 验证方法

应用配置后，可以在 OpenClash 的最终运行配置或规则提供者页面中确认存在：

```text
COCR-Encrypted-DNS-Domain
COCR-Encrypted-DNS-IP
```

规则列表顶部应当出现：

```yaml
- DST-PORT,853,REJECT
- RULE-SET,COCR-Encrypted-DNS-Domain,REJECT
- RULE-SET,COCR-Encrypted-DNS-IP,REJECT,no-resolve
```

---

# 🌍 替换 GeoIP 数据库地址

[`Set_GeoIP_Database_URL.conf`](Set_GeoIP_Database_URL.conf) 用于将 OpenClash 的 GeoIP 数据库下载地址替换为 [`Aethersailor/geoip`](https://github.com/Aethersailor/geoip) 提供的数据。

## ✨ 主要功能

启用后，模块会替换：

- 🗺️ GeoIP MMDB 数据库：`Country.mmdb`
- 📦 GeoIP DAT 数据库：`geoip.dat`

使用的数据源为：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/geoip@release/Country.mmdb
https://testingcf.jsdelivr.net/gh/Aethersailor/geoip@release/geoip.dat
```

## 🔗 订阅链接

### 推荐链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Set_GeoIP_Database_URL.conf
```

### GitHub 原始链接

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Set_GeoIP_Database_URL.conf
```

## ⚠️ 使用须知

该模块会覆盖 OpenClash 页面或其他配置中已经设置的 GeoIP MMDB 和 GeoIP DAT 自定义下载地址。

该模块不会：

- 自动启用 GeoIP DAT 模式；
- 自动开启 GeoIP 数据库定时更新；
- 修改 GeoSite、GeoASN 或其他 GEO 数据库地址；
- 修改分流规则或策略组。

> [!NOTE]
>
> 模块只负责指定数据库来源。是否使用相应数据库以及何时更新，仍由 OpenClash 的相关设置决定。

## 🔍 验证方法

应用配置后，可以通过以下方式确认：

- 📋 查看 OpenClash 数据库更新日志；
- 🧾 查看最终运行配置中的 Geo 数据库地址；
- 🔄 手动执行一次 GeoIP 数据库更新，确认下载成功。

---

# 🇨🇳 替换大陆 IP 白名单数据源

[`Set_China_IP_Route_URL.conf`](Set_China_IP_Route_URL.conf) 用于替换 OpenClash“绕过中国大陆 IP”等功能所使用的大陆 IPv4 和 IPv6 白名单数据源。

## ✨ 主要功能

启用后，模块会替换：

- 🌐 大陆 IPv4 白名单数据源；
- 🌏 大陆 IPv6 白名单数据源。

使用的数据源为：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/geoip@release/text/cn-ipv4.txt
https://testingcf.jsdelivr.net/gh/Aethersailor/geoip@release/text/cn-ipv6.txt
```

这些数据由 OpenClash 下载后，用于生成对应的大陆 IP 白名单。

## 🔗 订阅链接

### 推荐链接

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Set_China_IP_Route_URL.conf
```

### GitHub 原始链接

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Set_China_IP_Route_URL.conf
```

## ⚠️ 使用须知

该模块会覆盖 OpenClash 页面中已经设置的大陆 IPv4 和 IPv6 白名单自定义下载地址。

该模块不会：

- 自动开启“绕过中国大陆 IP”；
- 自动开启回国模式；
- 自动启用大陆白名单定时更新；
- 修改订阅配置中的分流规则；
- 修改 GeoIP、GeoSite 或其他数据库地址。

> [!NOTE]
>
> 只有在 OpenClash 已经启用相关大陆 IP 白名单功能时，替换后的数据源才会被实际使用。

## 🔍 验证方法

应用配置后，可以手动更新大陆 IP 白名单，并在 OpenClash 日志中确认：

- ✅ IPv4 白名单下载成功；
- ✅ IPv6 白名单下载成功；
- ✅ 数据处理过程中没有格式或网络错误。

---

# 🧰 第三方完整覆写方案

如需通过远程覆写快速建立较完整的 OpenClash 配置，可以参考：

- 📂 本目录入口：[`OpenClash_Overwrite/`](OpenClash_Overwrite/)
- 🔗 上游项目：[Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)

该项目提供适用于不同场景的完整覆写方案，包括：

- 🏠 主路由与旁路由；
- 🌐 启用或不使用 IPv6；
- ⚡ URL-Test 节点选择；
- 🧠 Smart 节点选择。

完整覆写方案通常会同时调整策略组、规则、DNS、节点选择和其他配置项，并可能要求设置订阅地址等环境变量。

使用前请完整阅读上游 README，并按照实际网络结构选择对应版本。具体订阅链接、环境变量、兼容版本和使用要求，均以上游项目的最新说明为准。

> [!WARNING]
>
> 完整覆写方案与轻量功能模块不同，会对最终配置产生较大范围的修改。
>
> 不建议在不了解其配置内容的情况下，与其他完整覆写方案或大量自定义覆写同时启用。

---

# 🧭 推荐使用方式

## ✅ 已经有可正常使用的配置

只希望增加某项功能时，使用本项目维护的轻量模块：

- 🛡️ 阻断加密 DNS；
- 🌍 替换 GeoIP 数据库来源；
- 🇨🇳 替换大陆 IP 白名单来源；
- 未来增加的其他覆写模块。

无需为了单项功能改用完整覆写方案。

## 🆕 准备重新配置 OpenClash

优先按照本项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 完成基础设置，再根据需要使用：

- [`cfg/`](../cfg/) 中的订阅转换模板（已收录于在 OpenClash 内置的模板选择列表中）；
- [`cfg/yaml/`](../cfg/yaml/) 中的 YAML 配置示例；
- 本目录中的轻量覆写模块。

## 🧰 希望通过远程覆写生成完整配置

阅读并使用 [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)，不要同时启用其他功能重叠的完整覆写方案。

---

# ❓ 常见问题

## 多个轻量模块可以同时启用吗？

多数情况下可以，但不能一概而论。

本目录中的轻量模块通常只处理一项明确功能。组合使用前，应查看各模块的“使用须知”，确认它们没有修改相同配置项，也没有与当前配置或其他覆写方案产生冲突。

如果同时使用第三方完整覆写方案，尤其需要检查该方案是否已经修改了相同的数据源、规则、DNS 或其他设置。

## 覆写模块会修改我的订阅源吗？

不会修改远程订阅源本身。

覆写模块会在 OpenClash 加载和应用配置时调整最终运行配置，或者修改 OpenClash 使用的相关数据源地址。

## 停用模块后如何恢复？

停用对应模块，保存设置并重新应用配置即可。

如果此前在 OpenClash 页面中设置过自定义数据源地址，还需要确认原有地址仍然正确。

## 模块没有生效怎么办？

依次检查：

1. ✅ 模块是否已经启用；
2. 🌐 订阅链接是否可以正常下载；
3. 🔄 是否已经保存并应用配置重启；
4. 🧩 是否存在其他覆写模块修改了相同设置；
5. 📦 当前 OpenClash 版本是否支持该模块使用的覆写参数；
6. 📋 OpenClash 日志中是否存在下载、解析或合并错误。

> [!TIP]
>
> 排查时可以暂时只保留一个覆写模块，重新应用配置后确认其是否能够单独生效。
