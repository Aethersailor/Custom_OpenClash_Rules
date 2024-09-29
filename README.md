<h1 align="center">OpenClash 保姆级设置教程<br>&<br>全分组防泄漏订阅转换模板</h1>

<p align="center">
   <img src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=for-the-badge&logo=github" alt="GitHub stars">
</p>


## 关于本仓库 
可能是目前全网最强的 [OpenClash](https://github.com/vernesong/OpenClash) 保姆级图文教程和订阅转换模板，秒杀一切教程贴！  
终结所有错误设置！让稀奇古怪的套娃设置方法见鬼去吧！  

手把手嘴对嘴指导你将 OpenClash 设置为效率、安全和便利三者兼顾的完美状态，零基础小白也能轻松看懂。  
按照本仓库 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的教程，搭配本仓库的[订阅模板](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini)对 OpenClash 进行设置，仅依靠 OpenClash 自身，无需套娃其他工具，即可实现快速、无污染、无泄漏的 DNS 解析以及完善多样的分流功能，同时配合 Dnsmasq 可实现无第三方插件的广告拦截，并且完美兼容 IPv6。  

欢迎 star ！转载请注明出处，感谢！

## 更新  
本仓库模板包含的规则均为引用的上游规则碎片，上游规则更新与本仓库模板的更新没有直接关系，只需根据教程设置每日更新订阅即可每日自动获取最新规则。  

2024.9.29  
完善教程中广告拦截设置的部分。  

2024.9.27  
完善教程，更新部分教程图片。现在建议启用“使用规则集”功能。（感谢 [bdingtech](https://github.com/bdingtech) 的建议）    

2024.9.15  
根据 OpenClash v0.46.029-beta 的界面改动，更新部分教程图片。  

2024.9.7  
根据 OpenClash v0.46.024-beta 的界面改动，更新部分教程图片。  

2024.8.9  
更新 Steam 下载 CDN 规则。  

2024.7.28  
换用新的广告拦截设置方法，现在使用 OpenClash 的开发者选项来实现广告屏蔽功能，大幅提升便利性。  
增加“开发者选项”一键修改脚本，方便小白操作。  

2024.7.7  
修改完善教程。  
“Meta 设置”页面的设置有所改变，建议对照教程进行修改。  

2024.6.19  
教程中上传了一处错误图片，已修正。  
配置订阅 > 配置文件订阅信息中，请务必停用“使用规则集”功能！  

## 本仓库教程及订阅转换模板介绍
本仓库的订阅转换模板是在 [ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) 规则的订阅模板基础上进行了魔改和完善。
以下特性涉及的设置需要按照本仓库 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的教程对 OpenClash 进行配置才可以实现：  
* 无需搭配其他插件，实现 DNS 防泄露；  
* 基于 ACL4SSR_Online_Full 全分组规则魔改，将大部分规则碎片替换成 [blackmatrix7](https://github.com/blackmatrix7/ios_rule_script) 的规则文件，域名分流信息极为全面，增加更多策略组，覆盖大多数日常使用环境，无需自己折腾；  
* 支持节点按地区分类测速优选；  
* 媒体服务（Youtube、Netflix、Disney+ 等）走指定区域测速选优或指定节点，特定网站（电报、ChatGPT 等）走指定区域节点测速选优或指定节点；  
* 单独列出 Steam 规则并强制 Steam 下载 CDN 走直连，解决 Steam 下载 CDN 定位到国外的问题，确保 Steam 下载流量不走代理；  
* 国内域名和 IP 绕过 Clash 内核，提升访问速度和下载性能，并采用运营商 DNS 解析取得最佳解析结果；
* 国外域名和 IP 使用远端节点服务器的 DNS 进行解析，取得最佳解析结果；  
* 国内域名返回真实 IP，国外域名返回 Fake-IP；
* 增加若干冷门域名规则（互动对战平台、猫眼浏览器、蓝点网、EA Desktop 下载 CDN 等），绝无副作用。具体内容详见 Rule\Custom_Direct.list 文件）;  
* 每日定时自动更新上游规则，一次设置即可长期无人值守，无需反复折腾；  
* 增加更多的节点区域分组（英国、加拿大等）；    
* 尽力实现海外下载流量强制直连（相关规则完善中）；  
* 广告屏蔽功能（可选）  

## 使用方法  
准备好你的订阅链接，然后按照本仓库 [Wiki 中的图文教程](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置教程)对 OpenClash 进行设置程，教程中已包括了本仓库订阅转换模板的使用方法：  
https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置教程  
教程非常详尽，只需按部就班设置即可。全部设置内容均基于 OpenClash 的 luci 设置页面，有手就行！  

此处也提供本仓库订阅模板的单独下载地址：  
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini  
请注意，如果不按照本仓库教程使用，无法保证最终效果，不建议单独使用订阅模板。  

## 关于个性化需求  
由于本仓库为自用目的，且个人时间有限，因此不提供个性化修改服务。  
如果你需要个性化的模板需求，有以下两用办法可以实现：  
* fork 本仓库后自行修改添加  
* 使用 OpenClash 的“规则附加”功能附加你需要的规则  
具体的规则碎片可以在 [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) 中自行寻找。  

## 关于 DNS 泄露  
配合上述订阅转换模板和教程正确设置 OpenClash 后，大陆域名将使用国内 DNS 进行解析，默认为运营商DNS，亦可自行设置其他国内 DNS，且大陆域名绕过 Clash 内核，可以返回真实 IP  
国外域名自动通过节点远端默认 DNS 解析，一般为机场默认的 DNS 或者你在 VPS 中设置的 DNS。  

理论上，以上设置可以取得最快、最佳的解析结果，且无污染、无泄露，DNS 完美分流，无需借助其他工具。  

PS：如果在控制面板中为“漏网之鱼”策略组选择了“全球直连”策略，则不能通过防泄露测试。  

## 关于广告过滤  
由于放弃了套娃其他工具，且大陆域名绕过了 Clash 内核，因此无法依靠 OpenClash 的规则来完成广告过滤，广告过滤功能只能通过 Dnsmasq 来实现。  
借助 OpenClash 的“开发者选项”功能，让 OpenClash 每次启动时为 Dnsmasq 拉取相应的广告过滤规则文件，同时利用 OpenClash 启动时会重启 Dnsmasq 的特性使广告过滤规则生效。  
具体设置见 Wiki 中的教程：[广告拦截设置教程](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/%E6%97%A0%E6%8F%92%E4%BB%B6%E5%B9%BF%E5%91%8A%E6%8B%A6%E6%88%AA%E5%8A%9F%E8%83%BD%E8%AE%BE%E7%BD%AE%E6%95%99%E7%A8%8B)

## 关于 IPv6  
谁说 OpenClash 不能和 IPv6 同时工作？  
通过正确设置 OpenWrt 的 IPv6 功能以及 OpenClash，即可实现 IPv6 和 OpenClash 的完美兼容。在实现 IPv6 国内外分流代理的同时，还能通过 IPv6-Test 的国内和国外镜像站点测试。  

OpenWrt 的 IPv6 设置教程见本仓库的 Wiki：  
https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenWrt-IPv6-设置教程  

## 已知问题  
目前本仓库订阅模板对 BT 和 PT 流量的处理依托上游规则碎片和关键词完成，可能有不足之处，逐渐完善中。  
如果觉得当前的 BT/PT 分流状态不能满足需要，请指定“漏网之鱼”策略组直连，可以解决相关流量走节点的问题。  

## 不能上网？分流不正常？  
如果出现异常情况，请尝试完全还原 OpenClash 设置后重新配置。  
更新 GEOIP 数据库和大陆白名单！更新 GEOIP 数据库和大陆白名单！更新 GEOIP 数据库和大陆白名单！  
重要的事情说三遍，一定要更新，否则 OpenClash 自带的绕过大陆功能会出现问题  

订阅模板只是一个对上游第三方规则的集中引用，模板自身并不会导致分流这个问题。大陆域名和 IP 的分流也是依托引用的大陆白名单和 GEOIP 数据库完成的。  
上游规则、大陆白名单、GEOIP 数据库这些内容和本仓库没有关系，它们导致的分流异常情况请不要向我反馈，我也无法解决。有需要请去上游规则的仓库进行反馈。  
如果百度之类的热门网站出现分流不正常，说明你的 OpenClash 工作不正常，请先更新 GEOIP 数据库和大陆白名单，必要时请还原设置重新配置。  
如果你认为规则出现了分流不正常，自行检索规则相关策略组引用的规则，然后至对应项目的仓库反馈。  

本仓库提供的仅仅是订阅转换模板以及 OpenClash 有关的设置教程，且所有设置操作均基于 OpenClash 的图形界面，没有任何超出常规范围的设置和修改，因此不会导致 OpenWrt 以及 OpenClash 工作异常。  
本人使用的固件是 ImmortalWrt SNAPSHOT 官方编译版本，主路由 PPPOE 拨号环境，本仓库仅能保证在同样固件同样网络条件的情况下正常工作。  
旁路由/二级路由相关设置基于本人对 OpenWrt 以及 OpenClash 的理解而形成，理论上不会导致问题，请自己根据实际情况调整。  

OpenClash 设置以及订阅转换模板具有普适性，按照教程设置后如果有异常，请从教程和模板以外的因素自行查找原因。  
故障原因包括但不限于 OpenClash 自身、Clash 内核自身、订阅转换服务亦或是搭配其他插件、他人编译的固件、老旧的固件版本、OpenWrt 设置错误，以及某些设备内置 DNS 等原因。
以上原因均与本仓库内容无关，请自行排查故障。相关 issue 将被直接关闭，不再予以解答。  

## 机场推荐  
### 求推荐机场  

本人之前自用和推荐的机场，已经关闭了大部分节点的 IPv6 出站功能，强烈谴责这种服务缩水的行为！  

现在欢迎大家推荐一个机场，需要满足以下功能和特性：  

- 节点覆盖地区全面，至少要包含香港、新加坡、美国等主要国家和地区；
- 必须是 IEPL/IPLC 或 BGP 等不过墙线路，敏感时期时期服务稳定的；
- 速度稳定，至少高峰时期油管可播放 8K 视频；
- 支持流媒体（至少包含 Netflix 和 Disney+）的新加坡区解锁
- 支持 ChatGPT 解锁；
- 支持游戏加速（UDP 转发）；
- 支持 IPv6 出站；
- 节点统一速率，无倍率节点；
- 节点命名规则整齐划一；
- 套餐流量 850G 以上；
- 设备数量限制6台以上或无限制；
- 月费用一百元以下；

如有符合以上要求的机场，欢迎推荐。可以将你的推广链接发送到本仓库的讨论区中。  
使用体验不错的话我会把你的推荐链接在 README 此处位置放置三个月。  

## 控制面板效果截图  
历史截图，可能和当前版本不一致，仅供示意  
![](https://github.com/Aethersailor/Custom_OpenClash_Rules/blob/main/doc/openclash/pics/db2.png)  


## 感谢  
以下排名不分先后  
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)
- [dogfight360/UsbEAm](https://github.com/dogfight360/UsbEAm)  

# License		
[![](https://licensebuttons.net/l/by-sa/4.0/88x31.png)](https://creativecommons.org/licenses/by-sa/4.0/deed.zh)
* CC-BY-SA-4.0  

## Star History

<a href="https://star-history.com/#Aethersailor/Custom_OpenClash_Rules&Date">
 <picture>
   <source media="(prefers-color-scheme: dark)" srcset="https://api.star-history.com/svg?repos=Aethersailor/Custom_OpenClash_Rules&type=Date&theme=dark" />
   <source media="(prefers-color-scheme: light)" srcset="https://api.star-history.com/svg?repos=Aethersailor/Custom_OpenClash_Rules&type=Date" />
   <img alt="Star History Chart" src="https://api.star-history.com/svg?repos=Aethersailor/Custom_OpenClash_Rules&type=Date" />
 </picture>
</a>
