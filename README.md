<h1 align="center">
  🚀 OpenClash 配置方案<br>
  &<br>
  🛡️ 分流规则与防泄漏配置模板
</h1>

<p align="center">
 <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=flat">
 <img alt="GitHub contributors" src="https://img.shields.io/github/contributors-anon/Aethersailor/Custom_OpenClash_Rules?style=flat">
 <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/t/Aethersailor/Custom_OpenClash_Rules?style=flat">
 <img alt="OpenClash" src="https://img.shields.io/badge/OpenClash-integrated-brightgreen?style=flat">
 <img alt="Website" src="https://img.shields.io/website?url=https%3A%2F%2Fapi.asailor.org%2Fversion&up_message=online&down_message=offline&style=flat&label=backend">
</p>
<p align="center"><b>✨ 让你更优雅地使用 OpenClash ✨</b></p>

---

<p align="center">
  <a href="#-关于本项目">📖 关于</a>
  &nbsp;•&nbsp;
  <a href="#%EF%B8%8F-特别声明">⚠️ 声明</a>
  &nbsp;•&nbsp;
  <a href="#-本项目设置方案及转换模板介绍">📝 方案</a>
  &nbsp;•&nbsp;
  <a href="#%EF%B8%8F-使用方法">🛠️ 用法</a>
  &nbsp;•&nbsp;
  <a href="#-一些说明">💡 说明</a>
  &nbsp;•&nbsp;
  <a href="#-贡献者">🤝 贡献</a>
  &nbsp;•&nbsp;
  <a href="#-感谢">🙏 感谢</a>
  &nbsp;•&nbsp;
  <a href="#-许可">📝 许可</a>
</p>

---

## 📖 关于本项目

