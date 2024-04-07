# 个人自用 OpenClash 订阅转换模板

1.修改自 ACL4SSR 规则；  
2.部分规则文件替换成 blackmatrix7 的规则文件；  
3.广告拦截规则替换成 Anti-AD 规则； 
4.游戏平台规则增加战网国际服；   
5.增加 TikTok、Steam 国区、小米服务等分流规则；  
6.增加更多的节点区域分组，调整节点优先顺序；  
7.海外域名自动使用远端 DNS 解析，避免 DNS 泄露；  


## 食用方法  
OpenClash > 配置订阅 > 编辑配置文件订阅信息  
订阅转换服务地址填写：  
https://apiurl.v1.mk/sub  
订阅转换模板选择自定义模板，填写：  
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/cfg/Custom_Clash.ini  

## 关于 DNS 泄露  
正确设置可以避免 DNS 泄露  
OpenClash 设置建议配合恩山大神的教程贴使用：https://www.right.com.cn/forum/thread-8360227-1-1.html

## 关于 IPv6  
正确设置 OpenWRT 和 OpenClash，可完美容 IPv4 和 IPv6  
请首先确认你的节点支持 IPv6 出站，有 IPv6 地址，然后按照以下步骤操作：  

1.设置 OpenWRT IPv6  
严格按照以下教程步骤打开IPv6功能  
OpenWRT IPv6 设置教程：https://post.smzdm.com/p/awzodmpp/  

2.OpenCLash 设置：  
先按照上面恩山帖子完成 OpenClash 的设置，然后打开 OpenClash 的 IPv6 设置，勾选“IPv6 流量代理”，IPv6 代理模式选择“TUN 模式”，勾选“允许 IPv6 类型 DNS 解析”和“实验性：绕过中国大陆 IPv6”，最后应用设置即可。  

##感谢  

- [vernesong/OpenClash](https://github.com/vernesong/OpenClash)
- [MetaCubeX/mihomo](https://github.com/MetaCubeX/mihomo)
- [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR)
- [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script)
- [privacy-protection-tools/anti-AD](https://github.com/privacy-protection-tools/anti-AD)
- [dogfight360/UsbEAm]https://github.com/dogfight360/UsbEAm