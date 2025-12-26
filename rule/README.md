<h1 align="center">
  🛡️ Custom Rules
</h1>

<p align="center"><b>🎯 个人维护的轻量级规则碎片 🎯</b></p>

这里存放自用的 OpenClash / Clash 规则集合。所有规则均为**文本格式 (.list)**，文件内包含详细的注释说明。
这些规则旨在作为大型规则集（如 ACL4SSR）的补充，按需调用，**不影响**整体性能。

---

## 📜 规则列表

| 规则文件 | 类型 | 功能说明 |
| :--- | :---: | :--- |
| [**Custom_Direct.list**](Custom_Direct.list) | <img src="https://img.shields.io/badge/Mode-DIRECT-green?style=flat-square"> | 🎯 **直连规则**：包含一些需要直连的冷门域名。 |
| [**Custom_Proxy.list**](Custom_Proxy.list) | <img src="https://img.shields.io/badge/Mode-PROXY-blue?style=flat-square"> | 🚀 **代理规则**：包含一些需要代理的冷门域名。 |
| [**Steam_CDN.list**](Steam_CDN.list) | <img src="https://img.shields.io/badge/Mode-DIRECT-green?style=flat-square"> | 🎮 **Steam CDN**：精确匹配 Steam 下载服务器，确保 Steam 下载流量不走代理。 |

---

## 🧩 文件格式说明

本仓库提供多种格式的变体，以适配不同客户端的需求：

| 后缀 / 扩展名 | 格式类型 | 适用场景 |
| :--- | :--- | :--- |
| **`.list`** | 原始文本列表 | 适用于 `Subconverter` 引用。 |
| **`_Classical.yaml`** | Classical | 域名/IP 混合规则，适用于 `rule-providers`。 |
| **`_Classical_IP.yaml`** | Classical (Pure IP) | Classical 类型纯 IP 规则，适用于 `rule-providers`。 |
| **`_Domain.yaml`** | Domain | Domain 类型纯域名规则。 |
| **`_IP.yaml`** | IP-CIDR | IP-CIDR 类型纯 IP 规则。 |
| **`.mrs`** | Mihomo Binary | 二进制格式纯域名规则，Mihomo (Meta) 专用。 |

---

## 📂 归档文件

> [!NOTE]
> `archived/` 文件夹包含已弃用的历史规则文件（如旧版去广告规则等）。
> 详情请查阅 [📜 Archived README](archived/README.md)
