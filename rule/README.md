<h1 align="center">
  🎯 个人维护的轻量级规则碎片 🎯
</h1>

这里存放本项目使用的 OpenClash / Clash 规则集合。

---

## 📜 规则列表

| 规则文件 | 类型 | 功能说明 |
| :--- | :---: | :--- |
| [**Custom_Direct.list**](Custom_Direct.list) | <img src="https://img.shields.io/badge/Mode-DIRECT-green?style=flat-square"> | 🎯 **直连规则**：包含一些需要直连的冷门域名。 |
| [**Custom_Proxy.list**](Custom_Proxy.list) | <img src="https://img.shields.io/badge/Mode-PROXY-blue?style=flat-square"> | 🚀 **代理规则**：包含一些需要代理的冷门域名。 |
| [**Steam_CDN.list**](Steam_CDN.list) | <img src="https://img.shields.io/badge/Mode-DIRECT-green?style=flat-square"> | 🎮 **Steam CDN**：精确匹配 Steam 下载服务器，确保 Steam 下载流量不走代理。 |

---

## 🧩 文件格式说明

本仓库提供多种格式的变体：

| 后缀 / 扩展名 | 格式类型 | 适用场景 |
| :--- | :--- | :--- |
| **`.list`** | 原始规则列表 | 适用于 `Subconverter` 引用。 |
| **`_Classical.yaml`** | Classical | 域名/IP 混合规则，适用于 `rule-providers`。 |
| **`_Classical_IP.yaml`** | Classical (Pure IP) | Classical 类型纯 IP 规则，适用于 `rule-providers`。 |
| **`_Domain.yaml`** | Domain | Domain 类型纯域名规则，适用于 `rule-providers`。 |
| **`_IP.yaml`** | IP-CIDR | IP-CIDR 类型纯 IP 规则，适用于 `rule-providers`。 |
| **`.mrs`** | Mihomo Binary | 二进制格式纯域名规则，适用于 `rule-providers`。 |

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
