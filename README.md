# 个人自用 OpenClash 订阅转换模板
在 ACL4SSR 规则订阅模板的基础上进行了个性化修改  
采用大陆白名单模式，在配合正确的 OpenClash 设置的情况下，无需套娃其他工具即可实现快速且无污染、无泄漏的DNS解析以及多样的分流功能  

## 介绍  
1.基于 ACL4SSR_Online_Full 规则修改，模板中引用的上游规则碎片均为第三方规则，即使本模板常年不更新，也不会出现规则更新不及时的情况；  
2.将部分规则文件替换成 blackmatrix7 的规则文件，更加全面；  
3.游戏平台规则增加 Battle.net 战网国际服规则（登录走代理，下载走直连）;  
4.单独列出 Steam 规则并增加 Steam 下载 CDN 的 IP 分流信息，解决 Steam 下载 CDN 定位到国外以及 Steam 下载流量走代理的问题；     
5.增加 TikTok、小米服务等分流规则；  
6.增加更多的节点区域分组（英国、加拿大等）；  
7.调整节点优先顺序。媒体服务优先新加坡节点，Copilt 优先美国节点，其余服务优先香港节点；  
8.增加个人自用的若干冷门域名规则（互动对战平台、猫眼浏览器等若干小众网站，绝无副作用。具体内容详见 Rule\Custom_Direct.list 文件）;  
9.采用大陆白名单机制分流（包括域名、IPv4 地址和 IPv6 地址）；   

## 使用方法  
需在 OpenClash 下配合 Clash.Meta 使用  
OpenClash 设置参考恩山论坛大佬的教程贴使用：https://www.right.com.cn/forum/thread-8360227-1-1.html  
其中，OpenClash > 配置订阅 > 编辑配置文件订阅信息  
订阅转换服务地址填写肥羊大佬的订阅转换地址：  
https://apiurl.v1.mk/sub  
订阅转换模板选择自定义模板，填写本项目订阅转换模板地址  
若需要广告屏蔽功能，填写：    
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini  
若不需要广告屏蔽功能，填写：  
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash_NoBlockAD.ini  

## 关于 DNS 泄露  
配合以上订阅转换模板，并正确设置 OpenClash 后，大陆域名将使用国内DNS解析（默认为运营商DNS，可自行设置其他国内DNS），国外域名自动走节点远端默认DNS解析，理论上取得的均为最快最佳的解析结果，且无污染，无泄露，无需套娃其他工具    

## 关于 IPv6  
正确设置 OpenWRT 和 OpenClash，可完美兼容 IPv4 和 IPv6  
请首先确认你的节点具备 IPv6 出站能力，然后按照以下步骤操作：  

1.设置 OpenWRT IPv6  
严格按照以下教程，正确设置 OpenWRT 的 IPv6 功能，并在关闭 OpenClash 的情况下通过 IPv6 测试  
OpenWRT IPv6 设置教程：https://post.smzdm.com/p/awzodmpp/  

2.OpenCLash 设置：  
先按照上面恩山论坛的帖子完成 OpenClash 的设置，然后打开 OpenClash 的 IPv6 设置，勾选“IPv6 流量代理”，IPv6 代理模式选择“TUN 模式”，勾选“允许 IPv6 类型 DNS 解析”和“实验性：绕过中国大陆 IPv6”，最后应用设置即可。

## 机场推荐 
### SSRDOG  
本人常年使用的一家机场，价格和流量都比较适中  
节点覆盖地区全面，全IEPL线路，稳定流畅，流媒体/ChatGPT全解锁，高峰时期油管8K无压力，支持游戏加速，工单可用中文沟通且客服反应迅速  
https://dog1.ssrdog111.com/#/register?code=FnSb4oWM  

## 感谢  
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD)
- [TraderWukong/demo](https://github.com/TraderWukong/demo)
- [youshandefeiyang/sub-web-modify](https://github.com/youshandefeiyang/sub-web-modify)
- [dogfight360/UsbEAm](https://github.com/dogfight360/UsbEAm)
