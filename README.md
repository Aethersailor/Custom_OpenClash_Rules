<h1 align="center">
  🚀 OpenClash Configuration Guide
</h1>

<p align="center"><b>🛡️ Traffic Routing Rules and DNS Leak-Prevention Templates</b></p>

<p align="center">
  <b>English</b>
  &nbsp;|&nbsp;
  <a href="DO_NOT_README.md">简体中文</a>
</p>

<p align="center">
  <a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki">📖 Configuration Wiki (Chinese)</a>
  &nbsp;•&nbsp;
  <a href="https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini">🧩 Subscription Conversion Template</a>
</p>

<p align="center">
 <img alt="GitHub Repo stars" src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=flat">
 <img alt="GitHub contributors" src="https://img.shields.io/github/contributors-anon/Aethersailor/Custom_OpenClash_Rules?style=flat">
 <img alt="GitHub commit activity" src="https://img.shields.io/github/commit-activity/t/Aethersailor/Custom_OpenClash_Rules?style=flat">
 <img alt="OpenClash" src="https://img.shields.io/badge/OpenClash-integrated-brightgreen?style=flat">
 <img alt="Website" src="https://img.shields.io/website?url=https%3A%2F%2Fapi.asailor.org%2Fversion&up_message=online&down_message=offline&style=flat&label=backend">
</p>
<p align="center"><b>✨ A More Elegant Way to Use OpenClash ✨</b></p>

---

<p align="center">
  <a href="#-about-this-project">📖 About</a>
  &nbsp;•&nbsp;
  <a href="#%EF%B8%8F-special-disclaimer">⚠️ Disclaimer</a>
  &nbsp;•&nbsp;
  <a href="#-configuration-guide-and-subscription-conversion-templates">📝 Features</a>
  &nbsp;•&nbsp;
  <a href="#%EF%B8%8F-how-to-use">🛠️ Usage</a>
  &nbsp;•&nbsp;
  <a href="#-additional-notes">💡 Notes</a>
  &nbsp;•&nbsp;
  <a href="#-contributors">🤝 Contributors</a>
  &nbsp;•&nbsp;
  <a href="#-acknowledgements">🙏 Thanks</a>
  &nbsp;•&nbsp;
  <a href="#-license">📝 License</a>
</p>

---

## 📖 About This Project

