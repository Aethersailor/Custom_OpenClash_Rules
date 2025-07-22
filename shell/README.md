# 一键脚本  
一些方便的一键脚本，欢迎使用。   

***

## **一键安装更新 OpenClash 为最新 dev 版本**  

**install_openclash_dev_update.sh** 

兼容 APK 和 OPKG 包管理器。  

大多数固件的软件源默认自带的 OpenClash 是 master 版本，在值守式更新后，会将 OpenClash 和内核还原为 master 版本  

该脚本可以自动从 OpenClash 官方仓库拉取最新 dev 版本安装包并安装，并更新内核至 dev 版本，同时更新所有的数据库、大陆白名单以及订阅至最新版，然后启动 OpenClash。

**新增功能：** 如果检测到 Smart 内核已启用（`openclash.config.smart_enable = '1'`），脚本会自动下载最新的 Smart 内核模型文件（Model-large.bin）并保存为 `/etc/openclash/Model.bin`，支持 CDN 加速下载。  

适合 dev 版本爱好者。  

```bash
curl -sSL -4 https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/install_openclash_dev_update.sh | sh
```

***

## **写入“开发者选项”中的去广告命令**  

**edit_custom_firewall_rules.sh**  

运行脚本后，根据提示自行选择需要写入的去广告规则指令。  

```bash
curl -sSL -4 https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/edit_custom_firewall_rules.sh | sh
```

***

## **一键写入“开发者选项”中的去广告命令（anti-AD 广告过滤规则 + Github520 加速规则）**  

**edit_custom_firewall_rules_anti-adn+github520.sh**  

```bash
curl -sSL -4 https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/edit_custom_firewall_rules_anti-ad+github520.sh | sh
```

***

## **一键写入“开发者选项”中的去广告命令（adblockfilters 广告过滤规则 + Github520 加速规则）**

**edit_custom_firewall_rules_adblockfilters+github520.sh**  
  
```bash
curl -sSL -4 https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/edit_custom_firewall_rules_adblockfilters+github520.sh | sh
```

***

## **一键写入“开发者选项”中的去广告命令（adblockfilters-modified 广告过滤规则 + Github520 加速规则）**

**edit_custom_firewall_rules_adblockfilters-modified+github520.sh**  

```bash
curl -sSL -4 https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/edit_custom_firewall_rules_adblockfilters-modified+github520.sh | sh
```

***

## **一键写入“开发者选项”中的 Github520 Hosts 拉取指令** 

**edit_custom_firewall_rules_github520.sh**  

一键写入“开发者选项”中的 Github520 Hosts 拉取指令  

```bash
curl -sSL -4 https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/edit_custom_firewall_rules_github520.sh | sh
```
