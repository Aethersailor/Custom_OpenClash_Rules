# 个人自用 OpenClash 订阅转换模板
在 ACL4SSR 规则订阅模板的基础上进行了个性化修改，采用大陆白名单模式，无污染，无泄漏，配合 FakeIP 模式降低延迟提升响应速度。

## 介绍  
1.基于 ACL4SSR_Online_Full 规则修改；  
2.部分规则文件替换成 blackmatrix7 的规则文件，更加全面；  
3.广告拦截规则替换成 Anti-AD 规则；  
4.游戏平台增加战网国际服规则（战网国际服登录走代理，下载走直连）;  
5.单独列出 Steam 规则并增加 Steam 下载 CDN 的 IP 信息，解决 Steam 下载 CDN 定位到国外以及 Steam 下载流量走代理的问题；     
6.增加 TikTok、小米服务等分流规则；  
7.增加更多的节点区域分组（英国、加拿大等）；  
8.调整节点优先顺序。媒体服务优先新加坡节点，Copilt 优先美国节点，其余服务优先香港节点；  
9.增加个人常用的一些冷门域名（互动对战平台、猫眼浏览器等若干小众网站，绝无副作用。具体信息见 Rule\Custom_Direct.list 文件）;  
10.海外域名自动使用远端 DNS 解析，无污染，无泄露，无需套娃其他工具。 


## 使用方法  
需在 OpenClash 下配合 Clash.Meta 使用  
OpenClash > 配置订阅 > 编辑配置文件订阅信息  
订阅转换服务地址填写：  
https://apiurl.v1.mk/sub  
订阅转换模板选择自定义模板，填写：  
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini  

## 关于 DNS 泄露  
配合以上订阅转换模板，并正确设置 OpenClash 可以避免 DNS 泄露，无需套娃其他工具（如mosdns）  
OpenClash 设置建议配合恩山大神的教程贴使用：https://www.right.com.cn/forum/thread-8360227-1-1.html

## 关于 IPv6  
正确设置 OpenWRT 和 OpenClash，可完美兼容 IPv4 和 IPv6  
请首先确认你的节点支持 IPv6 出站，有 IPv6 地址，然后按照以下步骤操作：  

1.设置 OpenWRT IPv6  
严格按照以下教程，正确设置 OpenWRT 的 IPv6 功能，并在关闭OpenClash的情况下通过IPv6测试  
OpenWRT IPv6 设置教程：https://post.smzdm.com/p/awzodmpp/  

2.OpenCLash 设置：  
先按照上面恩山帖子完成 OpenClash 的设置，然后打开 OpenClash 的 IPv6 设置，勾选“IPv6 流量代理”，IPv6 代理模式选择“TUN 模式”，勾选“允许 IPv6 类型 DNS 解析”和“实验性：绕过中国大陆 IPv6”，最后应用设置即可。  

## 感谢  
- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD)
- [youshandefeiyang/sub-web-modify](https://github.com/youshandefeiyang/sub-web-modify)
- [dogfight360/UsbEAm](https://github.com/dogfight360/UsbEAm)
