<h1 align="center">
  🚀 Custom_OpenClash_Rules
</h1>

<p align="center"><b>OpenClash configuration, rule fragments, utilities, and override resources</b></p>

<p align="center">
  <b>English</b>
  &nbsp;|&nbsp;
  <a href="DO_NOT_README.md">简体中文</a>
</p>

<p align="center">
  <a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki">📖 Project Wiki</a>
  &nbsp;•&nbsp;
  <a href="cfg/">🧩 Configuration Resources</a>
  &nbsp;•&nbsp;
  <a href="rule/">🗂️ Rule Fragments</a>
</p>

<p align="center">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="GitHub contributors" src="https://img.shields.io/github/contributors-anon/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/t/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="OpenClash" src="https://img.shields.io/badge/OpenClash-resources-brightgreen?style=flat">
  <img alt="Website" src="https://img.shields.io/website?url=https%3A%2F%2Fapi.asailor.org%2Fversion&up_message=online&down_message=offline&style=flat&label=backend">
</p>

<p align="center"><b>✨ A More Elegant Way to Use OpenClash ✨</b></p>

---

## 📖 About This Project

**Custom_OpenClash_Rules** is a resource repository built around [OpenClash](https://github.com/vernesong/OpenClash).

It provides OpenClash configuration guidance, subscription-conversion templates, YAML examples, rule fragments, utility scripts, override resources, and related documentation to make OpenClash easier to deploy, maintain, and adjust.

The root README serves only as the project homepage and resource navigator. For individual files, their purposes, differences, and usage instructions, refer to the README in the corresponding directory or the project Wiki.

> [!NOTE]
> The project Wiki is currently available in Chinese only.

---

## 🚀 Quick Start

| Need | Recommended entry |
| --- | --- |
| Configure or understand OpenClash for the first time | [Project Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) |
| Use subscription-conversion templates or YAML examples | [`cfg/`](cfg/) |
| Add rules to an existing configuration | [`rule/`](rule/) |
| Use OpenClash-related utility scripts | [`shell/`](shell/) |
| Use remote override resources | [`overwrite/`](overwrite/) |
| Troubleshoot common problems | [Troubleshooting](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4) |

---

## 🧭 Project Resources

### 📚 Configuration Guides and Documentation

The project Wiki is one of the repository's two core components. It provides a complete configuration approach for OpenWrt and OpenClash rather than merely listing individual settings. The documentation explains how related options interact, why they are configured, and what effects they may have, helping users deploy and maintain OpenClash with an understanding of the underlying design.

The guide follows the practical OpenClash workflow and focuses on:

- **OpenClash fundamentals and transparent traffic routing**: Establishes a complete usage framework around `Fake-IP` mode, traffic interception, rule matching, and policy selection.
- **DNS strategy and leak-risk control**: Explains the resolution paths used by direct and non-direct traffic, with the aim of reducing unnecessary DNS detours, resolution failures, and leak risks.
- **Direct-access optimization**: Uses features such as OpenClash's “Bypass Mainland China” option so that suitable domains and IP addresses can retain local resolution and direct access, reducing unnecessary processing of direct traffic by OpenClash.
- **IPv6 configuration and compatibility**: Provides an approach for configuring IPv6 in OpenWrt and OpenClash while preserving IPv6 connectivity and applying the intended routing policies.
- **Troubleshooting and supplementary guides**: Covers common problems such as OpenClash startup failures, network interruptions, unexpected traffic routing, and inaccessible websites, together with related notes and tutorials.

The overall approach is designed to rely primarily on OpenClash's own capabilities and avoid unnecessary stacks of DNS plugins. Most operations can be completed through the OpenClash LuCI interface. The Wiki can therefore serve both as a first-time setup guide and as a reference for later troubleshooting and configuration optimization.

> [!TIP]
> New users should read the Wiki before selecting a configuration resource below. The Wiki explains why the settings are designed this way, while the configuration resources provide reusable implementations.

**Entry:** [Project Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

### 🧩 Configuration Resources

The `cfg/` directory is the repository's other core component. It converts the configuration approach described in the Wiki into reusable resources. The directory contains subscription-conversion templates, YAML configuration examples, and supporting documentation for users who want to generate an OpenClash configuration quickly or adapt an existing configuration.

These resources focus on:

- **Subscription conversion and configuration generation**: Organizes node subscriptions into structures suitable for OpenClash, reducing the need to write and maintain configurations manually.
- **Policy designs with different levels of complexity**: Provides configurations with different priorities, balancing policy-group coverage, ease of use, and maintenance cost.
- **Routing for common services and applications**: Organizes policy groups and rules for commonly used services, applications, and platforms while retaining room for further customization.
- **Alignment with the Wiki's configuration approach**: Designs the configurations around `Fake-IP`, DNS strategy, direct access, and rule-based routing so they can be used together with the project Wiki.
- **Rule and data update capabilities**: References upstream rules and GEO data to reduce the cost of manually maintaining time-sensitive datasets. Some configurations also apply differentiated handling to scenarios such as downloads and gaming platforms.
- **YAML configuration references**: Provides complete configuration-structure examples for understanding OpenClash configuration files and for use as a foundation when building or modifying a configuration.

The root README does not enumerate individual templates or configuration files. Refer to the README in `cfg/` for each configuration's purpose, differences, usage links, and precautions.

**Entry:** [`cfg/`](cfg/)

### 🗂️ Rule Fragments

Rule fragments that can be added selectively to an existing configuration. General and game-related rules are treated as a single resource category; consult the directory documentation for their classification and usage.

**Entry:** [`rule/`](rule/)

### 🛠️ Utility Scripts

Scripts related to OpenClash installation, updates, detection, and maintenance.

**Entry:** [`shell/`](shell/)

### ⚙️ Override Resources

Resources and documentation for OpenClash remote overrides. This directory references an externally maintained project; consult its directory documentation and upstream repository for details.

**Entry:** [`overwrite/`](overwrite/)

---

## 🎯 Project Scope

This repository primarily targets OpenWrt and OpenClash environments. It does not provide general-purpose configuration support for other clients or operating systems.

The project is a collection of the maintainer's personal experience and technical materials. It does not provide customized configurations, bespoke development, or one-to-one technical support.

---

## 🈸 Submitting Direct-Access Domains

For a small number of direct-access domains, using OpenClash custom rules is recommended first.

Domains suitable for inclusion in this project may be submitted through GitHub Issues, Pull Requests, or [COCR RULE BOT](https://telegram.me/asailor_rulebot).

> [!NOTE]
> Where appropriate, the maintainer may submit collected entries to relevant upstream rule projects.

---

## ⚠️ Special Disclaimer

> [!WARNING]
> **Usage Notice:**
>
> 1. This project is intended solely for technical study and research concerning the OpenWrt operating system and its OpenClash plugin. Its content consists of neutral technical implementation examples and experimental materials and is not directed toward any specific use case or purpose.
> 2. Before accessing, using, or copying any content from this project, users must independently confirm that doing so is permitted by the laws and regulations of their location and all relevant jurisdictions. The relevant content must be deleted within 24 hours after study and research.
> 3. This project's content must not be used for any purpose that violates applicable laws or regulations. Users must independently comply with the laws and regulations of their location and all relevant jurisdictions, including those of the People's Republic of China. Within the territory of the People's Republic of China, this project's content must not be used to obtain or disseminate unlawful information from outside the country whose access or distribution is legally restricted or blocked, or to engage in similar conduct.
> 4. This project neither provides nor concerns any equipment, software, tools, network connections, or services. The project maintainer does not produce, sell, or provide related equipment, software, tools, or technical services, nor does the maintainer provide technical support, assistance, or any other form of help to any individual or organization for obtaining or disseminating information whose access or distribution is legally restricted or blocked, or for circumventing regulatory systems.
> 5. Any individual or organization is solely responsible for conduct arising from its direct or indirect use of this project's content and bears all corresponding legal liability. The project maintainer does not participate in users' specific conduct and assumes no responsibility for their purposes, methods, or resulting consequences, including joint and several liability of any kind.
> 6. Any modification, secondary development, integration, distribution, or other derivative activity based on this project's content is the independent act of the relevant individual or organization and is unrelated to this project or its maintainer. Any resulting legal liability is borne solely by the party performing such activity.
> 7. This project discourages any form of reproduction, republication, or secondary dissemination. Reproducing, republishing, or redistributing this project's content on any platform within mainland China is strictly prohibited.
> 8. No reproduction, republication, or secondary dissemination may imply endorsement of the reproduced content by this project or its maintainer. Any legal risk arising from the reproduction, dissemination, or use of this project's content is borne solely by the party performing the relevant act and is unrelated to this project or its maintainer.
> 9. The project maintainer reserves the right to revise or supplement this disclaimer at any time. Any individual or organization that uses, copies, or accesses this project's content is deemed to have read and accepted this disclaimer.

> [!NOTE]
> - This project was created in April 2024 as a non-profit collection of technical research and practical experience.
> - The content reflects only the maintainer's personal experience. It is intended for technical exchange, is not authoritative, and does not represent the only or officially recommended way to use OpenClash.
> - This project does not operate any YouTube channel and has not published tutorials or instructional videos on YouTube or any other video platform.
> - This project's content was not compiled or adapted from third-party tutorials or videos. Problems caused by tutorials, templates, or configuration files from other sources should not be reported in this project's Issues or Discussions.
> - Accessible wording does not constitute a commitment to teach, guide, or support any particular group of users.

---

## 🤝 Contributors

<a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Aethersailor/Custom_OpenClash_Rules&anon=1&max=100" alt="Contributors" />
</a>

---

## 🙏 Acknowledgements

This project uses or references the following projects and resources, listed in no particular order:

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
- [Aethersailor/adblockfilters-modified](https://github.com/Aethersailor/adblockfilters-modified)
- [521xueweihan/GitHub520](https://github.com/521xueweihan/GitHub520)
- [Aethersailor/SubConverter-Extended](https://github.com/Aethersailor/SubConverter-Extended)
- [Aethersailor/subconverter](https://github.com/Aethersailor/subconverter)
- [Aethersailor/Rule-Bot](https://github.com/Aethersailor/Rule-Bot)
- [oooldtoy/SSTAP_ip_crawl_tool](https://github.com/oooldtoy/SSTAP_ip_crawl_tool)
- [immortalwrt/user-FAQ](https://github.com/immortalwrt/user-FAQ/)

---

## 📝 License

[![CC BY-SA 4.0 License](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.en)

### CC BY-SA 4.0

---

## ⭐ Star History

<a href="https://www.star-history.com/?type=date&repos=Aethersailor%2FCustom_OpenClash_Rules">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&theme=dark&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
    <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
  </picture>
</a>

## 📊 Statistics

![Repository activity statistics](https://repobeats.axiom.co/api/embed/0d7d55da94670a4766aa0fb8ccd03c7abc9e8464.svg "Repobeats analytics image")