> ⭐ **本项目提供 [OpenClash](https://github.com/vernesong/OpenClash) 的图文配置方案与规则/模板示例。**

本项目整理了一套可复用的设置思路与配置示例，尽量避免不必要的“套娃”设置。

[OpenClash](https://github.com/vernesong/OpenClash) 是 OpenWrt 下常用的网络流量分流与出站策略插件，可用于按规则对流量进行处理并配合 DNS 策略降低泄漏风险。

本项目示例如何将 OpenClash 配置为更稳定、可维护的透明分流状态，侧重 DNS 防泄漏、规则分流与日常可用性，无需搭配其他插件。

> 🧩 **彻底告别手搓配置和多个插件套娃的繁琐设置方法，保证零基础小白也能轻松看懂。**

按照本项目的 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的设置方案，搭配本项目的[订阅转换模板](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini)，花费数分钟对 OpenClash 进行设置，无需套娃其他工具，仅依靠 OpenClash 自身即可实现更稳健的 DNS 策略与分流功能，同时配合 Dnsmasq 可实现无需第三方插件的广告拦截，并且完美兼容 IPv6。

同时也提供基于 OpenClash 远程覆写功能的配置示例。

欢迎 ⭐star！

---

> [!NOTE]
> **声明事项：**
>
> - 本项目编写于 2024 年 4 月，为非盈利性质的技术研究与经验整理项目。
> - **本项目内容仅为维护者个人经验的总结，用于技术交流，不具权威性，亦不构成 OpenClash 的唯一或推荐使用方式。**
> - **本项目未运营任何 YouTube 频道，亦未在 YouTube 或其他视频平台发布任何形式的教学或指导视频。**
> - **本项目内容未基于其他第三方教程或视频进行整理或改编。如因使用其他来源的教程、模板或配置文件产生问题，请勿在本项目的 Issues/Discussions 中反馈。**
> - **本项目部分内容在表述上可能相对易于理解，但不构成对任何特定用户群体的教学、指导或支持承诺，维护者亦不承担相应帮助义务。**

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
> 7. 本项目以 CC-BY-SA-4.0 许可协议发布（见下方许可章节），但不鼓励任何形式的转载、再发布或二次传播，且严禁转载、再发布或二次传播本项目内容至中国大陆境内任何平台之上。
> 8. 任何转载、再发布或二次传播均均不得暗示本项目或维护者对转载内容背书。因转载、传播或使用本项目内容所产生的法律风险，由行为主体自行承担，与本项目及其维护者无关。
> 9. 本项目维护者保留在任何时间对本免责声明进行修订或补充的权利。任何使用、复制或访问本项目内容的个人或组织，均视为已知悉并接受本免责声明。

---

## 📝 本项目设置方案及订阅转换模板介绍

本项目的配置模板参考 [ACL4SSR](https://github.com/ACL4SSR/ACL4SSR/tree/master) 等规则模板进行完善，分流数据基于 GeoSite。

**按照本项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的设置方案，配合本项目的订阅转换模板对 OpenClash 进行配置，即可实现以下特性，更优雅地使用你的 OpenClash：**

- 🚀 **优化的 DNS 设置，尽量降低对直连访问的影响**
  > 本地站点采用运营商 DNS 解析，示例地区(CN)域名和 IP 不经 OpenClash 内核处理并返回真实 IP，让 OpenClash 对直连访问的影响降低到更小。

- 🛡️ **降低解析异常与泄漏风险，无需搭配其他插件**
  > 非直连站点可根据规则由出站侧完成 DNS 解析与访问，并配合策略降低泄漏风险。

- 🧩 **彻底告别套娃设置**
  > 免去各种 DNS 插件带来的搭配烦恼，全部特性依靠 OpenClash 一个插件实现，且保证 OpenClash 即使挂了也不影响访问直连站点。

- 🖱️ **傻瓜化的设置操作**
  > 全程在 OpenClash 页面上操作，鼠标点击 + 复制粘贴几分钟即可完成完美设置，无需手搓配置，无需上传文件。

- 🗂️ **丰富的分流策略组**
  > 多款规则模板，包含常见应用/服务（如影音、AI 工具、电商、游戏平台等）的分流策略组，同时也提供简化版本的规则。

- ⚡ **分流与测速优选**
  > 自动优选低延迟出站项，减少手动切换成本。

- 🎮 **Steam 访问优化**
  > Steam 下载流量与非下载流量分流，允许在 Steam 代理登录的情况下，下载流量仍然直连。

- 🔄 **自动更新，长期无人值守**
  > 设置完成后即可长期无人值守，每日定时自动更新上游规则 GEO 数据库和直连白名单等具有时效性要求的数据，无需自己动手。

- 🌍 **大流量下载优化**
  > 提供非标端口分流控制，尽力避免大流量下载走非直连出口，提供下载类流量优化选项，减少不必要的出站流量消耗。

- ~~🚫 **广告屏蔽功能和 hosts 加速**~~ *(暂时停用)*
  > ~~依靠 OpenClash 配合系统自带 Dnsmasq 实现广告过滤和 hosts 加速功能，并实现每日自动更新，支持添加多个规则。（可选）~~

- 🧩 **直连冷门域名处理机制**
  > 增加了一些小众网站的直连规则；维护者会根据反馈定期将收集到的域名向上游规则提交。

---

## 🛠️ 使用方法

> [!IMPORTANT]
> **重要提醒：**
>
> - 本项目设置方案使用 OpenClash 的 `Fake-IP` 模式，不适用 Redir-Host 模式。
> - 本项目依赖 OpenClash 的"绕过中国大陆"功能实现效果。

请按照本项目 Wiki 中的对应部分对 OpenClash 进行设置：[OpenClash-设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置方案)

方案中已包括了本项目订阅转换模板的使用方法，根据描述，自行选择需要使用的规则模板即可。

以上方案非常详尽，只需按部就班设置即可。全部设置内容均基于 OpenClash 的 luci 设置页面。

如需使用远程覆写配置文件，可参考 [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)。

> [!TIP]
> **📝 阅读建议：**
>
> 设置方案文字较多，务必逐字逐句认真阅读，不要忽略以防漏掉关键部分导致故障。且方案内含多处设置的讲解便于理解相关设置原理，有助于小白学习。

---

## 💡 一些说明

### 🎨 关于个性化需求

> [!NOTE]
> 由于本项目为自用目的，且个人时间有限，只能随缘更新，因此不提供个性化修改服务。

具体个性化实现方式，请参考 Wiki 中的对应章节：[个性化需求](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E5%85%B6%E4%BB%96%E8%AF%B4%E6%98%8E#%E5%85%B3%E4%BA%8E%E4%B8%AA%E6%80%A7%E5%8C%96%E9%9C%80%E6%B1%82)

### 🈸 关于冷门直连域名收录问题

若需要添加少量需要直连的冷门域名，建议使用 OpenClash 的自定义规则功能，插入相关的规则条目。

如希望将少量直连域名纳入仓库规则中，建议通过 GitHub Issues/PR 进行提交与讨论。

也可访问 [COCR RULE BOT](https://t.me/asailor_rulebot) 按照提示添加域名，符合要求的域名会自动添加至本项目的直连规则中。  

> [!NOTE]
> 维护者会定期将收集到的冷门直连域名向上游规则进行 PR。

---

### ~~🚫 关于广告过滤~~

<details>
<summary>点击查看已废弃的广告过滤说明</summary>

> **2025.7.22**：目前发现该功能可能引起 dnsmasq 故障，请暂时停用。

~~本项目借助 OpenClash 的"开发者选项"功能，实现不依赖第三方插件的广告过滤功能。~~

~~具体设置见 Wiki 中的方案：[广告拦截设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%97%A0%E6%8F%92%E4%BB%B6%E5%B9%BF%E5%91%8A%E6%8B%A6%E6%88%AA%E5%8A%9F%E8%83%BD%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)~~

~~其中提供了 Dnsmasq 格式和 hosts 格式的两种设置方法的示例，可以照抄，亦可自由设置其他任何符合格式要求的广告规则。~~

</details>

---

### 🌐 关于 IPv6

通过正确设置 OpenWrt 的 IPv6 功能以及 OpenClash，即可实现 OpenWrt 主路由下的 IPv6 和 OpenClash 的更好兼容，并支持在 IPv6 环境下进行分流与连通性测试。

OpenWrt 的 IPv6 设置方案见本项目的 Wiki：[OpenWrt-IPv6-设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenWrt-IPv6-设置方案)

---

### ❓ 不能上网？分流不正常？某些网站打不开？OpenClash 不能启动？

出现故障请参考 [Wiki 中的故障排除部分](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4)，内含常见问题的解决方法。

> [!TIP]
> 🛠️ 项目的设置方案经过众多用户验证一般不存在结构性问题，建议不要从本项目的内容上找原因，以免浪费时间。某些特定应用/服务的异常可能涉及多种因素，与模板本身未必相关。

---

### 💻 其他环境

本仓库仅讨论 OpenWrt / OpenClash 场景。其他客户端或系统环境请自行查阅对应项目文档。

---

## 🤝 贡献者

<a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Aethersailor/Custom_OpenClash_Rules&anon=1" alt="贡献者列表" />
</a>

---

## 🙏 感谢

**本项目使用或引用了以下内容：**

以下排名不分先后

### 🔌 插件

- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)

### 🧩 内核

- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)

### 🗂 配置模板

- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)

### ⚙️ 远程覆写配置

- [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)

### 🛣 分流规则

- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [v2fly/domain-list-community](https://github.com/v2fly/domain-list-community)
- [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)
- [Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat)
- [dogfight360/UsbEAm](https://www.dogfight360.com/blog/18627/)
- [ddgksf2013/ddgksf2013](https://github.com/ddgksf2013/ddgksf2013)
- [mottzz87/crules](https://github.com/mottzz87/crules)

### 🚫 广告过滤规则

- [217heidai/adblockfilters](https://github.com/217heidai/adblockfilters)
- [privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD)
- [TG-Twilight/AWAvenue-Ads-Rule](https://github.com/TG-Twilight/AWAvenue-Ads-Rule)
- [Aethersailor/adblockfilters-modified](https://github.com/Aethersailor/adblockfilters-modified)

### ⚡ 加速规则

- [521xueweihan/GitHub520](https://github.com/521xueweihan/GitHub520)

### 🔄 订阅转换后端

- [Aethersailor/SubConverter-Extended](https://github.com/Aethersailor/SubConverter-Extended)
- [Aethersailor/subconverter](https://github.com/Aethersailor/subconverter)

### 🧰 工具

- [Aethersailor/Rule-Bot](https://github.com/Aethersailor/Rule-Bot)
- [oooldtoy/SSTAP_ip_crawl_tool](https://github.com/oooldtoy/SSTAP_ip_crawl_tool)

### 🔖 其他

- [immortalwrt/user-FAQ](https://github.com/immortalwrt/user-FAQ/)

---

## 📝 许可

[![CC-BY-SA-4.0 许可证](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.zh)

### CC-BY-SA-4.0

---

## ⭐ 记录

<a href="https://www.star-history.com/?type=date&repos=Aethersailor%2FCustom_OpenClash_Rules">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&theme=dark&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
   <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
 </picture>
</a>

## 📊 数据统计

![Alt](https://repobeats.axiom.co/api/embed/0d7d55da94670a4766aa0fb8ccd03c7abc9e8464.svg "Repobeats analytics image")  
