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
| [**Custom_Direct.list**](Custom_Direct.list) | <img src="https://img.shields.io/badge/Mode-DIRECT-green?style=flat-square"> | 🎯 **强制直连**：包含一些容易被误杀或需要低延迟访问的域名。 |
| [**Custom_Proxy.list**](Custom_Proxy.list) | <img src="https://img.shields.io/badge/Mode-PROXY-blue?style=flat-square"> | 🚀 **强制代理**：包含一些被墙或直连体验不佳的冷门域名。 |
| [**Steam_CDN.list**](Steam_CDN.list) | <img src="https://img.shields.io/badge/Mode-DIRECT-green?style=flat-square"> | 🎮 **Steam CDN**：精确匹配 Steam 下载服务器，确保满速下载 (配合 STUN)。 |

---

## 📂 归档文件

> [!NOTE]
> `archived/` 文件夹包含已弃用的历史规则文件（如旧版去广告规则等）。
> 详情请查阅 [📜 Archived README](archived/README.md)