> ⭐ **This project provides an illustrated configuration guide and example rules/templates for [OpenClash](https://github.com/vernesong/OpenClash).**

This project brings together a reusable configuration approach and practical examples while avoiding unnecessary layers of nested configuration wherever possible.

[OpenClash](https://github.com/vernesong/OpenClash) is a commonly used OpenWrt plugin for rule-based network traffic routing and outbound policies. It can process traffic according to rules and work with DNS policies to reduce the risk of DNS leaks.

This project demonstrates how to configure OpenClash for more stable and maintainable transparent traffic routing, with an emphasis on DNS leak prevention, rule-based routing, and everyday usability—without requiring additional plugins.

> 🧩 **Say goodbye to tedious hand-written configurations and stacks of nested plugins. The guide is designed to be easy to follow even for complete beginners.**

By following the configuration guide in this project's [Wiki (Chinese)](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) and using the project's [subscription conversion template](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini), you can configure OpenClash in just a few minutes. Without stacking it with other tools, OpenClash alone can provide more robust DNS policies and traffic routing while remaining fully compatible with IPv6. The project previously provided a Dnsmasq-based ad-blocking example, but that feature is currently disabled; see the notice below for details.

The project also provides configuration examples based on OpenClash's remote override feature.

Stars ⭐ are welcome!

> [!NOTE]
> The project Wiki is currently available in Chinese only. All English README links to the Wiki intentionally open the existing Chinese documentation.

---

> [!NOTE]
> **Statement:**
>
> - This project was created in April 2024 as a non-profit collection of technical research and practical experience.
> - **The content reflects only the maintainer's personal experience and is intended for technical exchange. It is not authoritative and does not represent the only or officially recommended way to use OpenClash.**
> - **This project does not operate any YouTube channel and has not published tutorials or instructional videos of any kind on YouTube or any other video platform.**
> - **This project's content was not compiled or adapted from third-party tutorials or videos. If you encounter problems after using tutorials, templates, or configuration files from other sources, please do not report them in this project's Issues or Discussions.**
> - **Some parts of this project may be written in relatively accessible language, but this does not constitute a commitment to teach, guide, or support any particular group of users, nor is the maintainer obligated to provide such assistance.**

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

---

## 📝 Configuration Guide and Subscription Conversion Templates

This project's configuration templates were refined with reference to rule templates such as [ACL4SSR](https://github.com/ACL4SSR/ACL4SSR/tree/master). Traffic-routing data is based on GeoSite.

**Configure OpenClash by following the guide in this project's [Wiki (Chinese)](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) and using the project's subscription conversion templates. You will gain the following features for a more elegant OpenClash experience:**

- 🚀 **Optimized DNS settings that minimize the impact on direct connections**
  > Domains and IP addresses in the selected region (CN in this example) are resolved through the ISP's DNS servers, bypass the OpenClash core, and return their real IP addresses, minimizing OpenClash's impact on direct access.

- 🛡️ **Reduced risk of DNS resolution failures and leaks, with no additional plugins required**
  > For destinations not routed directly, DNS resolution and access can be handled by the selected outbound according to routing rules, with accompanying policies reducing the risk of leaks.

- 🧩 **No more nested configurations**
  > Avoid the complexity of combining multiple DNS plugins. All features are implemented through OpenClash alone, and direct-access sites remain reachable even if OpenClash stops working.

- 🖱️ **Beginner-friendly setup**
  > The entire process is completed in the OpenClash interface. A few minutes of clicking, copying, and pasting are all that is required—no manual configuration authoring and no file uploads.

- 🗂️ **A rich selection of traffic-routing policy groups**
  > Multiple rule templates provide traffic-routing policy groups for common applications and services, including media, AI tools, e-commerce, and gaming platforms. Simplified rule variants are also available.

- ⚡ **Traffic routing with automatic latency-based selection**
  > Automatically selects low-latency outbound options, reducing the need for manual switching.

- 🎮 **Optimized Steam access**
  > Steam download traffic is routed separately from other Steam traffic, allowing downloads to remain on a direct connection even when Steam login traffic uses a proxy.

- 🔄 **Automatic updates for long-term unattended operation**
  > Once configured, the system can run unattended over the long term. Time-sensitive data—including upstream rule and GEO databases and direct-connection allowlists—is updated automatically on a daily schedule.

- 🌍 **Optimized high-volume downloads**
  > Provides routing controls for non-standard ports to help prevent high-volume downloads from using non-direct outbound connections. Download-traffic optimization options reduce unnecessary outbound traffic consumption.

- ~~🚫 **Ad blocking and hosts-based acceleration**~~ *(temporarily disabled)*
  > ~~Uses OpenClash together with the system's built-in Dnsmasq to provide ad filtering and hosts-based acceleration, with automatic daily updates and support for multiple rule lists. (Optional)~~

- 🧩 **Handling for less common direct-access domains**
  > Adds direct-connection rules for selected niche websites. The maintainer periodically submits collected domains to upstream rule projects based on user feedback.

---

## 🛠️ How to Use

> [!IMPORTANT]
> **Important:**
>
> - This project's configuration guide uses OpenClash's `Fake-IP` mode and does not apply to Redir-Host mode.
> - The intended behavior depends on OpenClash's “Bypass Mainland China” feature.

Configure OpenClash by following the relevant section of the project Wiki: [OpenClash Configuration Guide (Chinese)](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置方案)

The guide includes instructions for using this project's subscription conversion templates. Select the rule template you need as described.

The guide is highly detailed; simply follow each step in order. Every setting is configured through OpenClash's LuCI interface.

If you need remote override configuration files, refer to [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite).

> [!TIP]
> **📝 Reading Recommendation:**
>
> The configuration guide is lengthy, so read it carefully, word by word. Skipping material may cause you to miss a critical step and encounter problems. The guide also explains the principles behind many settings to help beginners understand and learn.

---

## 💡 Additional Notes

### 🎨 Customization Requests

> [!NOTE]
> This project was created for the maintainer's own use, and personal time is limited. Updates are therefore made when time permits, and customized modification services are not provided.

For implementation details concerning customization, refer to the corresponding Wiki section: [Customization Requests (Chinese)](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E5%85%B6%E4%BB%96%E8%AF%B4%E6%98%8E#%E5%85%B3%E4%BA%8E%E4%B8%AA%E6%80%A7%E5%8C%96%E9%9C%80%E6%B1%82)

### 🈸 Adding Less Common Direct-Access Domains

If you need to add a small number of uncommon domains that should use a direct connection, we recommend inserting the relevant entries through OpenClash's custom-rules feature.

If you would like a small number of direct-access domains to be included in the repository's rules, submit and discuss them through a GitHub Issue or pull request.

You may also visit [COCR RULE BOT](https://telegram.me/asailor_rulebot) and add domains by following its prompts. Domains that meet the requirements will automatically be added to this project's direct-connection rules.

> [!NOTE]
> The maintainer periodically submits collected less common direct-access domains to upstream rule projects through pull requests.

---

### ~~🚫 Ad Filtering~~

<details>
<summary>Click to view the deprecated ad-filtering instructions</summary>

> **2025-07-22**: This feature has been found to potentially cause Dnsmasq failures. Please keep it disabled for now.

~~This project uses OpenClash's “Developer Options” feature to implement ad filtering without relying on third-party plugins.~~

~~For configuration details, see the Wiki guide: [Ad-Blocking Configuration Guide (Chinese)](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%97%A0%E6%8F%92%E4%BB%B6%E5%B9%BF%E5%91%8A%E6%8B%A6%E6%88%AA%E5%8A%9F%E8%83%BD%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)~~

~~The guide provides examples for both Dnsmasq-format and hosts-format configurations. You may copy them directly or use any other ad-filtering rules that meet the relevant format requirements.~~

</details>

---

### 🌐 IPv6

By configuring IPv6 in OpenWrt and OpenClash correctly, you can achieve better compatibility between IPv6 and OpenClash when OpenWrt is used as the main router, while supporting traffic routing and connectivity tests in IPv6 environments.

See this project's Wiki for the OpenWrt IPv6 configuration guide: [OpenWrt IPv6 Configuration Guide (Chinese)](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenWrt-IPv6-设置方案)

---

### ❓ No Internet Access? Incorrect Traffic Routing? Some Websites Do Not Open? OpenClash Does Not Start?

If you encounter a problem, refer to the [Troubleshooting section of the Wiki (Chinese)](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4), which provides solutions to common issues.

> [!TIP]
> 🛠️ This project's configuration guide has been validated by many users and generally has no structural issues. To avoid wasting time, we recommend looking elsewhere first when diagnosing problems. Issues affecting particular applications or services may involve many factors and are not necessarily related to the templates themselves.

---

### 💻 Other Environments

This repository discusses only OpenWrt/OpenClash environments. For other clients or operating systems, consult the documentation of the relevant projects.

---

## 🤝 Contributors

<a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Aethersailor/Custom_OpenClash_Rules&anon=1&max=100" alt="Contributors" />
</a>

---

## 🙏 Acknowledgements

**This project uses or references the following:**

Listed in no particular order.

### 🔌 Plugin

- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)

### 🧩 Cores

- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [vernesong/mihomo](https://github.com/vernesong/mihomo)

### 🗂 Configuration Templates

- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)

### ⚙️ Remote Override Configuration

- [Giveupmoon/OpenClash_Overwrite](https://github.com/Giveupmoon/OpenClash_Overwrite)

### 🛣 Traffic-Routing Rules

- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [v2fly/domain-list-community](https://github.com/v2fly/domain-list-community)
- [felixonmars/dnsmasq-china-list](https://github.com/felixonmars/dnsmasq-china-list)
- [Loyalsoldier/v2ray-rules-dat](https://github.com/Loyalsoldier/v2ray-rules-dat)
- [dogfight360/UsbEAm](https://www.dogfight360.com/blog/18627/)
- [ddgksf2013/ddgksf2013](https://github.com/ddgksf2013/ddgksf2013)
- [mottzz87/crules](https://github.com/mottzz87/crules)

### 🚫 Ad-Filtering Rules

- [217heidai/adblockfilters](https://github.com/217heidai/adblockfilters)
- [privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD)
- [TG-Twilight/AWAvenue-Ads-Rule](https://github.com/TG-Twilight/AWAvenue-Ads-Rule)
- [Aethersailor/adblockfilters-modified](https://github.com/Aethersailor/adblockfilters-modified)

### ⚡ Acceleration Rules

- [521xueweihan/GitHub520](https://github.com/521xueweihan/GitHub520)

### 🔄 Subscription Conversion Backends

- [Aethersailor/SubConverter-Extended](https://github.com/Aethersailor/SubConverter-Extended)
- [Aethersailor/subconverter](https://github.com/Aethersailor/subconverter)

### 🧰 Tools

- [Aethersailor/Rule-Bot](https://github.com/Aethersailor/Rule-Bot)
- [oooldtoy/SSTAP_ip_crawl_tool](https://github.com/oooldtoy/SSTAP_ip_crawl_tool)

### 🔖 Other

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
