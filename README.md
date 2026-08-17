<h1 align="center">
  🚀 Custom_OpenClash_Rules
</h1>

<p align="center"><b>OpenClash 配置方案、订阅转换模板、YAML 配置、规则文件、实用脚本与覆写模块资源</b></p>

<p align="center">
  <a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki">📖 项目 Wiki</a>
  &nbsp;•&nbsp;
  <a href="cfg/">🧩 配置资源</a>
  &nbsp;•&nbsp;
  <a href="rule/">🗂️ 规则文件</a>
  &nbsp;•&nbsp;
  <a href="overwrite/">⚙️ 覆写模块</a>
  &nbsp;•&nbsp;
  <a href="shell/">🛠️ 实用脚本</a>
</p>

<p align="center">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="GitHub contributors" src="https://img.shields.io/github/contributors-anon/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/t/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="OpenClash" src="https://img.shields.io/badge/OpenClash-resources-brightgreen?style=flat">
  <img alt="Website" src="https://img.shields.io/website?url=https%3A%2F%2Fapi.asailor.org%2Fversion&up_message=online&down_message=offline&style=flat&label=backend">
</p>

---

## 📖 关于本项目

**Custom_OpenClash_Rules** 是一个围绕 [OpenClash](https://github.com/vernesong/OpenClash) 维护的配置与扩展资源仓库。

本项目提供 OpenClash 设置文档、订阅转换模板、YAML 配置、规则文件、远程覆写模块及辅助脚本。各类资源可以独立使用；完整配置方案需要结合项目 Wiki 中的 OpenClash LuCI 设置。

> [!TIP]
> **仅需 OpenClash，无需「套娃」**
>
> 本项目的所有配置方案均只需 OpenClash 一个插件，无需叠加其他代理或 DNS 插件，也无需进行任何「套娃」设置。

> [!IMPORTANT]
> **关于 DNS 泄漏防护**
>
> 使用本项目的 OpenClash 设置方案，并选择三种订阅路径中的任意一种（订阅转换、远程 YAML 覆写或手动导入 YAML），在以下条件同时满足时，可以避免本地 DNS 泄漏：
>
> - Fake-IP、流量接管和 DNS 设置均已按 Wiki 生效；
> - 终端 DNS 请求及相关流量均经过 OpenClash。
>
> 实际结果必须通过检测验证，不能仅以配置完成作为结论。客户端启用私有 DNS 或 DoH、设备或部分流量未被接管、插件或固件行为与文档不一致，或自行覆写 DNS 配置时，均超出该方案的控制范围，需要单独处理并验证。

根目录的 `README.md` 作为项目首页和资源导航，仅介绍各类资源的定位与入口。具体文件、版本区别、参数和使用方法，请进入对应目录查看其自动展示的 `README.md`。

> [!NOTE]
> 项目 Wiki 目前仅提供中文版本。

---

## 🚀 快速开始

| 需求 | 建议入口 |
| --- | --- |
| 首次配置 OpenClash 或系统了解其工作方式 | [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) |
| 使用订阅转换模板、YAML 配置或远程 YAML 覆写模块 | [`cfg/`](cfg/) |
| 为现有配置补充或修正规则 | [`rule/`](rule/) |
| 使用独立游戏规则 | [`rule/game_rule/`](rule/game_rule/) |
| 使用单功能远程覆写模块 | [`overwrite/`](overwrite/) |
| 安装、更新或检测 OpenClash | [`shell/`](shell/) |
| 使用 Sub-Store 扩展脚本 | [Sub-Store 脚本](script/sub-store/) |
| 排查常见故障 | [故障排除](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4) |

---

## 🧭 项目资源

### 📚 配置方案与文档

项目 Wiki 是本仓库的核心内容之一，提供一套围绕 OpenWrt 与 OpenClash 整理的完整配置思路。

内容重点包括：

- **OpenClash 从准备到验收的完整配置流程：** 运行模式、流量接管、规则匹配和策略选择；
- **DNS 策略与泄漏风险控制：** 直连与代理流量的解析路径、DNS 劫持和规则跟随；
- **直连访问优化：** 结合中国大陆域名与 IP 绕过机制，减少不必要的代理处理；
- **IPv6 配置与兼容：** 在保留 IPv6 连通性的同时正确完成分流与接管；
- **故障排除与补充教程：** 覆盖启动失败、网络异常、规则命中异常等常见问题。

Wiki 负责解释「为什么这样配置」，各资源目录负责提供可以直接使用或修改的落地文件。

**入口：** [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

---

### 🧩 配置资源

[`cfg/`](cfg/) 用于将上述 Wiki 中的配置思路落实为可直接使用的完整配置资源，具体包括：

| 资源 | 所在位置 | 主要用途 |
| --- | --- | --- |
| **订阅转换模板** | [`cfg/`](cfg/) | 通过在线订阅转换生成完整 OpenClash 配置 |
| **YAML 配置文件** | [`cfg/yaml/`](cfg/yaml/) | 下载后手动修改并导入 OpenClash |
| **YAML 远程覆写模块** | [`overwrite/yaml/`](overwrite/yaml/) | 自动下载对应 YAML、写入订阅并切换配置 |

> [!IMPORTANT]
> 本项目提供三种完整配置的使用方式：
>
> 1. **订阅转换**；
> 2. **远程 YAML 覆写模块**；
> 3. **下载 YAML 后手动修改并导入**。
>
> 本项目按同一套配置设计维护三种使用方式。选择相同版本且未自行修改时，策略组定位、规则顺序和分流逻辑应保持一致；文件结构和加载方式不同，实际结果还会受到订阅转换后端及 OpenClash 版本影响。

OpenClash `dev` 版当前已内置本项目全部 8 个订阅转换模板，包括标准版、轻量版、极简 GFW 版、重度分流版，以及文件名以 `_Fallback` 结尾的对应故障转移版。旧版如未显示对应条目，可手动填写远程模板地址，具体方法和地址见 [`cfg/`](cfg/)。

本项目提供标准版、轻量版、极简 GFW 版、重度分流版及对应的故障转移版，并提供自建节点相关 YAML。版本定位、参数、远程地址和详细操作请进入相应目录查看。

**入口：**

- 订阅转换模板：[`cfg/`](cfg/)
- YAML 配置文件：[`cfg/yaml/`](cfg/yaml/)
- YAML 远程覆写模块：[`overwrite/yaml/`](overwrite/yaml/)

---

### 🗂️ 规则文件

[`rule/`](rule/) 存放本项目维护的补充规则及其多格式派生文件，包括自定义直连、代理、Steam CDN、游戏下载 CDN、加密 DNS 等内容。

目录中的 `.list` 是主要规则来源；工作流据此生成 Classical YAML、Domain YAML、IP-CIDR YAML 和 MRS，供订阅转换模板或 Mihomo Rule Provider 使用。

直连规则由项目用户共同参与维护。如需提交符合收录条件的域名，可使用 GitHub Issue、Pull Request 或 [RULE BOT](https://telegram.me/asailor_rulebot)。

[`rule/game_rule/`](rule/game_rule/) 另存放人工整理的独立游戏规则。目录中的 `.list` 是规则来源，工作流会自动生成 YAML 和 MRS 派生文件，但不会更新规则内容或将其加载到主配置。使用前应核对适用区服、更新时间和实际命中情况。

**入口：** [`rule/`](rule/)

> [!NOTE]
> 维护者会根据实际情况将本项目收集到的规则内容向上游相关规则项目提交。

---

### 🛠️ 实用脚本

[`shell/`](shell/) 提供 OpenClash 安装、更新和 CPU 架构检测脚本，支持 OpenWrt、ImmortalWrt，并适配 OPKG 和 APK 包管理器。

脚本可能涉及软件源临时切换、插件覆盖重装、UCI 设置和 OpenClash 内置更新流程。运行前请进入目录阅读完整说明。

[Sub-Store 扩展脚本](script/sub-store/) 用于扩展 Sub-Store 的订阅处理能力。相关脚本独立于 OpenClash 安装流程，也不会被本项目配置自动加载。

**入口：**

- OpenClash 安装与维护脚本：[`shell/`](shell/)
- Sub-Store 扩展脚本：[查看目录](script/sub-store/)

---

### ⚙️ 覆写模块资源

[`overwrite/`](overwrite/) 存放 OpenClash 远程覆写模块及相关资源。

根目录中主要存放单功能的远程覆写模块；[`overwrite/yaml/`](overwrite/yaml/) 则存放调用本项目 YAML 配置的远程覆写模块。

不同模块的修改范围、参数、组合关系和冲突风险，请进入对应目录查看。未来会不断追加其他功能的覆写模块。

**入口：**

- 单功能覆写模块：[`overwrite/`](overwrite/)
- YAML 配置远程覆写模块：[`overwrite/yaml/`](overwrite/yaml/)

---

## 🎯 项目范围

本仓库主要面向 OpenWrt 与 OpenClash 使用场景，不提供其他客户端或操作系统的通用配置支持。

本项目为维护者个人使用经验与技术资料的整理，不提供个性化配置、定制开发或一对一技术支持。

---

## 💬 讨论与反馈

### 本项目讨论群组

欢迎加入本项目的 Telegram 讨论群组：[Custom OpenClash Rules](https://t.me/custom_openclash_rules_group)

群组欢迎一切与本项目相关的讨论，包括配置使用、规则反馈、问题排查，也欢迎其他交流。

> [!IMPORTANT]
> 如排查后确认问题由 OpenClash 插件本身引起、与本项目配置或规则无关（如插件无法启动、界面异常、安装失败等），建议：
>
> - 前往 [OpenClash 仓库](https://github.com/vernesong/OpenClash) 提交 Issue；
> - 或加入 OpenClash 官方 Telegram 讨论群组咨询（可在插件 LuCI 首页点击 Telegram 图标进入）。

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

<!-- -->

> [!NOTE]
>
> - 本项目编写于 2024 年 4 月，为非营利性质的技术研究与经验整理项目。
> - 本项目内容仅为维护者个人经验的总结，用于技术交流，不具权威性，亦不构成 OpenClash 的唯一或推荐使用方式。
> - 本项目未运营任何 YouTube 频道，亦未在 YouTube 或其他视频平台发布任何形式的教学或指导视频。
> - 本项目文档由维护者根据实际使用经验独立整理；引用或使用的第三方项目、资料与资源在对应位置或下方「感谢」中标注。如因使用其他来源的教程、模板或配置文件产生问题，请勿在本项目的 Issues 或 Discussions 中反馈。
> - 内容采用相对易于理解的表述，不代表对任何用户群体作出教学、指导或支持承诺。

---

## 🤝 贡献者

<a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Aethersailor/Custom_OpenClash_Rules&anon=1&max=100" alt="贡献者列表" />
</a>

---

## 🙏 感谢

感谢以下项目和资源对本项目提供基础能力、数据、工具或参考。为准确说明关系，以下内容按实际用途分类，各分类内排名不分先后；列入本节不表示相关项目对本项目提供官方支持或背书。

### 核心上游与现行数据源

| 项目或资源 | 本项目中的用途 |
| --- | --- |
| [vernesong/OpenClash](https://github.com/vernesong/OpenClash) | 本项目配置、覆写脚本和使用文档所面向的 OpenWrt 插件 |
| [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) | 规则格式、配置能力以及 MRS 生成与校验工具 |
| [vernesong/mihomo](https://github.com/vernesong/mihomo) | 安装脚本与第三方覆写方案使用的 LightGBM 模型资源 |
| [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) | 本项目订阅转换配置的基础模板 |
| [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite) | 以 Git 子模块保留的第三方完整覆写方案 |
| [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) | 中国大陆 IPTV 域名规则的数据来源 |
| [v2fly/domain-list-community](https://github.com/v2fly/domain-list-community) | 游戏下载域名与加密 DNS GeoSite 规则的数据来源 |
| [HaGeZi DNS Blocklists](https://gitlab.com/hagezi/mirror/-/tree/main/dns-blocklists) | 加密 DNS 域名与 IP 规则的数据来源 |
| [DNSCrypt/dnscrypt-resolvers](https://github.com/DNSCrypt/dnscrypt-resolvers) | 加密 DNS 公共解析器、Relay 与 ODoH 端点的数据来源 |
| [dogfight360/UsbEAm](https://www.dogfight360.com/blog/18627/) | 游戏网络地址与下载节点规则的参考工具 |

### 本项目关联项目

| 项目 | 与本项目的关系 |
| --- | --- |
| [Aethersailor/SubConverter-Extended](https://github.com/Aethersailor/SubConverter-Extended) | 本项目维护的增强型订阅转换后端 |
| [Aethersailor/subconverter](https://github.com/Aethersailor/subconverter) | 本项目维护的传统订阅转换后端 |
| [Aethersailor/Rule-Bot](https://github.com/Aethersailor/Rule-Bot) | 自定义规则提交工具 |
| [Aethersailor/geoip](https://github.com/Aethersailor/geoip) | GeoIP 数据库与中国大陆 IPv4、IPv6 网段来源 |

<details>
<summary><strong>其他规则、工具与历史参考来源</strong></summary>

| 项目或资源 | 本项目中的用途 |
| --- | --- |
| [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list) | 补充直连域名的上游提交目标 |
| [Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat) | 完整配置模板中的 GeoIP、GeoSite 数据来源 |
| [mottzz87/crules](https://github.com/mottzz87/crules) | Talkatone 规则的原始来源；相关规则已停止更新 |
| [oooldtoy/SSTAP_ip_crawl_tool](https://github.com/oooldtoy/SSTAP_ip_crawl_tool) | 游戏服务器 IP 规则的抓取与整理工具 |
| [alecthw/mmdb_china_ip_list](https://github.com/alecthw/mmdb_china_ip_list) | 完整配置模板及历史覆写脚本中的 MMDB 数据来源 |
| [xishang0128/geoip](https://github.com/xishang0128/geoip) | 完整配置模板及历史覆写脚本中的 GeoASN 数据来源 |
| [sub-store-org/Sub-Store](https://github.com/sub-store-org/Sub-Store) | 订阅处理脚本的运行平台 |
| [网易 UU 加速器](https://uu.163.com/) | 游戏网络规则的参考来源 |
| [217heidai/adblockfilters](https://github.com/217heidai/adblockfilters) | 已归档广告过滤脚本的数据来源 |
| [privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD) | 已归档广告过滤脚本的数据来源 |
| [TG-Twilight/AWAvenue-Ads-Rule](https://github.com/TG-Twilight/AWAvenue-Ads-Rule) | 已归档广告过滤脚本的数据来源 |
| [Aethersailor/adblockfilters-modified](https://github.com/Aethersailor/adblockfilters-modified) | 已归档广告过滤脚本的数据来源 |
| [521xueweihan/GitHub520](https://github.com/521xueweihan/GitHub520) | 已归档 GitHub 访问加速脚本的数据来源 |
| [TraderWukong/demo](https://github.com/TraderWukong/demo) | 项目早期保留的参考来源 |
| [ddgksf2013/ddgksf2013](https://github.com/ddgksf2013/ddgksf2013) | 项目早期保留的参考来源 |
| [immortalwrt/user-FAQ](https://github.com/immortalwrt/user-FAQ/) | IPv6 文档的历史参考来源 |

</details>

“历史”或“已归档”表示相关内容不再主动维护或推荐使用，但为保留来源记录而继续列出。

---

## 📝 许可

[![CC BY-SA 4.0 许可证](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.zh)

### CC BY-SA 4.0

本许可证适用于本项目的原创内容；第三方项目、规则、数据、工具与子模块仍适用各自的许可证或使用条款。引用、分发或修改前，请同时核对对应来源。

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
