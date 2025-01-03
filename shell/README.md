自用脚本文件。  
擅自使用，后果自负。  


### install_openclash_dev.sh  
一键更新 OpenClash 和 Meta 内核为最新 dev 版本。  
ImmortalWrt 在值守式更新后，会将 OpenClash 和内核还原为 Master 版本，这个脚本可以一键更新 OpenClash 和内核为仓库中的最新 dev 版本，免去在 luci 上操作的麻烦。  
适合 dev 版本爱好者。  
```bash
curl -s https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/install_openclash_dev.sh | sh
```

### install_openclash_dev_update_geo.sh
一键更新 OpenClash 和 Meta 内核为最新 dev 版本，并更新 GeoIP 和 GeoSite 数据库、大陆白名单。  
```bash
 curl -s https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/install_openclash_dev_update_geo.sh | sh
 ```

### edit_custom_firewall_rules.sh
一键写入“开发者选项”中的去广告命令  
```bash
curl -s https://gh-proxy.com/https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/edit_custom_firewall_rules.sh | sh
```
