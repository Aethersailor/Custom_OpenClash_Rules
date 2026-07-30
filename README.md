<h1 align="center">
  🚀 Custom_OpenClash_Rules
</h1>

<p align="center"><b>OpenClash 配置方案、完整配置资源、规则文件、实用脚本与远程覆写模块</b></p>

<p align="center">
  <a href="DO_NOT_README.md">English</a>
  &nbsp;|&nbsp;
  <b>简体中文</b>
</p>

<p align="center">
  <a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki">📖 项目 Wiki</a>
  &nbsp;•&nbsp;
  <a href="#-三种完整配置方式">🧭 配置方式</a>
  &nbsp;•&nbsp;
  <a href="cfg/">🧩 配置资源</a>
  &nbsp;•&nbsp;
  <a href="overwrite/">⚙️ 覆写模块</a>
  &nbsp;•&nbsp;
  <a href="rule/">🗂️ 规则文件</a>
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

**Custom_OpenClash_Rules** 是一个围绕 [OpenClash](https://github.com/vernesong/OpenClash) 整理和维护的配置资源仓库。

项目主要提供：

- OpenClash 设置方案与故障排查文档；
- 订阅转换模板、YAML 配置文件及其远程覆写模块；
- 自定义规则与多格式派生规则；
- DNS、规则和数据源相关的单功能覆写模块；
- OpenClash 安装、更新与维护脚本。

> [!IMPORTANT]
> 完整配置资源主要负责节点来源、策略组、Rule Provider 和分流规则。DNS、IPv6、TUN、嗅探、运行模式、流量接管等插件参数，仍应根据自身环境在 OpenClash LuCI 中完成设置。
>
> 首次使用建议先阅读 [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)。

> [!NOTE]
> 项目 Wiki 目前仅提供中文版本。

---

## 🧭 三种完整配置方式

本项目提供三种方式加载完整配置。它们的区别在于**配置的获取和维护方式**，而不是分流设计。

> [!IMPORTANT]
> 选择相同配置版本且未自行修改内容时，三种方式的**策略组结构、规则引用、规则顺序和分流逻辑完全对齐**。

| 使用方式 | 资源入口 | 适合场景 |
| --- | --- | --- |
| **订阅转换** | [`cfg/README.md`](cfg/README.md) | 操作最简单，直接在 OpenClash 中更新订阅 |
| **远程 YAML 覆写模块** | [`overwrite/yaml/README.md`](overwrite/yaml/README.md) | 不使用订阅转换，也不想手工维护 YAML |
| **下载并导入 YAML** | [`cfg/yaml/README.md`](cfg/yaml/README.md) | 需要固定版本或自行修改配置 |

三种方式通常应当选择一种作为主路径。详细操作、参数和注意事项请进入对应目录查看。

---

## 🧩 配置资源

完整配置资源由三部分组成：

| 资源 | 位置 | 用途 |
| --- | --- | --- |
| **订阅转换模板** | [`cfg/*.ini`](cfg/) | 通过订阅转换生成完整配置 |
| **YAML 配置文件** | [`cfg/yaml/*.yaml`](cfg/yaml/) | 用于手工导入，也是远程 YAML 模块的调用目标 |
| **YAML 对应的远程覆写模块** | [`overwrite/yaml/*.conf`](overwrite/yaml/) | 自动下载 YAML、写入订阅并切换配置 |

所有自定义订阅转换模板均已被 OpenClash 收录，常规使用可直接在内置模板列表中选择。

不同配置版本的定位、普通版与 Fallback 版区别、自建节点配置及详细使用方法，请查看：

- [`cfg/README.md`](cfg/README.md)
- [`cfg/yaml/README.md`](cfg/yaml/README.md)
- [`overwrite/yaml/README.md`](overwrite/yaml/README.md)

---

## 🚀 快速开始

1. 按照 [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 完成 OpenClash 基础设置。
2. 选择所需的标准、轻量、极简 GFW、重度分流或对应 Fallback 版本。
3. 从订阅转换、远程 YAML 覆写模块、手工导入 YAML 中选择一种方式。
4. 配置订阅地址、自建节点或模块变量。
5. 检查配置校验、内核启动、Provider、策略组、DNS、IPv6、实际分流和日志。

---

## 📚 其他资源

| 资源 | 用途 | 详细说明 |
| --- | --- | --- |
| [`overwrite/`](overwrite/) | DNS、规则、`no-resolve`、Provider 格式和数据源等单功能覆写模块 | [`overwrite/README.md`](overwrite/README.md) |
| [`rule/`](rule/) | 自定义直连、代理、游戏下载、加密 DNS 及多格式派生规则 | [`rule/README.md`](rule/README.md) |
| [`shell/`](shell/) | OpenClash 安装、更新和架构检测脚本 | [`shell/README.md`](shell/README.md) |
| [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) | 配置原理、操作方案和故障排查 | [进入 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) |

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
