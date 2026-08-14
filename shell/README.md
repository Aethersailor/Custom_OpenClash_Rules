# OpenClash 实用脚本

本目录提供两个 OpenClash `dev` 版安装器和一个 CPU 架构检测脚本，适用于 OpenWrt 和 ImmortalWrt，兼容 `opkg` 与 `apk` 包管理器、`fw3`（基于 `iptables`）与 `fw4`（基于 `nftables`）防火墙，以及 Meta 与 Smart 内核。

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

使用 `root` 用户运行安装器。安装器会安装软件包、写入少量 OpenClash UCI 设置并重启 OpenClash。

## 终端显示

两个安装器均采用单一默认运行方式，不提供额外的详细、安静或无颜色参数。按照上述命令运行即可查看完整流程。

在交互式终端中，安装器启动时会清屏一次，然后按固定阶段展示：

- 发行版、包管理器、防火墙和安装包格式；
- 临时使用的软件源镜像、依赖处理和原软件源恢复状态；
- 官方 `package` 分支、短 SHA、目标版本、安装包名称和实际下载来源；
- 文件大小、SHA-256（可用时）和包管理器安装预检结果；
- CPU 与内核架构、Meta 与 Smart 类型和 OpenClash 内置流程的调用状态；
- 完整安装器中的 Smart、LightGBM、Geo、Chnroute、订阅和用户预设结果；
- OpenClash 启用、重启以及最终汇总。

包管理器和 OpenClash 内置脚本的大段原始输出不会与上述界面混排，而是写入本次运行日志 `/tmp/openclash-installer.<PID>.log`。如果切换到备用来源，终端会自动说明首选来源、备用来源和最终校验结果。如果安装失败，终端会自动展开失败阶段、原因、软件源恢复状态和日志末尾的关键错误，无需改用其他命令重新运行。

输出被重定向到文件或其他非交互环境时，安装器不会清屏，也不会写入 ANSI 颜色控制字符。

## 两个安装器的共同流程

### 1. 软件源在依赖安装前直接临时切换

安装器不会先测试用户的原始软件源，也不会等原始源失败后再换源。固定顺序是：

1. 识别 OpenWrt 或 ImmortalWrt，以及 `opkg` 或 `apk`；
2. 使用 `cp -p` 备份当前 `distfeeds`；
3. 忽略原软件源域名，将标准发行版仓库路径写入临时 CERNET 软件源；
4. 更新索引并安装依赖；
5. 无论成功、失败还是收到 INT、TERM、HUP，都恢复运行前的完整软件源配置。

镜像映射如下：

| 发行版 | 当前软件源 | 本次运行使用的镜像 |
| --- | --- | --- |
| ImmortalWrt | 任意包含标准 `/releases/` 或 `/snapshots/` 路径的软件源 | `mirrors.cernet.edu.cn/immortalwrt` |
| OpenWrt | 任意包含标准 `/releases/` 或 `/snapshots/` 路径的软件源 | `cernet.mirrors.ustc.edu.cn/openwrt` |

安装器不再维护软件源域名白名单。安装器从当前 `distfeeds` 提取标准的 `/releases/…` 或 `/snapshots/…` 路径，保留版本、目标、架构和仓库名称，并统一写入对应的 CERNET 根地址。原软件源域名、镜像前缀和不属于发行版标准仓库的条目不会进入临时软件源；运行前的完整文件仍会在依赖阶段结束时恢复。

OpenWrt 使用中国科学技术大学的 CERNET 网络入口。CERNET 智能聚合根地址当前可能把 OpenWrt snapshots 导向不包含 snapshots 的成员镜像，因此安装器不使用该不稳定路径。

如果 `distfeeds` 中没有任何标准 `/releases/` 或 `/snapshots/` 仓库路径，安装器无法构造对应的 CERNET 地址，并会在修改软件源前停止。

### 2. 插件本体由安装器自行覆盖重装

两个安装器都不使用 OpenClash 内置的插件更新脚本。无论设备上是否已经安装 OpenClash、是否已经是同一版本，每次执行都会：

1. 通过 Git Smart HTTP 解析官方 `refs/heads/package` 的 40 位提交 SHA；
2. 锁定该不可变提交；
3. 从同一提交读取 `dev/version`；
4. 构造对应的 `.ipk` 或 `.apk` 文件名；
5. 从同一提交下载安装包；
6. 检查文件非空且达到最低大小，并执行包管理器预检（dry run）；
7. 覆盖重装；
8. 从包管理器读取已安装版本并与目标版本核对。

固定提交下载顺序是：

1. `https://testingcf.jsdelivr.net/`
2. `https://v6.gh-proxy.org/`
3. GitHub Raw

三条路径都使用同一个提交 SHA，不使用浮动的 `package/dev` 安装包 URL。如果 `package` 分支在安装期间发生移动，安装器最多追加一轮处理；即使分支之后再次移动，当前已安装内容仍来自一个完整且自洽的固定提交。

`apk` 每次都使用 `--force-reinstall` 覆盖同版本。支持 `--allow-downgrade` 的 `apk` 版本会同时启用该参数；`apk` 3 已移除该选项，安装器会使用其支持的显式本地包覆盖方式，避免传入无效参数。

安装或版本确认失败时，安装包会保留在 `/tmp`，终端同时输出手动安装命令。

### 3. 基础 UCI、内核和服务

两个安装器只写入以下共同设置：

```text
release_branch=dev
github_address_mod=https://testingcf.jsdelivr.net/
core_version=<自动检测结果>
enable=1
```

CPU 检测保留 `x86_64` 的 `v1`、`v2`、`v3` 级别，以及 `x86`、ARM、MIPS、LoongArch、RISC-V 和 `s390x` 的现有覆盖范围。安装器不会在外层探测内核资源，也不会再次比较内核版本。

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

安装器不会自动启用 `smart_enable_lgbm`。仅当运行前已经设置 `smart_enable_lgbm=1` 时，安装器才会根据可用空间从大到小选择：

```text
Model-large.bin
Model-middle.bin
Model.bin
```

文件大小探测和实际下载优先通过 `https://v6.gh-proxy.org/`。如果代理返回的内容与可用的官方 SHA-256 元数据不一致，安装器会尝试直接访问 GitHub；无法完成安全校验时保留旧模型。下载完成且文件大小一致后，安装器先在目标文件系统中创建临时文件，再原子替换现有模型。

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

## 如何理解终端结果

最终汇总会明确区分两类状态：

- 插件本体：安装器已经完成固定提交下载、包管理器预检（dry run）、覆盖重装和安装后版本确认；
- 内核及其他远端资源：安装器已经调用对应的 OpenClash 内置流程。

内置脚本被调用不代表每个远端资源必然下载成功。内核、Geo、Chnroute、订阅等详细结果请查看：

```text
/tmp/openclash.log
```

安装器自身的软件源、包管理器、下载回退和安装过程则记录在最终汇总显示的 `/tmp/openclash-installer.<PID>.log`。
