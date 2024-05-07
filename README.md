# OpenClash 保姆级设置教程和个人自用 OpenClash 订阅转换模板  
可能是目前全网最强的 [OpenClash](https://github.com/vernesong/OpenClash) 保姆级图文教程，秒杀一切教程贴！  
终结所有错误设置！让稀奇古怪的套娃设置见鬼去吧！  
手把手嘴对嘴教你把 OpenClash 设置为效率、安全、便利三者兼顾的完美状态，零基础小白也能看懂；  
按照本仓库 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 中的教程，搭配本仓库的[订阅模板](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini)对 OpenClash 进行设置，仅依靠 OpenClash 自身，无需套娃其他工具即可实现快速且无污染、无泄漏的 DNS 解析以及多样的分流功能，同时配合 Dnsmasq 实现无第三方插件的广告拦截，并且完美兼容 IPv6      
欢迎批评指正  

## 个人使用需求  
* 媒体服务（Youtube、Netflix、Disney+ 等）走指定节点，特定网站（电报、ChatGPT 等）走指定区域节点测速选优或特定节点  
* 特定网站（苹果服务、微软服务以及国内域名 IP 等）走直连，其他国外网站走指定节点，节点需要按照区域自动测速选优     
* 杜绝 DNS 泄露，且大陆域名和 IP 绕过 OpenClash 内核提升访问速度和下载性能  
* 兼容 IPv6，实现 IPv6 完美分流  
* 广告拦截  
* 定时自动更新上游规则，无人值守

## 订阅转换模板介绍
本仓库的订阅转换模板是在 [ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) 规则的订阅模板的基础上进行了魔改 
* 基于 ACL4SSR_Online_Full 全分组规则魔改，将部分规则碎片替换成 [blackmatrix7](https://github.com/blackmatrix7/ios_rule_script) 的规则文件，增加更多策略组；  
* 单独列出 Steam 规则并强制 Steam 下载 CDN 走直连，解决 Steam 下载 CDN 定位到国外的问题，确保 Steam 下载流量不走代理；     
* 增加更多的节点区域分组（英国、加拿大等）；  
* 调整节点默认优先顺序；  
* 增加个人自用的若干冷门域名规则（互动对战平台、猫眼浏览器等若干小众网站，绝无副作用。具体内容详见 Rule\Custom_Direct.list 文件）;  
* 采用大陆白名单机制分流（包括域名、IPv4 地址和 IPv6 地址），杜绝 DNS 污染和泄漏；   

## 使用方法  
设置教程详见本仓库的 Wiki，只要按照图文进行设置即可。其中已包括了本仓库订阅转换模板的地址：  
https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置教程  
感谢恩山论坛各路大神特别是[悟★空](https://github.com/WukongMaster)大佬的教程贴，让我学习了很多

此处也提供本仓库订阅模板的单独下载地址：  
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini  
不搭配本仓库教程使用的话，不保证最终效果完美  

## 关于广告拦截  
由于放弃了套娃其他工具，且大陆域名绕过了 OpenClash 内核，因此去广告功能只能由 Dnsmasq 的 hosts 文件来实现  
详情见本人另一个仓库 [AutoUpdateHosts](https://github.com/Aethersailor/OpenWrt-AutoUpdateHosts)   
内有一键安装脚本，可实现每日自动下载去广告 hosts 文件并合并至本机 hosts 文件的功能  

## 关于 DNS 泄露  
配合以上订阅转换模板和教程正确设置 OpenClash 后，大陆域名将使用国内 DNS 解析，默认为运营商DNS，可自行设置其他国内 DNS，且大陆域名绕过 Clash 内核，可以返回真实 IP 
国外域名自动走节点远端默认 DNS 解析，一般为机场默认的 DNS 或者你的 VPS 中设置的 DNS  
理论上，以上取得的均为最快最佳的解析结果，且无污染，无泄露，无需套娃其他工具    

## 关于 IPv6  
谁说 OpenClash 不能和 IPv6 同时工作？  
正确设置 OpenWRT 的 IPv6 功能以及 OpenClash，即可实现 IPv6 和 OpenWrt 完美兼容。在实现 IPv6 国内外分流代理的同时通过 IPv6-Test 国内和国外镜像站点测试   
IPv6 设置教程见本仓库的 Wiki：  
https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenWrt-IPv6-设置教程  

## 控制面板效果截图  
![](https://github.com/Aethersailor/Custom_OpenClash_Rules/blob/main/doc/openclash/pics/db2.png)  
## 机场推荐 
### SSRDOG  
本人常年使用的一家机场，价格和流量都比较适中  
节点覆盖地区全面，全 IEPL 线路不过墙，低延迟稳定流畅，流媒体/ChatGPT 全解锁，高峰时期油管8K秒开无压力，支持游戏加速，工单可用中文沟通且客服反应迅速  
https://dog1.ssrdog111.com/#/register?code=FnSb4oWM  
本仓库订阅模板的节点地区分类即是参考该机场的节点地区而分类  

## 感谢  
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)
- [dogfight360/UsbEAm](https://github.com/dogfight360/UsbEAm)
