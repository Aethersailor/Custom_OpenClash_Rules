<h1 align="center">OpenClash 保姆级设置方案<br>&<br>全分组防泄漏订阅转换模板</h1>

<p align="center">
	<img src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=for-the-badge&logo=github" alt="GitHub stars">
	<a href="https://t.me/custom_openclash_rules">
		<img src="http://img.shields.io/badge/dynamic/json?style=for-the-badge&label=%E9%A2%91%E9%81%93&logo=telegram&query=$.data.totalSubs&url=https%3A%2F%2Fapi.spencerwoo.com%2Fsubstats%2F%3Fsource%3Dtelegram%26queryKey%3Dcustom_openclash_rules" alt="Telegram">
	</a>
	<a href="https://t.me/custom_openclash_rules_group">
		<img src="https://img.shields.io/badge/dynamic/json?style=for-the-badge&label=%E7%BE%A4%E8%81%8A&logo=telegram&query=$.data.totalSubs&url=https%3A%2F%2Fapi.spencerwoo.com%2Fsubstats%2F%3Fsource%3Dtelegram%26queryKey%3Dcustom_openclash_rules_group" alt="Telegram">
	</a>
</p>
<p align="center"><b>让你更优雅的使用 OpenClash </b></p>

## 关于本项目 
本项目可能是目前全网最强的 [OpenClash](https://github.com/vernesong/OpenClash) 保姆级图文设置方案和订阅转换模板！  
终结所有错误设置！让稀奇古怪的套娃设置方法见鬼去吧！  

OpenClash 无疑是 OpenWrt 中最强大的科学上网软件，它可以实现最完美的透明代理效果。

本项目以中华人民共和国境内的网络环境为参考，示例如何将 OpenClash 插件设置为无感、快速、安全和省心三者兼顾的完美状态，从而达到极致优雅的科学上网体验。
彻底告别手搓配置和多个插件套娃的繁琐设置方法，保证零基础小白也能轻松看懂。  
按照本项目的 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的设置方案，搭配本项目的[订阅转换模板](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini)对 OpenClash 进行设置，仅依靠 OpenClash 自身，无需套娃其他工具，即可实现快速、无污染、无泄漏的 DNS 解析以及完善多样的分流功能，同时配合 Dnsmasq 可实现无需第三方插件的广告拦截，并且完美兼容 IPv6。  

欢迎 star ！

本项目编写于2024年4月，为非盈利项目。  
某些 Youtube 作者转载本项目内容请注明本项目的仓库地址，感谢合作！

## 特别声明  
1. 本项目的主要目的是探索与学习 OpenWrt 系统插件 OpenClash，因此无法确保所有内容的合法性、完整性、准确性或有效性。
2. 项目中的内容仅用于学习与研究目的，不得将其用于任何可能违反国家、地区或组织法律法规的用途。
3. 任何直接或间接使用本项目的个人或组织，应在24小时内完成学习与研究，随后删除所有相关内容。
4. 使用本项目内容进行的任何更改，均为其他个人或组织的行为，与本项目及其维护者无关，因其修改导致的任何后果由相关责任方承担。
5. 本项目允许对项目内容进行任何形式的转载和二次创作，包括但不限于文章、视频等形式，转载时务必注明本项目的地址，但不得将相关内容转载于中华人民共和国境内的任何互联网平台之上。
6. 本项目保留随时补充或修改免责声明的权利，凡使用本项目内容的个人或组织，均视为已接受此声明。  

## 本项目设置方案及订阅转换模板介绍
本项目的订阅转换模板是参考 [ACL4SSR](https://github.com/ACL4SSR/ACL4SSR/tree/master) 等规则的订阅模板进行了魔改和完善而来。  

**按照本项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的设置方案，配合本项目的订阅转换模板对 OpenClash 进行配置，即可实现以下特性，更优雅的使用你的 OpenClash：** 
* **优化的 DNS 设置，闪电般的国内访问速度。**  国内域名采用运营商 DNS 解析，域名和 IP 均绕过 OpenClash 内核并返回真实 IP，让 OpenClash 对国内访问的影响降低到几乎为零。
* **杜绝 DNS 污染和泄露，无需搭配其他插件。**  海外域名采用使用远端节点服务器的 DNS 进行解析并访问，确保隐私的同时取得最佳解析结果。
* **彻底告别套娃设置。**  免去各种 DNS 插件带来的搭配烦恼，全部特性依靠 OpenClash 一个插件实现，且保证 OpenClash 即使挂了也不影响访问国内网站。  
* **傻瓜化的设置操作。**  鼠标点击+复制粘贴几分钟即可完成完美设置，无需手搓配置。  
* **丰富的分流策略组。**  包含流媒体服务、AI 工具、电商、游戏平台等在内的大量常见的分流策略组。 
* **支持节点按地区分类测速优选。**  自动优选最快节点，不用自己折腾切换。  
* **Steam 访问优化。**  单独列出 Steam 规则并强制 Steam 下载 CDN 走直连，解决 Steam 下载 CDN 定位到海外的问题，确保 Steam 下载流量不走代理。  
* **一次设置，长期无人值守。**  每日定时自动更新上游规则和 GEO 数据库、大陆白名单等具有时效性要求的数据，无需自己动手。    
* **海外下载流量优化。**  尽力避免海外下载流量走节点，节约节点流量。（尚不完善）。  
* **支持广告屏蔽功能和 hosts 加速。**  依靠 OpenClash 配合系统自带 Dnsmasq 实现广告过滤和 hosts 加速功能，并实现每日自动更新，支持添加多个规则。（可选）
* **增加更多的节点区域分组。**  增加包括英国、加拿大等国家的节点分组。
* **增加若干冷门域名规则。**  增加了一些小众网站的直连规则，可以自己 PR 提交域名参与完善规则。  

## 使用方法  
准备好你的订阅链接，然后按照本项目 Wiki 中的对应部分对 OpenClash 进行设置：[OpenClash-设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置方案)  
方案中已包括了本项目订阅转换模板的使用方法。  
以上方案非常详尽，只需按部就班设置即可。全部设置内容均基于 OpenClash 的 luci 设置页面，有手就行！  
设置方案文字较多，务必逐字逐句认真阅读，不要忽略以防漏掉关键部分导致故障。且方案内含多处设置的讲解便于理解相关设置原理，有助于小白学习。  

## 关于个性化需求  
由于本项目为自用目的，且个人时间有限，只能随缘更新，因此不提供个性化修改服务。  
具体个性化实现方式，请参考 Wiki 中的对应章节：[个性化需求](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E5%85%B6%E4%BB%96%E8%AF%B4%E6%98%8E#%E5%85%B3%E4%BA%8E%E4%B8%AA%E6%80%A7%E5%8C%96%E9%9C%80%E6%B1%82)

## 关于冷门国内域名收录问题
如果遇到缺失的冷门国内域名，参考 Wiki 对应章节：[关于国内冷门域名的收录](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E5%85%B6%E4%BB%96%E8%AF%B4%E6%98%8E#%E5%85%B3%E4%BA%8E%E5%86%B7%E9%97%A8%E5%9B%BD%E5%86%85%E5%9F%9F%E5%90%8D%E7%9A%84%E6%94%B6%E5%BD%95)

## 关于广告过滤  
本项目借助 OpenClash 的“开发者选项”功能，实现不依赖第三方插件的广告过滤功能。  
具体设置见 Wiki 中的方案：[广告拦截设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%97%A0%E6%8F%92%E4%BB%B6%E5%B9%BF%E5%91%8A%E6%8B%A6%E6%88%AA%E5%8A%9F%E8%83%BD%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)  
其中提供了 Dnsmasq 格式和 hosts 格式的两种设置方法的示例，可以照抄，亦可自由设置其他任何符合格式要求的广告规则。

## 关于 IPv6  
谁说 OpenClash 不能和 IPv6 同时工作？  
通过正确设置 OpenWrt 的 IPv6 功能以及 OpenClash，即可实现 IPv6 和 OpenClash 的完美兼容。在实现 IPv6 国内外分流代理的同时，还能完美通过 IPv6-Test 的国内和国外镜像站点测试。  

OpenWrt 的 IPv6 设置方案见本项目的 Wiki：[OpenWrt-IPv6-设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenWrt-IPv6-设置方案)  

## 已知问题  
目前本项目订阅模板对 BT 和 PT 流量的处理依托上游规则碎片和关键词以及 OpenClash 自带的功能完成，仍然有不足之处，逐渐完善中。  
具体解释见 [Wiki 对应内容](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4#5-bt-%E5%92%8C-pt-%E7%AD%89%E4%B8%8B%E8%BD%BD%E6%B5%81%E9%87%8F%E5%88%86%E6%B5%81%E4%B8%8D%E5%AE%8C%E5%96%84)。

## 不能上网？分流不正常？某些网站打不开？OpenClash 不能启动？
出现故障请参考 [Wiki 中的故障排除部分](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%95%85%E9%9A%9C%E6%8E%92%E9%99%A4)，内含常见问题的解决方法。  
项目维护者可以确定，本项目的设置方案完美无瑕，建议不要从本项目的内容上找原因，以免浪费时间。某些特殊问题如 Google Play 更新问题涉及诸多原因，和模板本身并无关系。  

## 在 OpenClash 之外的其他软件中是否可用？  
理论上本项目的订阅转换模板是通用的，可以在任何 Clash 客户端下使用（例如 Stash）。  
但是不建议在移动端设备上使用。由于规则过于复杂会导致移动设备耗电急剧增加，甚至影响上网体验。  

适用于 iOS 下 Shadowrocket 的规则：https://github.com/Aethersailor/Custom_Shadowrocket_Rules  
测试状态，尚不完善  


## 机场推荐 
### SSRDOG  

本人常年使用的一家机场，价格和流量都比较适中，搭配本项目的设置方案以及订阅模板使用，体验保证拉满。

- 全 IEPL 线路不过墙，特殊时期服务稳定
- 低延迟大带宽，高峰时期油管 8K 视频秒开无压力
- 节点覆盖地区全面，包含港台美日新欧等主流地区
- 解锁 Netflix、Disney+、YouTube、TikTok、Spotify 等主流流媒体服务
- 解锁 ChatGPT 
- 支持 UDP 转发和游戏加速，部分节点支持 FullCone 全锥形 NAT
- 支持 IPv6 出站
- 支持试用
- 工单支持简体中文沟通且客服反应迅速

注册链接：[SSRDOG 注册](https://dog1.ssrdog111.com/#/register?code=FnSb4oWM)  (链接包含 aff 信息，感谢支持！)

本项目订阅模板的节点地区分类即参考了该机场的节点地区进行分类。  

PS：该机场 Hong Kong 11-15 节点暂不支持 IPv6 出站，如果需要使用 IPv6 出站功能，建议在 订阅设置 > 排除节点中设置排除如下关键词，以避免使用非 IPv6 出站节点：  
Traffic、GB、Expire、11、12、13、14、15  

若不使用 IPv6 功能，建议只需屏蔽如下节点关键词：  
Traffic、GB、Expire  
不屏蔽不影响使用，只是会让节点列表看着更整洁一些  

## 控制面板效果截图  
历史截图，可能和当前版本不一致，仅供示意  
![](https://github.com/Aethersailor/Custom_OpenClash_Rules/blob/main/doc/openclash/pics/db2.png)  

## 贡献者  
<a href="https://github.com/Aethersailor/Custom_OpenClash_Rules/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=Aethersailor/Custom_OpenClash_Rules" />
</a>  

## 感谢  
以下排名不分先后  
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)
- [dogfight360/UsbEAm](https://github.com/dogfight360/UsbEAm)  

## 许可		
[![](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.zh)
* CC-BY-SA-4.0  
**谴责所有不遵循 LICENSE 的搬运行为。** 

## 星标记录

<a href="https://star-history.com/#Aethersailor/Custom_OpenClash_Rules&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Aethersailor/Custom_OpenClash_Rules&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Aethersailor/Custom_OpenClash_Rules&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Aethersailor/Custom_OpenClash_Rules&type=Date" />
 </picture>
</a>
