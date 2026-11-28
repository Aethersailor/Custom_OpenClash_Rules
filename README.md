<h1 align="center">
  🚀 Custom_OpenClash_Rules
</h1>

<p align="center"><b>OpenClash setup guides, subscription conversion templates, YAML configurations, rule files, utility scripts, and overwrite modules</b></p>

<p align="center">English · <a href="README-zh-CN.md">简体中文</a></p>

<p align="center">
  <a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki">📖 Project Wiki</a>
  &nbsp;•&nbsp;
  <a href="cfg/">🧩 Configuration Resources</a>
  &nbsp;•&nbsp;
  <a href="rule/">🗂️ Rule Files</a>
  &nbsp;•&nbsp;
  <a href="overwrite/">⚙️ Overwrite Modules</a>
  &nbsp;•&nbsp;
  <a href="shell/">🛠️ Utility Scripts</a>
</p>

<p align="center">
  <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="GitHub contributors" src="https://img.shields.io/github/contributors-anon/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/t/Aethersailor/Custom_OpenClash_Rules?style=flat">
  <img alt="OpenClash" src="https://img.shields.io/badge/OpenClash-resources-brightgreen?style=flat">
  <img alt="Website" src="https://img.shields.io/website?url=https%3A%2F%2Fapi.asailor.org%2Fversion&up_message=online&down_message=offline&style=flat&label=backend">
</p>

---

> [!WARNING]
> This project provides neutral technical material solely for studying and researching OpenWrt and OpenClash outside the People's Republic of China.
>
> **Organizations and individuals are prohibited from accessing, downloading, or using any part of this project in mainland China. If you are in mainland China, close this page immediately.**
>
> Organizations and individuals must not use any part of this project for activities that violate applicable laws or regulations. Users are individually responsible for the legal consequences of their use.

## 📖 About This Project

