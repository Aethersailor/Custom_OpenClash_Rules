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
| **`.list`** | 原始文本列表 | 适用于 OpenClash `策略组` 引用或作为基础源文件。 |
| **`_Classical.yaml`** | Classical Provider | 适用于 Clash Premium / Mihomo 的 `rule-providers`。 |
| **`_Domain.yaml`** | 仅域名规则 | 仅包含 `DOMAIN` 类规则，用于特定分流需求。 |
| **`_IP.yaml`** | 仅 IP 规则 | 仅包含 `IP-CIDR` 类规则，用于特定分流需求。 |
| **`.mrs`** | Mihomo 二进制 | 专为 Mihomo (Meta) 内核设计的编译格式，加载速度极快。 |

---

## 📂 归档文件

> [!NOTE]
> `archived/` 文件夹包含已弃用的历史规则文件（如旧版去广告规则等）。
> 详情请查阅 [📜 Archived README](archived/README.md)
