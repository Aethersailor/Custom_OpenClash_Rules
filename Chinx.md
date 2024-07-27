<h1 align="center">OpenClash 保姆级设置教程<br>&<br>个人自用全分组订阅转换模板</h1>

<p align="center">
   <img src="https://img.shields.io/github/stars/Aethersailor/Custom_OpenClash_Rules?style=for-the-badge&logo=github" alt="GitHub stars">
</p>


## 关于本仓库 
可能是目前全网最强的 [OpenClash](https://github.com/vernesong/OpenClash) 保姆级图文教程和订阅转换模板，秒杀一切教程贴！  
终结所有错误设置！让稀奇古怪的套娃设置方法见鬼去吧！  

手把手嘴对嘴指导你将 OpenClash 设置为效率、安全和便利三者兼顾的完美状态，零基础小白也能轻松看懂。  
按照本仓库 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的教程，搭配本仓库的[订阅模板](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini)对 OpenClash 进行设置，仅依靠 OpenClash 自身，无需套娃其他工具，即可实现快速、无污染、无泄漏的 DNS 解析以及完善多样的分流功能，同时配合 Dnsmasq 可实现无第三方插件的广告拦截，并且完美兼容 IPv6。  

欢迎 star ！  

## 更新  
2024.7.7  
修改完善教程。  
“Meta 设置”页面的设置有所改变，建议对照教程进行修改。  

2024.6.19  
教程中上传了一处错误图片，已修正。  
配置订阅 > 配置文件订阅信息中，请务必停用“使用规则集”功能！  

## 本仓库教程及订阅转换模板介绍
本仓库的订阅转换模板是在 [ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) 规则的订阅模板基础上进行了魔改和完善。
以下特性涉及的设置需要按照本仓库 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的教程对 OpenClash 进行配置才可以实现：  
* 基于 ACL4SSR_Online_Full 全分组规则魔改，将部分规则碎片替换成 [blackmatrix7](https://github.com/blackmatrix7/ios_rule_script) 的规则文件，域名分流信息极为全面，增加更多策略组，覆盖大多数日常使用环境，无需自己折腾；  
* 支持节点按地区分类测速优选；  
* 媒体服务（Youtube、Netflix、Disney+ 等）走指定区域测速选优或指定节点，特定网站（电报、ChatGPT 等）走指定区域节点测速选优或指定节点；  
* 单独列出 Steam 规则并强制 Steam 下载 CDN 走直连，解决 Steam 下载 CDN 定位到国外的问题，确保 Steam 下载流量不走代理；  
* 采用大陆白名单机制分流（包括域名、IPv4 地址和 IPv6 地址），无需配合其他工具即可杜绝 DNS 污染和泄漏；  
* 国内域名和 IP 绕过 Clash 内核，提升访问速度和下载性能，并采用运营商 DNS 解析取得最佳解析结果；
* 国外域名和 IP 使用远端节点服务器的 DNS 进行解析，取得最佳解析结果；  
* 国内域名返回真实 IP，国外域名返回 Fake-IP；
* 增加若干冷门域名规则（互动对战平台、猫眼浏览器、蓝点网、EA Desktop 下载 CDN 等），绝无副作用。具体内容详见 Rule\Custom_Direct.list 文件）;  
* 无需手搓配置，每日定时自动更新上游规则，一次设置即可长期无人值守，无需反复折腾；  
* 增加更多的节点区域分组（英国、加拿大等）；    
* 尽力实现海外下载流量强制直连（相关规则完善中）；  

## 使用方法  
准备好你的订阅链接，然后按照本仓库 [Wiki 中的图文教程](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置教程)对 OpenClash 进行设置程，教程中已包括了本仓库订阅转换模板的使用方法：  
https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置教程  
教程非常详尽，只需按部就班设置即可，有手就行！  

此处也提供本仓库订阅模板的单独下载地址：  
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini  
请注意，如果不按照本仓库教程使用，无法保证最终效果，不建议单独使用订阅模板。  

## 关于个性化需求  
如果你需要个性化的模板需求，有两用办法可以实现。  
* fork 本仓库后自行修改添加  
* 用 OpenClash 的“规则附加”功能进行附加  
具体的规则碎片可以在 [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) 中自行寻找  

## 关于 DNS 泄露  
配合上述订阅转换模板和教程正确设置 OpenClash 后，大陆域名将使用国内 DNS 进行解析，默认为运营商DNS，亦可自行设置其他国内 DNS，且大陆域名绕过 Clash 内核，可以返回真实 IP  
国外域名自动通过节点远端默认 DNS 解析，一般为机场默认的 DNS 或者你在 VPS 中设置的 DNS。  

理论上，以上设置可以取得最快、最佳的解析结果，且无污染、无泄露，DNS 完美分流，无需借助其他工具。  

## 关于广告拦截  
由于放弃了套娃其他工具，且大陆域名绕过了 Clash 内核，因此去广告功能只能通过 Dnsmasq 的 hosts 文件来实现。详情参见本人另一个仓库 [AutoUpdateHosts](https://github.com/Aethersailor/OpenWrt-AutoUpdateHosts)  
该仓库内提供了一键安装脚本，实现每日自动下载去广告 hosts 文件并合并至本机 hosts 文件的功能，可与本仓库搭配使用。  

## 关于 IPv6  
谁说 OpenClash 不能和 IPv6 同时工作？  
通过正确设置 OpenWrt 的 IPv6 功能以及 OpenClash，即可实现 IPv6 和 OpenClash 的完美兼容。在实现 IPv6 国内外分流代理的同时，还能通过 IPv6-Test 的国内和国外镜像站点测试。  

IPv6 设置教程见本仓库的 Wiki：  
https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenWrt-IPv6-设置教程  

## 已知问题  
目前本仓库订阅模板对 BT 和 PT 流量的处理依托上游规则碎片完成，可能有不足之处，逐渐完善中  
有其他问题请发 Issue  

## 控制面板效果截图  
历史截图，可能和当前版本不一致，仅供示意  
![](https://github.com/Aethersailor/Custom_OpenClash_Rules/blob/main/doc/openclash/pics/db2.png)  
## 机场推荐 
### SSRDOG  

本人常年使用的一家机场，价格和流量都比较适中，搭配本仓库的订阅模板使用，体验保证拉满。

- 节点覆盖地区全面，全 IEPL 线路不过墙，低延迟稳定流畅。
- 流媒体和 ChatGPT 全解锁，高峰时期油管 8K 视频秒开无压力。
- 支持游戏加速和 IPv6 出站。
- 工单支持简体中文沟通且客服反应迅速。  

注册链接：[SSRDOG 注册](https://dog1.ssrdog111.com/#/register?code=FnSb4oWM)  

本仓库订阅模板的节点地区分类即参考了该机场的节点地区进行分类。  

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
