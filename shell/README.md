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
wget -qO- https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/install_openclash_dev_update.sh | sh
```

---

## 归档文件夹

`archived/` 文件夹包含已弃用的脚本文件，保留用于历史参考。详情请查看 [archived/README.md](archived/README.md)。
