<div align="center">

# 🧩 OpenClash 覆写模块

**功能增强模块、远程 YAML 配置模块与完整覆写方案**

[目录结构](#-目录结构) · [推荐使用流程](#-推荐使用流程) · [功能模块](#-功能覆写模块) · [远程 YAML](#-远程-yaml-配置模块) · [使用方法](#%EF%B8%8F-通用使用方法) · [注意事项](#%EF%B8%8F-注意事项)

</div>

---

本目录收录适用于 OpenClash 的覆写模块及相关资源。不同类型的模块用途并不相同：

- 根目录中的 `.conf` 是**功能覆写模块**，用于向现有配置增加或调整某项功能；
- [`yaml/`](./yaml/) 中的 `.conf` 是**远程 YAML 配置模块**，用于下载本项目 YAML、写入订阅地址并切换配置；
- [`OpenClash_Overwrite/`](./OpenClash_Overwrite/) 是第三方完整覆写方案；
- [`archived/`](./archived/) 保存已经停止维护的旧版文件。

> [!IMPORTANT]
> 建议先按照项目 Wiki 的 [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)，根据自身网络环境检查并完成 OpenClash LuCI 页面中的 DNS、IPv6、运行模式、流量接管及其他插件设置，再选择配置使用路径。
>
> 覆写模块不会替代这些 LuCI 设置。模块是否正确执行，也不代表 OpenClash 的最终运行状态一定正确。

## 📁 目录结构

| 目录或文件 | 类型 | 主要用途 |
| --- | --- | --- |
| 根目录 `.conf` | 功能覆写模块 | 对已有配置追加 DNS、规则、`no-resolve`、数据源等功能 |
| [`yaml/`](./yaml/) | 远程 YAML 配置模块 | 调用 [`cfg/yaml/`](../cfg/yaml/) 中的 YAML，写入订阅并自动切换配置 |
| [`OpenClash_Overwrite/`](./OpenClash_Overwrite/) | 第三方完整覆写方案 | 按上游方案生成或重构策略组、规则、DNS 等配置 |
| [`archived/`](./archived/) | 已归档资源 | 仅供历史参考，不建议继续部署 |

> [!NOTE]
> `yaml/` 子目录不是一个普通的单功能覆写模块集合。它对应本项目推荐的三种 OpenClash 使用路径之一，负责远程部署完整的策略组与分流配置。

## 🧭 推荐使用流程

本项目建议按照以下顺序使用 OpenClash：

1. 阅读 Wiki，并根据自身环境完成 OpenClash LuCI 设置；
2. 从三种配置路径中选择一种；
3. 根据需要叠加根目录中的功能覆写模块；
4. 应用配置并重启；
5. 验收内核、节点、Provider、策略组、规则、DNS、IPv6、流量接管和日志；
6. 确认稳定后再进入日常使用。

### 三种配置路径

| 路径 | 优点 | 局限 | 适合用户 |
| --- | --- | --- | --- |
| **订阅转换 + `.ini` 模板** | 操作最简单，更新订阅和切换模板方便 | 依赖订阅转换后端；公共后端的可用性和隐私取决于服务提供者 | 希望低成本使用和快速切换配置的用户 |
| **远程 YAML 配置模块** | 不依赖订阅转换；自动下载 YAML、写入订阅并切换配置 | 需要理解 OpenClash 覆写模块及 `EN_KEY` 参数 | 希望自动化部署 YAML、但不想手工维护文件的用户 |
| **下载 YAML 手工修改并导入** | 自由度最高，所有 Provider、策略组和规则均可自行调整 | 最复杂、最繁琐，更新时需要自行合并改动 | 熟悉 Mihomo YAML 的进阶用户 |

详细入口：

- 订阅转换模板：[`../cfg/README.md`](../cfg/README.md)
- YAML 配置说明：[`../cfg/yaml/README.md`](../cfg/yaml/README.md)
- 远程 YAML 模块：[`yaml/README.md`](./yaml/README.md)

> [!WARNING]
> 上述三种方式是同一配置目标的不同实现路径，通常应当三选一，不要同时让多种路径争夺或反复替换当前配置。
>
> 根目录中的功能覆写模块属于可选增强项，不算第四种配置路径。

> [!NOTE]
> 本项目提供的模板、YAML 和远程 YAML 模块，均基于维护者对典型使用场景的合理推定。它们无法保证完全贴合每位用户的网络、节点和业务需求。需要高度个性化时，应自行修改或编写 YAML。

## 🚀 当前可用资源

| 使用需求 | 推荐资源 | 影响范围 |
| --- | --- | --- |
| 通过远程模块部署本项目 YAML | [`yaml/`](./yaml/) | 下载配置、写入订阅、切换当前配置并重启 |
| 综合降低 DNS 泄漏风险 | [`Prevent_DNS_Leak.conf`](./Prevent_DNS_Leak.conf) | DNS、规则、策略组及 OpenClash 运行参数 |
| 阻止终端使用常见 DoH、DoT、DoQ 绕过本地 DNS | [`Block_Encrypted_DNS.conf`](./Block_Encrypted_DNS.conf) | Rule Provider 与前置阻断规则 |
| 为 IP 类规则自动添加 `no-resolve` | [`Add_No_Resolve.conf`](./Add_No_Resolve.conf) | 顶层规则与子规则 |
| 让 Steam CDN 与游戏平台下载流量直连 | [`Direct_Game_Download.conf`](./Direct_Game_Download.conf) | Rule Provider 与前置直连规则 |
| 替换 GeoIP MMDB、GeoIP DAT 数据源 | [`Set_GeoIP_Database_URL.conf`](./Set_GeoIP_Database_URL.conf) | OpenClash GEO 数据库地址 |
| 替换大陆 IPv4、IPv6 白名单数据源 | [`Set_China_IP_Route_URL.conf`](./Set_China_IP_Route_URL.conf) | OpenClash Chnroute 数据源 |
| 使用第三方完整覆写方案 | [`OpenClash_Overwrite/`](./OpenClash_Overwrite/) | 策略组、规则、DNS、节点选择等多项配置 |
| 查看停止维护的旧版文件 | [`archived/`](./archived/) | 仅供历史参考 |

## 🌐 远程 YAML 配置模块

[`yaml/`](./yaml/) 中的模块会：

1. 从本仓库下载指定的 OpenClash 最小 YAML；
2. 保存到 `/etc/openclash/config/`；
3. 通过模块变量向 YAML 写入节点订阅地址；
4. 将下载的 YAML 设为目标配置；
5. 触发 OpenClash 重新加载。

目前包括：

- 8 个与常规 YAML 一一对应的独立模块；
- 1 个可通过参数选择版本的 `8 合 1` 模块；
- 1 个“自建节点 Provider 优先 + 机场故障转移”模块。

普通模块使用：

```text
EN_KEY1=节点订阅链接
```

8 合 1模块使用：

```text
EN_KEY1=节点订阅链接;EN_KEY2=配置名称
```

自建节点 Provider 模块使用：

```text
EN_KEY1=机场订阅链接;EN_KEY2=自建节点订阅链接
```

完整文件清单、配置名称、参数格式、GitHub Raw 与 testingcf 订阅地址，请阅读：

> **[`overwrite/yaml/README.md`](./yaml/README.md)**

对应 YAML 的策略组、规则和版本区别，请阅读：

> **[`cfg/yaml/README.md`](../cfg/yaml/README.md)**

> [!CAUTION]
> 远程 YAML 模块会下载并覆盖 `/etc/openclash/config/` 中的同名配置文件。若你曾手工修改同名 YAML，启用模块前必须备份，否则本地修改可能被覆盖。

## 🪶 功能覆写模块

根目录中的功能模块用于修改已经加载的配置或 OpenClash 数据源。它们可以配合订阅转换、远程 YAML 或手工 YAML 使用，但应检查修改范围和执行结果。

### 模块关系速览

| 组合 | 建议 |
| --- | --- |
| `Prevent_DNS_Leak.conf` + `Block_Encrypted_DNS.conf` | ✅ 可组合。前者处理 OpenClash 内部 DNS 路由与兜底，后者阻断终端常见加密 DNS |
| `Prevent_DNS_Leak.conf` + `Add_No_Resolve.conf` | ⚠️ 不需要。前者已包含后者的核心处理逻辑 |
| `Add_No_Resolve.conf` + `Direct_Game_Download.conf` | ✅ 通常可以，游戏下载模块的 IP 规则已经带有 `no-resolve` |
| 数据源替换模块 + 规则模块 | ✅ 通常可以，修改范围不同 |
| 远程 YAML 模块 + 功能模块 | ⚠️ 可以尝试，但必须确认执行顺序、字段覆盖和最终运行配置 |
| 第三方完整覆写方案 + 其他模块 | ⚠️ 必须逐项检查，完整方案可能修改相同的 DNS、规则、策略组或数据源 |
| 多个完整配置生成方案 | ❌ 不建议同时启用 |

### 🛡️ 综合 DNS 防泄漏

[`Prevent_DNS_Leak.conf`](./Prevent_DNS_Leak.conf) 会联动处理 DNS 劫持、`dns.respect-rules`、IP 类规则 `no-resolve`、最终代理兜底及相关 OpenClash 参数。

主要用途：

- 降低客户端及路由器自身 DNS 请求绕过代理规则的风险；
- 为 IP 类规则与 `behavior: ipcidr` Rule Provider 补充 `no-resolve`；
- 将最终 `MATCH` 或 `FINAL` 指向代理目标；
- 未指定代理目标时创建 `COCR-DNS-Leak-Guard` 策略组。

可选参数：

| 参数 | 用途 |
| --- | --- |
| `EN_KEY1` | 指定最终规则使用的代理组或代理节点 |
| `EN_KEY2` | 指定 `proxy-server-nameserver`，多个地址使用英文分号分隔 |

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Prevent_DNS_Leak.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Prevent_DNS_Leak.conf
```

> [!WARNING]
> 该模块影响范围较大。启用后必须检查最终规则、DNS 配置、专用策略组及 OpenClash 日志。

### 🚫 阻断加密 DNS

[`Block_Encrypted_DNS.conf`](./Block_Encrypted_DNS.conf) 会：

- 阻断 TCP/UDP 目标端口 `853`；
- 添加加密 DNS 域名与 IP Rule Provider；
- 将阻断规则插入规则列表顶部。

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Block_Encrypted_DNS.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Block_Encrypted_DNS.conf
```

该模块无法识别所有非标准端口、共享 CDN 或经隧道传输的加密 DNS，也不能替代 DNS 劫持、IPv6 DNS 管理和 OpenWrt 防火墙策略。

### 🧭 自动添加 `no-resolve`

[`Add_No_Resolve.conf`](./Add_No_Resolve.conf) 用于处理：

- `IP-CIDR`
- `IP-CIDR6`
- `GEOIP`
- 引用 `behavior: ipcidr` Rule Provider 的 `RULE-SET`
- 顶层 `rules`
- `sub-rules`

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Add_No_Resolve.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Add_No_Resolve.conf
```

> [!NOTE]
> `Prevent_DNS_Leak.conf` 已包含该模块的核心功能，启用前者时不需要再启用本模块。

### 🎮 游戏下载直连

[`Direct_Game_Download.conf`](./Direct_Game_Download.conf) 会将：

- 本项目维护的 Steam CDN 域名规则设为直连；
- Steam CDN IP 规则设为 `DIRECT,no-resolve`；
- `GEOSITE,category-game-platforms-download` 设为直连。

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Direct_Game_Download.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Direct_Game_Download.conf
```

该模块只处理游戏下载和更新流量，不会将游戏平台登录、商店、社区、云存档或联机流量全部改为直连。

### 🌍 替换 GeoIP 数据库地址

[`Set_GeoIP_Database_URL.conf`](./Set_GeoIP_Database_URL.conf) 用于替换 OpenClash 的：

- `Country.mmdb`
- `geoip.dat`

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Set_GeoIP_Database_URL.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Set_GeoIP_Database_URL.conf
```

该模块不会自动启用数据库模式、定时更新或修改 GeoSite、ASN、策略组和分流规则。

### 🇨🇳 替换大陆 IP 白名单数据源

[`Set_China_IP_Route_URL.conf`](./Set_China_IP_Route_URL.conf) 用于替换 OpenClash 大陆 IPv4 与 IPv6 Chnroute 数据源。

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/Set_China_IP_Route_URL.conf
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/Set_China_IP_Route_URL.conf
```

只有在 OpenClash 已启用相关大陆 IP 白名单功能时，替换后的数据源才会被实际使用。

## 🧰 第三方完整覆写方案

[`OpenClash_Overwrite/`](./OpenClash_Overwrite/) 是 [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite) 的 Git 子模块镜像入口。

它可能同时生成或调整：

- 策略组
- 分流规则
- DNS
- Rule Provider
- 节点选择
- 订阅及环境参数
- 其他 Mihomo 配置项

具体文件、变量、兼容版本和使用方法，以上游 README 为准。

> [!WARNING]
> 完整覆写方案影响范围较大，不建议与其他完整配置生成方案同时使用。与本项目功能模块组合时，也必须确认没有重复修改相同字段。

## ⚙️ 通用使用方法

1. 先按照 Wiki 完成 OpenClash LuCI 设置；
2. 进入 OpenClash 的 **覆写设置** 或 **覆写模块** 页面；
3. 新增远程覆写模块；
4. 模块类型选择 `HTTP`；
5. 填写模块名称和订阅地址；
6. 按模块说明填写 `EN_KEY` 参数；
7. 启用模块并保存；
8. 应用配置并重启 OpenClash；
9. 检查最终运行配置和日志。

不同 OpenClash 版本的菜单名称可能略有差异。

> [!TIP]
> 排查模块问题时，可暂时停用其他覆写，只保留目标模块，重新应用配置后确认它能否独立生效。

## ✅ 最终验收

不论使用哪种配置路径或功能模块，建议至少确认：

- Mihomo 内核启动成功；
- 当前配置文件符合预期；
- 节点与 Proxy Provider 更新成功；
- 策略组不为空且节点归类正确；
- Rule Provider 下载和解析成功；
- DNS 解析、Fake-IP 或 Redir-Host 行为符合 LuCI 设置；
- IPv4、IPv6 和路由器自身流量按预期接管；
- 常用国内外服务命中正确策略；
- OpenClash 日志不存在下载、Ruby、YAML 校验或内核启动错误。

## ❓ 常见问题

### 功能覆写模块会修改远程订阅源吗？

不会。模块只会影响 OpenClash 加载后的配置、最终运行配置或插件使用的数据源。

### `yaml/` 模块会修改什么？

它会下载远程 YAML、写入订阅地址、选择目标配置并触发重新加载。它可能覆盖 `/etc/openclash/config/` 中的同名 YAML 文件。

### 多个模块可以同时启用吗？

多数单功能模块可以组合，但必须检查修改范围。多个模块同时修改同一字段、数组、策略组或最终规则时，后执行的结果可能覆盖前面的结果。

### 模块没有生效怎么办？

依次检查：

1. 模块是否启用；
2. 模块地址是否可以下载；
3. `EN_KEY` 参数格式是否正确；
4. 是否已经保存、应用配置并重启；
5. OpenClash 是否支持模块使用的指令；
6. 是否存在其他模块覆盖相同字段；
7. OpenClash 日志是否存在下载、解析、Ruby 或配置校验错误；
8. 最终运行配置是否出现预期内容。

### testingcf 地址无法访问怎么办？

可临时改用对应的 GitHub Raw 地址。GitHub Raw 在部分网络环境中的可用性也可能不稳定，应优先排查网络和 DNS，而不是长期依赖来源不明的转发服务。

## 📦 已归档资源

[`archived/`](./archived/) 保存已经停止维护的旧版覆写文件，仅供历史参考，不建议继续部署。

## 📚 相关文档

- [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)
- [订阅转换模板说明](../cfg/README.md)
- [YAML 配置说明](../cfg/yaml/README.md)
- [远程 YAML 模块说明](./yaml/README.md)
- [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

---

<div align="center">

覆写模块会持续调整，请以仓库 `main` 分支中的最新文件和说明为准。

</div>
