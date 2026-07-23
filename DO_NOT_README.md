<h1 align="center">
  🚀 Custom_OpenClash_Rules
</h1>

<p align="center"><b>OpenClash 配置、规则碎片、实用脚本与覆写资源</b></p>

<p align="center">
  <a href="README.md">English</a>
  &nbsp;|&nbsp;
  <b>简体中文</b>
</p>

<p align="center">
  <a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki">📖 项目 Wiki</a>
  &nbsp;•&nbsp;
  <a href="cfg/">🧩 配置资源</a>
  &nbsp;•&nbsp;
  <a href="rule/">🗂️ 规则碎片</a>
</p>

<p align="center">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="GitHub contributors" src="https://img.shields.io/github/contributors-anon/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/t/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="OpenClash" src="https://img.shields.io/badge/OpenClash-resources-brightgreen?style=flat">
  <img alt="Website" src="https://img.shields.io/website?url=https%3A%2F%2Fapi.asailor.org%2Fversion&up_message=online&down_message=offline&style=flat&label=backend">
</p>

<p align="center"><b>✨ 让你更优雅地使用 OpenClash ✨</b></p>

---

## 📖 关于本项目

**Custom_OpenClash_Rules** 是一个围绕 [OpenClash](https://github.com/vernesong/OpenClash) 整理和维护的资源仓库。

本项目提供 OpenClash 配置方案、订阅转换模板、YAML 配置示例、规则碎片、实用脚本、覆写资源及相关文档，帮助用户更方便地部署、维护和调整 OpenClash。

根 README 仅作为项目首页和资源导航。各目录中的具体文件、用途、区别及使用方法，请查看对应目录内的 README 或项目 Wiki。

> [!NOTE]
> 项目 Wiki 目前仅提供中文版本。

---

## 🚀 快速开始

| 需求 | 建议入口 |
| --- | --- |
| 首次配置或系统了解 OpenClash | [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) |
| 使用订阅转换模板或 YAML 配置示例 | [`cfg/`](cfg/) |
| 为现有配置补充规则 | [`rule/`](rule/) |
| 使用 OpenClash 相关脚本 | [`shell/`](shell/) |
| 使用远程覆写资源 | [`overwrite/`](overwrite/) |
| 排查常见故障 | [故障排除](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4) |

---

## 🧭 项目资源

### 📚 配置方案与文档

项目 Wiki 是本仓库最核心的内容之一，提供一套围绕 OpenWrt 与 OpenClash 整理的完整配置思路。它并非简单罗列参数，而是结合实际使用场景说明各项设置之间的关系、配置目的及可能产生的影响，帮助用户在理解基本原理的基础上完成部署和维护。

方案以 OpenClash 的实际使用流程为主线，重点覆盖：

- **OpenClash 基础配置与透明分流**：围绕 `Fake-IP` 模式、流量接管、规则匹配和策略选择，建立完整的 OpenClash 使用框架。
- **DNS 策略与泄漏风险控制**：说明直连与非直连流量的解析路径，尽量减少不必要的 DNS 绕行、解析异常及泄漏风险。
- **直连访问优化**：结合 OpenClash 的“绕过中国大陆”等功能，使适合直连的域名与 IP 尽量保持本地解析和直接访问，降低 OpenClash 对直连流量的额外影响。
- **IPv6 配置与兼容**：提供 OpenWrt 与 OpenClash 的 IPv6 配置思路，帮助用户在保留 IPv6 连通性的同时正确进行分流。
- **故障排除与补充教程**：整理 OpenClash 无法启动、网络异常、分流不符合预期、部分网站无法访问等常见问题，并提供相关补充说明。

整套方案力求主要依靠 OpenClash 自身功能完成配置，避免引入不必要的多层 DNS 插件组合。大部分操作均可通过 OpenClash 的 LuCI 管理界面完成，既可作为初次配置的操作指南，也可作为后续排查和优化配置的参考资料。

> [!TIP]
> 建议首次使用本项目时先完整阅读 Wiki，再选择下方的配置资源。Wiki 负责说明“为什么这样配置”，配置资源负责提供可复用的落地示例。

**入口：** [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

### 🧩 配置资源

`cfg/` 是本项目另一项核心内容，用于将 Wiki 中的配置思路转化为可直接参考和复用的配置资源。目录内提供订阅转换模板、YAML 配置示例及配套说明，适合希望快速生成 OpenClash 配置，或需要在现有配置基础上进行调整的用户。

> [!TIP]
> 本项目订阅转换模板的远程链接已收录于 OpenClash 内置的模板列表，可直接选择，无需手动填写。

这些配置资源主要关注以下方面：

- **订阅转换与配置生成**：通过订阅转换模板，将节点订阅整理为适用于 OpenClash 的配置结构，减少手工编写和维护配置的工作量。
- **不同复杂度的策略设计**：提供定位不同的配置方案，在策略组丰富程度、使用复杂度和维护成本之间进行取舍，便于用户按实际需求选择。
- **常用服务与应用分流**：围绕常见网络服务、应用和平台组织策略组及规则，并保留进一步扩展和自定义的空间。
- **与 Wiki 配置思路保持一致**：配置资源围绕 `Fake-IP`、DNS 策略、直连访问和规则分流进行设计，适合与本项目 Wiki 配合使用。
- **规则及数据更新能力**：通过引用上游规则和 GEO 数据，降低手工维护大量时效性规则的成本；部分配置同时针对下载流量、游戏平台等场景提供差异化处理思路。
- **YAML 配置参考**：提供完整配置结构示例，便于理解 OpenClash 配置文件的组成，也可作为自行修改和构建配置的基础。

根 README 不逐一列出目录中的具体模板和配置文件。各配置方案的定位、区别、使用地址及注意事项，请以 `cfg/` 目录中的 README 为准。

**入口：** [`cfg/`](cfg/)

### 🗂️ 规则碎片

提供可按需加入现有配置的规则碎片。普通规则与游戏规则统一视为规则碎片资源，具体分类和使用方式以目录说明为准。

**入口：** [`rule/`](rule/)

### 🛠️ 实用脚本

提供 OpenClash 安装、更新、检测及维护相关脚本。

**入口：** [`shell/`](shell/)

### ⚙️ 覆写资源

提供 OpenClash 远程覆写相关资源和说明。本目录引用外部维护项目，具体内容与使用方式请以目录说明及上游项目为准。

**入口：** [`overwrite/`](overwrite/)

---

## 🎯 项目范围

本仓库主要面向 OpenWrt 与 OpenClash 使用场景，不提供其他客户端或操作系统的通用配置支持。

本项目为维护者个人使用经验与技术资料的整理，不提供个性化配置、定制开发或一对一技术支持。

---

## 🈸 提交直连域名

需要补充少量直连域名时，建议优先使用 OpenClash 的自定义规则功能。

如希望将符合要求的域名纳入本项目，可通过 GitHub Issues、Pull Requests，或访问 [COCR RULE BOT](https://telegram.me/asailor_rulebot) 提交。

> [!NOTE]
> 维护者会根据实际情况，将收集到的适合内容向相关上游规则项目提交。

---

## ⚠️ 特别声明

> [!WARNING]
> **使用须知：**
>
> 1. 本项目仅用于 OpenWrt 系统及其插件 OpenClash 的技术学习与研究，相关内容属于中立性的技术实现示例与实验性资料，不涉及任何具体使用场景或用途导向。
> 2. 使用者在访问、使用、复制本项目内容前，应自行确认其所在地及相关司法辖区的法律法规允许，且在学习和研究后于 24 小时内删除相关内容。
> 3. 本项目内容不得用于任何违反适用法律法规的用途。使用者在使用本项目内容时，应自行遵守其所在地及相关司法辖区的法律法规，包括中华人民共和国的相关法律法规，不得在中华人民共和国境内利用本项目内容从事获取、传播依法被限制或阻断的境外违法信息等行为。
> 4. 本项目不提供、亦不涉及设备、软件、工具、线路或服务。项目维护者不制作、不销售、不提供相关设备、软件、工具或技术服务，亦不为任何个人或组织获取、传播依法被限制或阻断的信息、规避监管制度提供技术支持、协助或其他形式的帮助。
> 5. 任何个人或组织因直接或间接使用本项目内容所实施的行为，均由其自行负责并承担相应法律责任。项目维护者不参与使用者的具体行为，对使用者的用途、方式及其产生的后果不承担任何责任，亦不承担任何形式的连带责任。
> 6. 基于本项目内容所进行的修改、二次开发、整合、分发或其他衍生行为，均属于相关个人或组织的独立行为，与本项目及其维护者无关，由此产生的任何法律责任由行为主体自行承担。
> 7. 本项目不鼓励任何形式的转载、再发布或二次传播，且严禁转载、再发布或二次传播本项目内容至中国大陆境内任何平台之上。
> 8. 任何转载、再发布或二次传播均不得暗示本项目或维护者对转载内容背书。因转载、传播或使用本项目内容所产生的法律风险，由行为主体自行承担，与本项目及其维护者无关。
> 9. 本项目维护者保留在任何时间对本免责声明进行修订或补充的权利。任何使用、复制或访问本项目内容的个人或组织，均视为已知悉并接受本免责声明。

> [!NOTE]
> - 本项目编写于 2024 年 4 月，为非盈利性质的技术研究与经验整理项目。
> - 本项目内容仅为维护者个人经验的总结，用于技术交流，不具权威性，亦不构成 OpenClash 的唯一或推荐使用方式。
> - 本项目未运营任何 YouTube 频道，亦未在 YouTube 或其他视频平台发布任何形式的教学或指导视频。
> - 本项目内容未基于其他第三方教程或视频进行整理或改编。如因使用其他来源的教程、模板或配置文件产生问题，请勿在本项目的 Issues 或 Discussions 中反馈。
> - 内容采用相对易于理解的表述，不代表对任何用户群体作出教学、指导或支持承诺。

---

## 🤝 贡献者

<a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Aethersailor/Custom_OpenClash_Rules&anon=1&max=100" alt="贡献者列表" />
</a>

---

## 🙏 感谢

本项目使用或参考了以下项目和资源，排名不分先后：

- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [vernesong/mihomo](https://github.com/vernesong/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)
- [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [v2fly/domain-list-community](https://github.com/v2fly/domain-list-community)
- [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)
- [Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat)
- [dogfight360/UsbEAm](https://www.dogfight360.com/blog/18627/)
- [ddgksf2013/ddgksf2013](https://github.com/ddgksf2013/ddgksf2013)
- [mottzz87/crules](https://github.com/mottzz87/crules)
- [217heidai/adblockfilters](https://github.com/217heidai/adblockfilters)
- [privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD)
- [TG-Twilight/AWAvenue-Ads-Rule](https://github.com/TG-Twilight/AWAvenue-Ads-Rule)
- [hagezi/dns-blocklists](https://github.com/hagezi/dns-blocklists)
- [Aethersailor/adblockfilters-modified](https://github.com/Aethersailor/adblockfilters-modified)
- [521xueweihan/GitHub520](https://github.com/521xueweihan/GitHub520)
- [Aethersailor/SubConverter-Extended](https://github.com/Aethersailor/SubConverter-Extended)
- [Aethersailor/subconverter](https://github.com/Aethersailor/subconverter)
- [Aethersailor/Rule-Bot](https://github.com/Aethersailor/Rule-Bot)
- [oooldtoy/SSTAP_ip_crawl_tool](https://github.com/oooldtoy/SSTAP_ip_crawl_tool)
- [immortalwrt/user-FAQ](https://github.com/immortalwrt/user-FAQ/)

---

## 📝 许可

[![CC-BY-SA-4.0 许可证](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.zh)

### CC-BY-SA-4.0

---

## ⭐ Star History

<a href="https://www.star-history.com/?type=date&repos=Aethersailor%2FCustom_OpenClash_Rules">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&theme=dark&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
    <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
  </picture>
</a>

## 📊 数据统计

![仓库活动统计](https://repobeats.axiom.co/api/embed/0d7d55da94670a4766aa0fb8ccd03c7abc9e8464.svg "Repobeats analytics image")