**Custom_OpenClash_Rules** is a repository of configuration and extension resources for [OpenClash](https://github.com/vernesong/OpenClash).

The project provides OpenClash setup documentation, subscription conversion templates, YAML configurations, rule files, remote overwrite modules, and supporting scripts. You can use each type of resource independently. For a complete setup, also apply the OpenClash LuCI settings documented in the project Wiki.

> [!TIP]
> **OpenClash is the only plugin required**
>
> Every configuration approach in this project works with OpenClash alone. There is no need to stack additional proxy or DNS plugins or use any other layered setup.

> [!IMPORTANT]
> **DNS leak prevention**
>
> You can prevent local DNS leaks by applying the project's OpenClash settings and using any of the three subscription setup methods (subscription conversion, remote YAML overwrite, or manual YAML import) when both of the following conditions are met.
>
> - Fake-IP, traffic interception, and DNS settings are active as documented in the Wiki.
> - DNS queries from client devices and the related traffic pass through OpenClash.
>
> Test for DNS leaks to verify the actual results. Applying the settings alone is insufficient. Client-side Private DNS or DoH, devices or traffic that OpenClash does not intercept, plugin or firmware behavior that differs from the documentation, and manual DNS overrides are outside the scope of this setup. Handle and test those cases separately.

The root `README.md` is the project home page and resource index. It describes what each resource is for and where to find it. See the `README.md` displayed in the relevant directory for specific files, differences between versions, parameters, and instructions.

> [!NOTE]
> The project Wiki is currently available only in Chinese.

---

## ⚠️ Important Notices

> [!IMPORTANT]
> **Project scope**
>
> This project provides no proxy servers, proxy nodes, or node subscriptions for users. It operates no commercial or other proxy services and provides no internet access services. Neither the project nor its maintainers partner with, represent, or act as guarantors for such providers.

> [!WARNING]
> Before using this project, expand and read the full notice below.

<details>
<summary><strong>Full Usage Notice and Disclaimer</strong></summary>

<br>

**Usage notice**

1. This project is solely for the technical study and research of OpenWrt and its OpenClash plugin. Its contents are neutral implementation examples and experimental materials, independent of any specific use case or intended application.
2. This project is not offered within the territory of the People's Republic of China. Individuals and organizations within that territory are strictly prohibited from accessing, downloading, copying, storing, installing, running, deploying, modifying, disseminating, or otherwise using any part of this project in any form. Anyone who has already obtained the material must immediately stop using it and permanently delete all copies.
3. Before accessing, using, or copying project material, users must determine for themselves whether the laws and regulations of their location and any relevant jurisdiction permit it. Users must delete the material within 24 hours after completing their study and research.
4. Project material must not be used for any purpose that violates applicable laws or regulations. Users are responsible for complying with the laws and regulations of their location and any relevant jurisdiction, including applicable laws and regulations of the People's Republic of China. Users must not use project material within the territory of the People's Republic of China to obtain or disseminate unlawful information from abroad that is restricted or blocked by law, or to engage in similar activities.
5. This project does not provide or involve equipment, software, tools, network connections, or services. The maintainers do not make, sell, or supply related equipment, software, tools, or technical services. They do not provide technical support, assistance, or any other form of help to individuals or organizations in obtaining or disseminating information restricted or blocked by law or in circumventing regulatory controls.
6. Individuals and organizations are solely responsible for their actions involving direct or indirect use of project material and bear the associated legal liability. The maintainers take no part in users' actions and accept no responsibility for the purposes, methods, or consequences of such use. They assume no form of joint and several liability.
7. Any modification, further development, integration, distribution, or other derivative activity based on project material is an independent act of the individual or organization carrying it out. It is unaffiliated with the project and its maintainers, and the party carrying out the activity bears any resulting legal liability.
8. The project discourages all forms of reposting, republication, and redistribution. Reposting, republishing, or redistributing project material on any platform in mainland China is strictly prohibited.
9. Reposting, republication, or redistribution must never imply that the project or its maintainers endorse the reposted material. The party that reposts, disseminates, or uses the project material assumes the resulting legal risks independently of the project and its maintainers.
10. The maintainers reserve the right to revise or supplement this disclaimer at any time. Any individual or organization that uses, copies, or accesses project material is deemed to know and accept this disclaimer.

**Additional information**

- The project was created in April 2024 as a nonprofit effort to conduct technical research and document practical experience.
- The material summarizes the maintainer's personal experience for technical discussion. It is non-authoritative and does not establish a sole or recommended way to use OpenClash.
- The project operates no YouTube channel and has published no tutorials or guidance videos on YouTube or any other video platform.
- The maintainer independently prepared the documentation based on practical experience. Third-party projects, materials, and resources are credited where used or in the Acknowledgments below. If you encounter problems with tutorials, templates, or configuration files from other sources, do not report them in this project's Issues or Discussions.
- The material uses straightforward language. This does not imply a commitment to teach, guide, or support any group of users.

</details>

---

## 🚀 Quick Start

| Task | Where to start |
| --- | --- |
| Set up OpenClash for the first time or learn how it works in depth | [Project Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) |
| Use subscription conversion templates, YAML configurations, or remote YAML overwrite modules | [`cfg/`](cfg/) |
| Add or correct rules in an existing configuration | [`rule/`](rule/) |
| Use standalone game rules | [`rule/game_rule/`](rule/game_rule/) |
| Use single-purpose remote overwrite modules | [`overwrite/`](overwrite/) |
| Install, update, or run checks for OpenClash | [`shell/`](shell/) |
| Use Sub-Store extension scripts | [Sub-Store scripts](script/sub-store/) |
| Troubleshoot common problems | [Troubleshooting](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4) |

---

## 🧭 Project Resources

### 📚 Setup Guides and Documentation

The project Wiki is a core resource in this repository. It documents a complete approach to setting up OpenWrt and OpenClash.

It covers the following topics.

- **The full OpenClash setup process, from preparation through verification**. Operating modes, traffic interception, rule matching, and policy selection.
- **DNS policies and leak prevention**. Resolution paths for direct and proxied traffic, DNS hijacking, and DNS resolution that follows routing rules.
- **Direct-access optimization**. Bypass rules for mainland China domains and IP addresses reduce unnecessary proxy handling.
- **IPv6 setup and compatibility**. Preserve IPv6 connectivity while routing and intercepting traffic correctly.
- **Troubleshooting and supplementary guides**. Common issues such as startup failures, network problems, and unexpected rule matches.

The Wiki explains the reasoning behind the setup. The resource directories contain files you can use as is or adapt.

See the [Project Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki).

---

### 🧩 Configuration Resources

[`cfg/`](cfg/) provides ready-to-use resources that implement the configuration design described in the Wiki.

| Resource | Location | Main purpose |
| --- | --- | --- |
| **Subscription conversion templates** | [`cfg/`](cfg/) | Generate a complete OpenClash configuration through online subscription conversion |
| **YAML configuration files** | [`cfg/yaml/`](cfg/yaml/) | Download, edit, and import a configuration into OpenClash manually |
| **Remote YAML overwrite modules** | [`overwrite/yaml/`](overwrite/yaml/) | Automatically download the corresponding YAML file, insert the subscription, and switch the active configuration |

> [!IMPORTANT]
> The project provides three ways to use a complete configuration.
>
> 1. **Convert a subscription**.
> 2. **Use a remote YAML overwrite module**.
> 3. **Download a YAML configuration, then edit and import it manually**.
>
> All three methods follow the same configuration design. If you choose the same edition and make no custom changes, the roles of the policy groups, rule order, and traffic routing logic should be consistent. File structure and loading methods differ, and the subscription conversion backend and OpenClash version can affect the results.

The OpenClash `dev` version currently includes all 8 subscription conversion templates from this project. These include the Standard, Lite, Minimal GFW, and Full Routing editions, plus a corresponding failover edition for each with a filename ending in `_Fallback`. If an older version does not list the desired template, enter its remote URL manually. See [`cfg/`](cfg/) for instructions and URLs.

For the exact built-in template names, see [`sub_ini.list`](https://github.com/vernesong/OpenClash/blob/dev/luci-app-openclash/root/usr/share/openclash/res/sub_ini.list) on the OpenClash `dev` branch. If OpenClash changes its built-in list, the interface may differ from this README. You can still use the templates by entering their remote URLs manually.

The project provides Standard, Lite, Minimal GFW, and Full Routing editions along with their corresponding failover editions. It also provides YAML for self-hosted proxy nodes. See the respective directories for the intended use of each edition, parameters, remote URLs, and detailed instructions.

Browse the configuration resources.

- Subscription conversion templates in [`cfg/`](cfg/)
- YAML configuration files in [`cfg/yaml/`](cfg/yaml/)
- Remote YAML overwrite modules in [`overwrite/yaml/`](overwrite/yaml/)

---

### 🗂️ Rule Files

[`rule/`](rule/) contains supplemental rules maintained by this project and their derivatives in multiple formats. These include custom direct-routing rules, proxy rules, Steam CDN rules, game download CDN rules, and encrypted DNS rules.

The `.list` files are the primary sources. Workflows generate Classical YAML, Domain YAML, IP-CIDR YAML, and MRS files from them for use by subscription conversion templates or Mihomo Rule Providers.

> [!IMPORTANT]
> **The maintainers and community users collect direct-routing rules together.**

Choose where to submit based on your needs.

| Task | Where to go |
| --- | --- |
| Manually look up or submit a small number of domains for direct routing | Use the [public Rule-Bot instance](https://t.me/asailor_rulebot) |
| Continuously collect domains from connections that ultimately match Mihomo's `MATCH` rule | Follow [Connect Rule-Bot Client to the public Rule-Bot instance](https://github.com/Aethersailor/Rule-Bot-Client/wiki/%E6%8E%A5%E5%85%A5%E5%85%AC%E5%85%B1-Rule-Bot) to configure the client. The client stores domains locally by default. Sending requires explicit opt-in |
| Submit verified domains in bulk | Edit [`rule/Custom_Direct.list`](rule/Custom_Direct.list) and open a pull request |
| Submit when Rule-Bot is unavailable to you or when you need to attach complete evidence | Use the [mainland China direct-routing domain issue form](https://github.com/Aethersailor/Custom_OpenClash_Rules/issues/new?template=02_direct_domain_submission.yml) |
| Report OpenClash startup failures, interface issues, or installation failures | Use the [official OpenClash issue chooser](https://github.com/vernesong/OpenClash/issues/new/choose) |

Before submitting, search the existing rules, issues, and pull requests. Include the rule that actually matched, the selected policy, and verifiable evidence. Keep subscription URLs, tokens, proxy node credentials, and other sensitive information off public pages.

[`rule/game_rule/`](rule/game_rule/) contains separate, manually curated game rules. The `.list` files are the sources. Workflows automatically generate YAML and MRS derivatives. Updates to rule contents and loading into the main configuration are outside those workflows. Before using the rules, check their intended server regions, last update date, and actual matches.

Browse [`rule/`](rule/).

> [!NOTE]
> The maintainers submit rules collected by this project to relevant upstream rule projects where appropriate.

---

### 🛠️ Utility Scripts

[`shell/`](shell/) provides scripts for installing and updating OpenClash and detecting CPU architecture. The scripts support OpenWrt and ImmortalWrt and work with both OPKG and APK package managers.

The scripts may temporarily switch package feeds, reinstall the plugin over an existing installation, change UCI settings, or use the built-in OpenClash update process. Read the full instructions in the directory before running them.

The [Sub-Store extension scripts](script/sub-store/) extend Sub-Store's subscription processing capabilities. These scripts are independent of OpenClash installation, and the project's configurations do not load them automatically.

Browse the scripts.

- OpenClash installation and maintenance scripts in [`shell/`](shell/)
- [Sub-Store extension script directory](script/sub-store/)

---

### ⚙️ Overwrite Module Resources

[`overwrite/`](overwrite/) contains OpenClash remote overwrite modules and related resources.

The top level of that directory mainly contains single-purpose remote overwrite modules. [`overwrite/yaml/`](overwrite/yaml/) contains remote overwrite modules that use the project's YAML configurations.

See the respective directories for what each module modifies, its parameters, how it combines with other modules, and potential conflicts. More overwrite modules will be added over time.

Browse the overwrite modules.

- Single-purpose overwrite modules in [`overwrite/`](overwrite/)
- Remote YAML overwrite modules in [`overwrite/yaml/`](overwrite/yaml/)

---

## 🎯 Project Scope

This repository primarily covers OpenWrt and OpenClash. General configuration support for other clients or operating systems falls outside its scope.

The project compiles the maintainer's personal experience and technical material. It provides no personalized configuration, custom development, or one-on-one technical support.

---

## 💬 Discussion and Feedback

Use [GitHub Discussions](https://github.com/Aethersailor/Custom_OpenClash_Rules/discussions) for usage questions and configuration discussions.

> [!IMPORTANT]
> If troubleshooting confirms that the OpenClash plugin itself caused the issue and this project's configurations or rules are unrelated, use the [official OpenClash issue chooser](https://github.com/vernesong/OpenClash/issues/new/choose). Examples include plugin startup failures, interface issues, and installation failures.

For general issues with rules, templates, scripts, or documentation, use [this project's issue chooser](https://github.com/Aethersailor/Custom_OpenClash_Rules/issues/new/choose). For security issues involving leaked credentials, bypassed download verification, or the script execution chain, first read the [security reporting instructions](SECURITY.md). Keep those details out of public issues.

---

## ⚠️ Usage and Limits of Responsibility

This project provides unofficial technical documentation and configuration resources for OpenWrt and OpenClash. It provides no equipment, network connections, subscriptions, or hosted services. The material is provided as is. Verify compatibility, accuracy, and results for the versions and environment you actually use.

Applicable laws, third-party rights, and each source's license apply independently. Users are responsible for confirming that their use meets applicable requirements. This section provides no legal advice and adds no platform, purpose, time, or noncommercial restrictions beyond the CC BY-SA 4.0 license described below.

When reposting, modifying, or distributing the material, do not imply that the project or its maintainers support or endorse any related content, product, or service.

<!-- -->

> [!NOTE]
>
> - The project was created in April 2024. The maintainer runs it on a nonprofit basis. This does not limit commercial use permitted by CC BY-SA 4.0.
> - The material summarizes the maintainer's personal experience for technical discussion. It is non-authoritative and does not establish a sole or recommended way to use OpenClash.
> - The project operates no YouTube channel and has published no tutorials or guidance videos on YouTube or any other video platform.
> - The maintainer independently prepared the documentation based on practical experience. Third-party projects, materials, and resources are credited where used or in the Acknowledgments below. If you encounter problems with tutorials, templates, or configuration files from other sources, do not report them in this project's Issues or Discussions.
> - The material uses straightforward language. This does not imply a commitment to teach, guide, or support any group of users.

---

## 🤝 Contributors

<a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Aethersailor/Custom_OpenClash_Rules&anon=1&max=100" alt="Contributors" />
</a>

---

## 🙏 Acknowledgments

The projects and resources below provide foundations, data, tools, or references. They are grouped by how this project uses them, with no ranking within each group. Inclusion does not imply official support or endorsement.

### Core Upstream Projects and Current Data Sources

| Project or resource | How this project uses it |
| --- | --- |
| [vernesong/OpenClash](https://github.com/vernesong/OpenClash) | The OpenWrt plugin that this project's configurations, overwrite scripts, and documentation are written for |
| [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo) | Rule formats, configuration capabilities, and tools for generating and validating MRS files |
| [vernesong/mihomo](https://github.com/vernesong/mihomo) | LightGBM model resources used by installation scripts and third-party overwrite configurations |
| [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) | The base template for this project's subscription conversion configurations |
| [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite) | A third-party complete overwrite configuration retained as a Git submodule |
| [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) | Data source for mainland China IPTV domain rules |
| [v2fly/domain-list-community](https://github.com/v2fly/domain-list-community) | Data source for game download domains and encrypted DNS GeoSite rules |
| [HaGeZi DNS Blocklists](https://gitlab.com/hagezi/mirror/-/tree/main/dns-blocklists) | Data source for encrypted DNS domain and IP rules |
| [DNSCrypt/dnscrypt-resolvers](https://github.com/DNSCrypt/dnscrypt-resolvers) | Data source for public encrypted DNS resolvers, relays, and ODoH endpoints |
| [dogfight360/UsbEAm](https://www.dogfight360.com/blog/18627/) | A reference tool for game network addresses and download endpoint rules |

### Related Projects

| Project | Relationship to this project |
| --- | --- |
| [Aethersailor/SubConverter-Extended](https://github.com/Aethersailor/SubConverter-Extended) | An optional enhanced subscription conversion backend that reads this project's `.ini` templates and generates YAML. Remote YAML overwrites and manual YAML imports work independently of it |
| [Aethersailor/subconverter](https://github.com/Aethersailor/subconverter) | The legacy subscription conversion backend. Its features and maintenance scope differ from those of SubConverter-Extended |
| [Aethersailor/Rule-Bot](https://github.com/Aethersailor/Rule-Bot) | A domain checking and submission service. The public instance submits qualifying domains to this repository. Self-hosted instances can use other target repositories |
| [Aethersailor/Rule-Bot-Client](https://github.com/Aethersailor/Rule-Bot-Client) | Collects domains from Mihomo connections handled by `MATCH` and stores them locally by default. The client sends candidates to Rule-Bot only after the user explicitly enables sending |
| [Aethersailor/geoip](https://github.com/Aethersailor/geoip) | Source of GeoIP databases and mainland China IPv4 and IPv6 ranges |

<details>
<summary><strong>Other Rules, Tools, and Historical References</strong></summary>

| Project or resource | How this project uses it |
| --- | --- |
| [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list) | The upstream submission target for supplemental direct-routing domains |
| [Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat) | Source of GeoIP and GeoSite data for complete configuration templates |
| [mottzz87/crules](https://github.com/mottzz87/crules) | The original source of the Talkatone rules, which are no longer updated |
| [oooldtoy/SSTAP_ip_crawl_tool](https://github.com/oooldtoy/SSTAP_ip_crawl_tool) | A tool for collecting and organizing game server IP rules |
| [alecthw/mmdb_china_ip_list](https://github.com/alecthw/mmdb_china_ip_list) | MMDB data source for complete configuration templates and historical overwrite scripts |
| [xishang0128/geoip](https://github.com/xishang0128/geoip) | GeoASN data source for complete configuration templates and historical overwrite scripts |
| [sub-store-org/Sub-Store](https://github.com/sub-store-org/Sub-Store) | Runtime platform for subscription processing scripts |
| [NetEase UU Game Booster](https://uu.163.com/) | A reference source for game network rules |
| [217heidai/adblockfilters](https://github.com/217heidai/adblockfilters) | Data source for archived ad-blocking scripts |
| [privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD) | Data source for archived ad-blocking scripts |
| [TG-Twilight/AWAvenue-Ads-Rule](https://github.com/TG-Twilight/AWAvenue-Ads-Rule) | Data source for archived ad-blocking scripts |
| [Aethersailor/adblockfilters-modified](https://github.com/Aethersailor/adblockfilters-modified) | Data source for archived ad-blocking scripts |
| [521xueweihan/GitHub520](https://github.com/521xueweihan/GitHub520) | Data source for archived scripts that accelerated access to GitHub |
| [TraderWukong/demo](https://github.com/TraderWukong/demo) | A reference retained from the project's early days |
| [ddgksf2013/ddgksf2013](https://github.com/ddgksf2013/ddgksf2013) | A reference retained from the project's early days |
| [immortalwrt/user-FAQ](https://github.com/immortalwrt/user-FAQ/) | A historical reference for the IPv6 documentation |

</details>

“Historical” or “archived” means the related material is no longer actively maintained or recommended. It remains listed to document its source.

---

## 📝 License

[![CC BY-SA 4.0 License](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/)

### CC BY-SA 4.0

Original material that the project has the right to license is available under the [Creative Commons Attribution-ShareAlike 4.0 International license](https://creativecommons.org/licenses/by-sa/4.0/). Subject to the license terms, you may copy, distribute, modify, and use it for any purpose, including commercial use. You must give appropriate credit, indicate any changes, and share adapted material under the same terms. Do not impose additional terms or technological measures that restrict others from exercising their rights under the license. The project adds no platform, purpose, time, or noncommercial restrictions beyond the license terms.

This summary is for convenience. Refer to the [official CC BY-SA 4.0 legal code](https://creativecommons.org/licenses/by-sa/4.0/legalcode.en) for the license terms.

Third-party projects, rules, data, images, tools, trademarks, and submodules retain their own licenses, terms of use, and other rights restrictions when included in this repository. Check the file notices, source links, and upstream licenses before referencing, modifying, or distributing them.

---

## ⭐ Star History

<a href="https://www.star-history.com/?type=date&repos=Aethersailor%2FCustom_OpenClash_Rules">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&theme=dark&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
    <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
    <img alt="Star History Chart" src="https://api.star-history.com/chart?repos=Aethersailor/Custom_OpenClash_Rules&type=date&legend=top-left&sealed_token=KgyG45jTJUPgFZV5k7dmTUTfLIaXaAF26vhZeTaPSFKCmZPtkd_hgbiZfQW8vpJOPWaaWn6VIJ3OJ0ILrsaYU4MyTPP7dilAo2uO6_Bylsyc4h25_Mc9og" />
  </picture>
</a>

## 📊 Repository Activity

![Repository activity](https://repobeats.axiom.co/api/embed/0d7d55da94670a4766aa0fb8ccd03c7abc9e8464.svg "Repobeats analytics image")
