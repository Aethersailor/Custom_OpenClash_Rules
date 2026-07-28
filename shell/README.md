# OpenClash 实用脚本

本目录提供两个 OpenClash Dev 安装器和一个 CPU 架构检测脚本，支持 OpenWrt、ImmortalWrt、OPKG、APK、fw3/iptables、fw4/nftables，以及 Meta/Smart 内核。

## 快速开始

完整安装或更新（插件、内核、Smart 模型、Geo、Chnroute、订阅和用户预设）：

```sh
wget -O /tmp/install_openclash.sh 'https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/shell/install_openclash_dev_update.sh' &&
sh /tmp/install_openclash.sh
```

只安装或更新插件与内核：

```sh
wget -O /tmp/install_openclash.sh 'https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/shell/install_openclash_dev.sh' &&
sh /tmp/install_openclash.sh
```

只检测当前设备对应的 OpenClash 内核架构：

```sh
wget -O /tmp/check_cpu_version.sh 'https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/shell/check_cpu_version.sh' &&
sh /tmp/check_cpu_version.sh
```

请以 `root` 用户运行安装器。安装器会安装软件包、写入少量 OpenClash UCI 设置并重启 OpenClash。

## 两个安装器的共同流程

### 1. 软件源在依赖安装前直接临时切换

安装器不会先测试用户的原始软件源，也不会等原始源失败后再换源。固定顺序是：

1. 识别 OpenWrt 或 ImmortalWrt，以及 OPKG/APK；
2. 使用 `cp -p` 备份当前 distfeeds；
3. 在任何 `opkg update` 或 `apk update` 之前直接切换到指定镜像；
4. 更新索引并安装依赖；
5. 无论成功、失败或收到 INT、TERM、HUP，都恢复运行前的完整 feed。

镜像映射如下：

| 发行版 | 识别的基础地址 | 本次运行使用的镜像 |
| --- | --- | --- |
| ImmortalWrt | `downloads.immortalwrt.org`、`mirrors.vsean.net/openwrt` | `mirror.nju.edu.cn/immortalwrt` |
| OpenWrt | `downloads.openwrt.org` | `mirrors.ustc.edu.cn/openwrt` |

只替换上述已知基础地址，后续版本、架构和仓库路径保持不变。第三方或自定义 feed 原样保留。发行版已识别但 distfeeds 中没有相应已知地址时，安装器会明确失败，不会猜测地址或静默使用原始源。

如果 feed 已经是该发行版的目标镜像，安装器可直接使用；未实际修改的文件不会被多余覆盖。

### 2. 插件本体由安装器自行覆盖重装

两个安装器都不使用 OpenClash 内置的插件更新脚本。无论设备上是否已经安装 OpenClash、是否已经是同一版本，每次执行都会：

1. 通过 Git Smart HTTP 解析官方 `refs/heads/package` 的 40 位 commit SHA；
2. 锁定该不可变提交；
3. 从同一提交读取 `dev/version`；
4. 构造对应的 IPK 或 APK 文件名；
5. 从同一提交下载安装包；
6. 检查文件非空和最低大小，并执行包管理器 dry-run；
7. 覆盖重装；
8. 从包管理器读取已安装版本并与目标版本核对。

固定提交下载顺序是：

1. `https://testingcf.jsdelivr.net/`
2. `https://v6.gh-proxy.org/`
3. GitHub Raw

三条路径都使用同一个 commit SHA，不使用浮动的 `package/dev` 安装包 URL。package 分支在安装期间移动时最多追加一轮；即使之后再次移动，当前已安装内容仍来自一个完整且自洽的固定提交。

APK 每次都使用 `--force-reinstall` 覆盖同版本。支持 `--allow-downgrade` 的 APK 版本会同时启用该参数；APK 3 已移除该选项，安装器会使用其支持的显式本地包覆盖方式，避免传入无效参数。

安装或版本确认失败时，安装包会保留在 `/tmp`，终端同时输出手工安装命令。

### 3. 基础 UCI、内核和服务

两个安装器只写入以下共同设置：

```text
release_branch=dev
github_address_mod=https://testingcf.jsdelivr.net/
core_version=<自动检测结果>
enable=1
```

CPU 检测保留 x86_64 v1/v2/v3、x86、ARM、MIPS、LoongArch、RISC-V 和 s390x 的现有覆盖。安装器不在外层探测内核资源，也不做内核版本的二次比较。

插件覆盖重装后，安装器调用：

```sh
/usr/share/openclash/openclash_core.sh "<Meta 或 Smart>"
```

内核类型遵循 OpenClash 当前设置：`smart_enable=1` 时使用 Smart，否则读取 `core_type`，空值默认为 Meta。安装器不传入第二参数；当前 OpenClash 会将第二参数视为完整内核下载 URL，而 CDN 前缀已通过 `github_address_mod=https://testingcf.jsdelivr.net/` 写入。下载、重试、解压、配置测试、替换和重启决策由 OpenClash 内置脚本负责。

最后两个安装器都执行：

```sh
uci set openclash.config.enable='1'
uci commit openclash
/etc/init.d/openclash enable
/etc/init.d/openclash restart
```

安装器不以用户是否已有有效代理配置来判定插件安装失败，也不额外等待或扫描内核进程。

## 完整安装器的额外流程

`install_openclash_dev_update.sh` 在共同流程之外执行以下内容。

### Smart 与 LightGBM

只有当前有效内核为 Smart 时，安装器才设置：

```text
auto_smart_switch=1
lgbm_auto_update=1
```

安装器不会替用户开启 `smart_enable_lgbm`。只有用户原本已经设置 `smart_enable_lgbm=1` 时，才会按可用空间从大到小选择：

```text
Model-large.bin
Model-middle.bin
Model.bin
```

大小探测和实际下载都只通过 `https://v6.gh-proxy.org/`。下载完成且大小一致后，先在目标文件系统创建临时文件，再原子替换现有模型；任何探测、下载或替换失败都会保留旧模型。

模型安装成功后，`lgbm_custom_url` 写入对应的官方 GitHub 原始模型 URL，不把代理地址永久写入 UCI。

### Geo、Chnroute、订阅与用户预设

完整安装器依次调用：

```sh
/usr/share/openclash/openclash_geo.sh all
/usr/share/openclash/openclash_chnroute.sh
/usr/share/openclash/openclash.sh
```

随后如果 `/etc/config/openclash-set` 存在，则最后执行该用户预设。

安装器不重复实现这些内置脚本已有的下载、校验、比较、替换或重启逻辑，也不扫描日志关键词、订阅数量或用户配置内容。

## 如何理解完成提示

终端中的完成提示分为两层：

- 插件本体：安装器已经完成固定提交下载、包管理器 dry-run、覆盖重装和安装后版本确认；
- 内核及其他远端资源：安装器已经调用对应的 OpenClash 内置流程。

内置脚本被调用不代表每个远端资源必然下载成功。内核、Geo、Chnroute、订阅等详细结果请查看：

```text
/tmp/openclash.log
```
