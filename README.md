# 个人自用 OpenClash 订阅转换模板
在 [ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) 规则的订阅模板的基础上进行了个性化修改  
采用大陆白名单模式，在配合正确的 OpenClash 设置的情况下，无需套娃其他工具即可实现快速且无污染、无泄漏的DNS解析以及多样的分流功能  

# 个人使用需求  
媒体服务（Youtube、Netflix、Disney+ 等）走指定节点，特定网站（电报、ChatGPT 等）走指定节点，特定网站（苹果服务、微软服务以及国内域名 IP 等）走直连，其他国外网站走指定节点，节点需要按照区域自动测速选优，无 DNS 泄露   

## 介绍  
1.基于 ACL4SSR_Online_Full 全分组规则修改，模板中引用的上游规则碎片均为第三方规则，即使本模板常年不更新，也不会出现规则更新不及时的情况；  
2.将部分分流规则文件替换成 blackmatrix7 的规则文件，内容更加全面；  
3.游戏平台规则增加 Battle.net 战网国际服规则（登录走代理，下载走直连）;  
4.单独列出 Steam 规则并增加 Steam 下载 CDN 的 IP 分流信息，解决 Steam 下载 CDN 定位到国外的问题，确保 Steam 下载流量不走代理；     
5.增加 TikTok、小米服务等分流规则；  
6.增加更多的节点区域分组（英国、加拿大等）；  
7.调整节点默认优先顺序。媒体服务默认优先新加坡节点，Copilot 默认优先美国节点，其余服务默认优先香港节点，请在控制面板中按照自己的需要进行选择；  
8.增加个人自用的若干冷门域名规则（互动对战平台、猫眼浏览器等若干小众网站，绝无副作用。具体内容详见 Rule\Custom_Direct.list 文件）;  
9.采用大陆白名单机制分流（包括域名、IPv4 地址和 IPv6 地址）；   

## 使用方法  
需在 OpenClash 下配合 Clash.Meta 使用  
OpenClash 设置参考恩山论坛大佬的教程贴使用：https://www.right.com.cn/forum/thread-8360227-1-1.html  
其中，OpenClash > 配置订阅 > 编辑配置文件订阅信息  
教程贴中使用的是肥羊大佬的订阅转换地址，实际测试中使用肥羊订阅转换会附加 Google 和 Cloudflare 的 DNS 服务器作为 Fallback 服务器  
实际使用过程中，理论上的最佳选择是直接使用机场节点的 DNS 服务器或者你的 VPS 的 DNS 服务器，所以我们并不需要设置 OpenClash 的 Fallback 服务器  
因此，订阅转换服务地址选择默认的 api.dler.io  
订阅转换模板选择自定义模板，填写本项目订阅转换模板地址：  
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini  

## 关于广告拦截  
由于放弃了套娃其他工具，且大陆域名绕过了 OpenClash 内核，因此去广告功能只能由 Dnsmasq 的 hosts 文件来实现  
已编写一键脚本用于实现自动更新去广告 hosts 文件并重启 OpenClash/Dnsmasq 稍后我会上传脚本安装方式  

## 关于 DNS 泄露  
配合以上订阅转换模板，并正确设置 OpenClash 后，大陆域名将使用国内DNS解析，默认为运营商DNS，可自行设置其他国内 DNS  
国外域名自动走节点远端默认 DNS 解析，一般为机场默认的 DNS 或者你的 VPS 中设置的 DNS  
理论上取得的均为最快最佳的解析结果，且无污染，无泄露，无需套娃其他工具    

## 关于 IPv6  
正确设置 OpenWRT 和 OpenClash，可完美兼容 IPv4 和 IPv6  
请首先确认你的节点具备 IPv6 出站能力，然后按照以下步骤操作：  

1.设置 OpenWRT 的 IPv6  
严格按照以下教程，正确设置 OpenWRT 的 IPv6 功能，并在关闭 OpenClash 的情况下通过 IPv6 测试  
OpenWRT IPv6 设置教程：https://post.smzdm.com/p/awzodmpp/  

2.OpenCLash 设置：  
先按照上面恩山论坛的帖子完成 OpenClash 的设置，然后打开 OpenClash 的 IPv6 设置，勾选“IPv6 流量代理”，IPv6 代理模式选择“TUN 模式”，勾选“允许 IPv6 类型 DNS 解析”和“实验性：绕过中国大陆 IPv6”，最后应用设置即可。

## 机场推荐 
### SSRDOG  
本人常年使用的一家机场，价格和流量都比较适中  
节点覆盖地区全面，全 IEPL 线路，稳定流畅，流媒体/ChatGPT 全解锁，高峰时期油管8K无压力，支持游戏加速，工单可用中文沟通且客服反应迅速  
https://dog1.ssrdog111.com/#/register?code=FnSb4oWM  
本仓库配置的节点地区分类即是参考该机场的节点地区而分类  

## 感谢  
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [Cats-Team/AdRules](https://github.com/Cats-Team/AdRules)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)
- [youshandefeiyang/sub-web-modify](https://github.com/youshandefeiyang/sub-web-modify)
- [dogfight360/UsbEAm](https://github.com/dogfight360/UsbEAm)
