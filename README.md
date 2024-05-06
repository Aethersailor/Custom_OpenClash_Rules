# OpenClash 设置教程和个人自用 OpenClash 订阅转换模板  
绝对全网最强的 OpenClash 图文教程，秒杀一切教程贴！终结所有错误设置！让稀奇古怪的套娃设置见鬼去吧！  
手把手嘴对嘴教你把 OpenClash 设置为效率、安全、便利三者兼顾的完美状态，零基础小白也能看懂；  
按照本项目 Wiki 中的教程，搭配本项目的订阅模板对 OpenClash 进行设置，仅依靠 OpenClash 自身，无需套娃其他工具即可实现快速且无污染、无泄漏的 DNS 解析以及多样的分流功能，同时配合 Dnsmasq 实现无第三方插件的广告拦截，并且完美兼容 IPv6      
欢迎批评指正  

## 个人使用需求  
* 媒体服务（Youtube、Netflix、Disney+ 等）走指定节点，特定网站（电报、ChatGPT 等）走指定区域节点测速选优或特定节点  
* 特定网站（苹果服务、微软服务以及国内域名 IP 等）走直连，其他国外网站走指定节点，节点需要按照区域自动测速选优，无 DNS 泄露   
* 大陆域名和IP绕过内核提升性能  
* 兼容 IPv6，且 IPv6 完美分流  
* 广告拦截  
* 定时自动更新上游规则，无人值守

## 订阅转换模板介绍
本项目订阅转换模板是在 [ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) 规则的订阅模板的基础上进行了魔改 
* 基于 ACL4SSR_Online_Full 全分组规则魔改，将部分分流规则碎片替换成 blackmatrix7 的规则文件，增加更多策略组；  
* 游戏平台规则增加 Battle.net 战网国际服规则（登录走代理，下载走直连，暴雪游戏国服回归后会取消此规则）;  
* 单独列出 Steam 规则并强制 Steam 下载 CDN 走直连，解决 Steam 下载 CDN 定位到国外的问题，确保 Steam 下载流量不走代理；     
* 增加更多的节点区域分组（英国、加拿大等）；  
* 调整节点默认优先顺序；  
* 增加个人自用的若干冷门域名规则（互动对战平台、猫眼浏览器等若干小众网站，绝无副作用。具体内容详见 Rule\Custom_Direct.list 文件）;  
* 采用大陆白名单机制分流（包括域名、IPv4 地址和 IPv6 地址），杜绝 DNS 污染和泄漏；   

## 使用方法  
需在 OpenClash 下配合 Clash.Meta 使用  
设置教程详见本项目的 Wiki，其中包括了本项目订阅转换模板的地址：  
https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-设置教程  
感谢恩山各路大神的教程贴，让我学习了很多  
此处也提供单独的订阅模板链接：  
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini  
不搭配本项目教程使用的话，不保证最终效果完美  

## 关于广告拦截  
由于放弃了套娃其他工具，且大陆域名绕过了 OpenClash 内核，因此去广告功能只能由 Dnsmasq 的 hosts 文件来实现  
详情见本人另一个项目 [AutoUpdateHosts](https://github.com/Aethersailor/OpenWrt-AutoUpdateHosts)   
内有一键安装脚本，可实现每日自动下载去广告 hosts 文件并合并至本机 hosts 文件的功能  

## 关于 DNS 泄露  
配合以上订阅转换模板和教程正确设置 OpenClash 后，大陆域名将使用国内 DNS 解析，默认为运营商DNS，可自行设置其他国内 DNS，且大陆域名绕过 Clash 内核，可以返回真实 IP 
国外域名自动走节点远端默认 DNS 解析，一般为机场默认的 DNS 或者你的 VPS 中设置的 DNS  
理论上，以上取得的均为最快最佳的解析结果，且无污染，无泄露，无需套娃其他工具    

## 关于 IPv6  
正确设置 OpenWRT 和 OpenClash，可完美 IPv6 并实现 IPv6 的国内外分流代理   
请首先确认你的节点具备 IPv6 出站能力（机场请发工单询问客服），然后按照以下步骤操作：  

1.参考本人教程贴设置 OpenWRT 的 IPv6：
https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenWrt-IPv6-设置教程  
2.参考本人教程贴设置 OpenCLash：  
启用 OpenClash 中的 IPv6 功能，具体见本项目的 Wiki 中的教程  

## 机场推荐 
### SSRDOG  
本人常年使用的一家机场，价格和流量都比较适中  
节点覆盖地区全面，全 IEPL 线路，稳定流畅，流媒体/ChatGPT 全解锁，高峰时期油管8K无压力，支持游戏加速，工单可用中文沟通且客服反应迅速  
https://dog1.ssrdog111.com/#/register?code=FnSb4oWM  
本项目订阅模板的节点地区分类即是参考该机场的节点地区而分类  

## 感谢  
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)
- [dogfight360/UsbEAm](https://github.com/dogfight360/UsbEAm)
