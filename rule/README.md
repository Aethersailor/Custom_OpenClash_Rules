<h1 align="center">
  🎯 个人维护的轻量级规则碎片 🎯
</h1>

这里存放本项目使用的 OpenClash / Clash 规则集合。

---

## 📜 规则列表

| 规则文件 | 类型 | 功能说明 |
| :--- | :---: | :--- |
| [**Custom_Direct.list**](Custom_Direct.list) | <img src="https://img.shields.io/badge/Mode-DIRECT-green?style=flat-square" alt="DIRECT"> | 🎯 **直连规则**：包含一些需要直连的冷门域名。 |
| [**Custom_Proxy.list**](Custom_Proxy.list) | <img src="https://img.shields.io/badge/Mode-PROXY-blue?style=flat-square" alt="PROXY"> | 🚀 **非直连规则**：包含一些需要经由出站策略处理的冷门域名。 |
| [**Steam_CDN.list**](Steam_CDN.list) | <img src="https://img.shields.io/badge/Mode-DIRECT-green?style=flat-square" alt="DIRECT"> | 🎮 **Steam CDN**：精确匹配 Steam 下载服务器，确保 Steam 下载流量尽量不经由出站策略。 |
| [**Encrypted_DNS.list**](Encrypted_DNS.list) | <img src="https://img.shields.io/badge/Mode-REJECT-red?style=flat-square" alt="REJECT"> | 🛡️ **加密 DNS**：汇总 HaGeZi、DNSCrypt 与 `geosite:category-doh` 的域名和 IP，用于拦截绕过本地 DNS 的连接。 |

---

## 🧩 文件格式说明

`Custom_Direct.list`、`Custom_Proxy.list`、`Steam_CDN.list` 和 `Encrypted_DNS.list` 是派生规则的源文件。仓库会根据其中的规则类型自动生成以下变体：

| 后缀 / 扩展名 | 格式类型 | 适用场景 |
| :--- | :--- | :--- |
| **`.list`** | 原始规则列表 | 适用于 `Subconverter` 引用。 |
| **`_Classical.yaml`** | Classical | 域名/IP 混合规则，适用于 `rule-providers`。 |
| **`_Classical_IP.yaml`** | Classical (IP / Port) | Classical 类型 IP 与端口规则，适用于 `rule-providers`。 |
| **`_Classical_Port.yaml`** | Classical (Pure Port) | Classical 类型纯端口规则，适用于 `rule-providers`；目前仅为 `Custom_Direct` 生成。 |
| **`_Domain.yaml`** | Domain | Domain 类型纯域名规则，适用于 `rule-providers`。 |
| **`_IP.yaml`** | IP-CIDR | IP-CIDR 类型纯 IP 规则，适用于 `rule-providers`。 |
| **`.mrs`** | Mihomo Binary | Domain 或 IP-CIDR 类型的 Mihomo 二进制规则，适用于 `rule-providers`。 |

> [!IMPORTANT]
> MRS 只适用于纯 `Domain` 或纯 `IP-CIDR` provider。Classical、端口及其他混合规则只生成 YAML，不转换为 MRS。当预留 provider 暂时没有规则时，YAML 使用 `payload: []`，并保留已有空 MRS 占位文件，以便日后加入规则时自动重建。

> [!TIP]
> **关于性能的补充说明**
>
> 1. **规则遍历性能**: `Domain` / `IP-CIDR` > `Classical`
>     * 内核对纯类型的 `Domain` (域名树) 和 `IP-CIDR` (Radix 树) 做了深度优化，查询效率远高于混合型的 `Classical`。
> 2. **加载速度**: `.mrs` > `.yaml` / `.list`
>     * `.mrs` 和 `.yaml` 的区别主要在于**启动/重载速度**。二进制格式 (.mrs) 省去了文本解析开销，能极大缩短加载时间。
>     * **注意**: 文件格式**不影响**规则遍历性能。一旦规则加载进内存，性能只取决于规则类型（第 1 点）。

---

## 📂 归档文件

> [!NOTE]
> `archived/` 文件夹包含已弃用的历史规则文件。
> 详情请查阅 [📜 Archived README](archived/README.md)
