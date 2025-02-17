# 一键脚本  
一些方便的一键脚本，欢迎使用。   
所有 OPKG 包管理器相关的脚本均未测试。  

***

## **一键更新 OpenClash 和 Meta 内核为最新 dev 版本（APK）**  

**install_openclash_dev.sh** 

仅限 APK 软件包管理器使用。  

大多数固件的软件源默认自带的 OpenClash 是 master 版本， 在值守式更新后，会将 OpenClash 和内核还原为 master 版本，这个脚本可以一键将 OpenClash 和内核更新为仓库中的最新 dev 版本，免去在 luci 上操作的麻烦。  

适合 dev 版本爱好者。  

```bash
curl -sSL -4 https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/install_openclash_dev.sh | sh
```

***


## **一键更新 OpenClash 和 Meta 内核为最新 dev 版本（OPKG）**  

**install_openclash_dev_opkg.sh** 

仅限 OPKG 软件包管理器使用。  

大多数固件的软件源默认自带的 OpenClash 是 master 版本， 在值守式更新后，会将 OpenClash 和内核还原为 master 版本，这个脚本可以一键将 OpenClash 和内核更新为仓库中的最新 dev 版本，免去在 luci 上操作的麻烦。  

适合 dev 版本爱好者，没测试。  

```bash
curl -sSL -4 https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/install_openclash_dev_opkg.sh | sh
```

***
  
## **一键更新 OpenClash 和 Meta 内核、GEO 数据库、大陆白名单、订阅信息（AKPG）** 

**install_openclash_dev_update_geo.sh**  

仅限 APK 软件包管理器使用。 

大多数固件的软件源默认自带的 OpenClash 是 master 版本， 在值守式更新后，会将 OpenClash 和内核还原为 master 版本，这个脚本可以一键将 OpenClash 和 Meta 内核更新为最新 dev 版本，并更新 GeoIP 和 GeoSite 数据库、大陆白名单、订阅链接，免去在 luci 上操作的麻烦。  

适合 dev 版本爱好者。 

```bash
curl -sSL -4 https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/install_openclash_dev_update_geo.sh | sh
```

***

## **一键写入“开发者选项”中的去广告命令（anti-AD 广告过滤规则 + Github520 加速规则）**  

**edit_custom_firewall_rules_anti-adn+github520.sh**  

```bash
curl -sSL -4 https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/edit_custom_firewall_rules_anti-adn+github520.sh | sh
```

***


## **一键写入“开发者选项”中的去广告命令（adblockfilters 广告过滤规则 + Github520 加速规则）**

**edit_custom_firewall_rules_adblockfilters+github520.sh**  
  
```bash
curl -sSL -4 https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/edit_custom_firewall_rules_adblockfilters+github520.sh | sh
```


***


## **一键写入“开发者选项”中的去广告命令（adblockfilters-modified 广告过滤规则 + Github520 加速规则）**

**edit_custom_firewall_rules_adblockfilters-modified+github520.sh**  

```bash
curl -sSL -4 https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/edit_custom_firewall_rules_adblockfilters-modified+github520.sh | sh
```


***


## **一键写入“开发者选项”中的 Github520 Hosts 拉取指令** 

**edit_custom_firewall_rules_github520.sh**  

一键写入“开发者选项”中的 Github520 Hosts 拉取指令  

```bash
curl -sSL -4 https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/edit_custom_firewall_rules_github520.sh | sh
```
