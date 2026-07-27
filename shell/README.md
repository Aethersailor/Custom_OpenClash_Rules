<h1 align="center">
  🐚 OpenClash 实用脚本
</h1>

<p align="center"><b>✨ 一键安装、更新与维护 OpenClash Dev ✨</b></p>

<p align="center">
  <a href="#-快速开始">🚀 快速开始</a>
  &nbsp;•&nbsp;
  <a href="#-应该使用哪个安装脚本">🧭 脚本选择</a>
  &nbsp;•&nbsp;
  <a href="#️-运行要求与注意事项">⚠️ 注意事项</a>
  &nbsp;•&nbsp;
  <a href="#-下载失败时">🛠️ 故障排查</a>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Shell-POSIX%20sh-4EAA25?style=flat&logo=gnu-bash&logoColor=white" alt="POSIX Shell">
  <img src="https://img.shields.io/badge/System-OpenWrt%20%7C%20ImmortalWrt-0055AA?style=flat&logo=openwrt&logoColor=white" alt="OpenWrt and ImmortalWrt">
  <img src="https://img.shields.io/badge/Package%20Manager-OPKG%20%7C%20APK-8A2BE2?style=flat" alt="OPKG and APK">
  <img src="https://img.shields.io/badge/Firewall-fw3%20%7C%20fw4-orange?style=flat" alt="fw3 and fw4">
</p>

---

本目录提供 OpenClash 安装、更新和 CPU 架构检测脚本。

> [!TIP]
> 所有公开使用命令均固定读取本仓库 `main` 分支。普通用户无需预设变量、手动选择分支或传入其他参数，复制对应命令即可运行。

## 🚀 快速开始

安装命令采用“下载成功后再执行”的形式：下载失败时不会继续运行空脚本，下载后的文件也便于在执行前自行检查。

### 🌟 完整安装或更新（推荐）

适合首次安装、固件升级后恢复，以及希望一次完成插件、内核、数据库和订阅更新的用户：

```sh
wget -O /tmp/install_openclash.sh 'https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/shell/install_openclash_dev_update.sh' && sh /tmp/install_openclash.sh
```

### ⚡ 只更新插件和内核

适合只想安装或更新 OpenClash Dev 插件与当前所用内核，不希望脚本更新 Geo 数据库、大陆 IP 白名单和订阅的用户：

```sh
wget -O /tmp/install_openclash.sh 'https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/shell/install_openclash_dev.sh' && sh /tmp/install_openclash.sh
```

### 🔍 检测 CPU 对应的内核架构

只输出当前设备应使用的 OpenClash 内核架构名称，不修改系统：

```sh
wget -O /tmp/check_cpu_version.sh 'https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/shell/check_cpu_version.sh' && sh /tmp/check_cpu_version.sh
```

示例输出：

```text
linux-arm64
linux-amd64-v3
linux-mipsle-hardfloat
```

---

## 🧭 应该使用哪个安装脚本

| 🔧 处理项目 | ⚡ `install_openclash_dev.sh` | 🌟 `install_openclash_dev_update.sh` |
| --- | :---: | :---: |
| 检测 OPKG/APK 和防火墙类型 | ✅ | ✅ |
| 检查并安装 OpenClash 依赖 | ✅ | ✅ |
| 安装官方 `package` 分支的最新 Dev 插件包 | ✅ | ✅ |
| 自动识别 CPU 架构并更新 Meta/Smart 内核 | ✅ | ✅ |
| 启用、重启并验证 OpenClash | ✅ | ✅ |
| 更新 Smart LGBM 模型 | — | ✅ |
| 更新 GeoIP、GeoSite、ASN 和 Country 数据库 | — | ✅ |
| 更新大陆 IPv4/IPv6 白名单 | — | ✅ |
| 更新已配置的订阅 | — | ✅ |
| 执行 `/etc/config/openclash-set` 个性化脚本 | — | ✅ |

> [!TIP]
> 拿不准时使用完整脚本 `install_openclash_dev_update.sh`。如果现有配置和数据均已正常，只想更新 OpenClash 插件与内核，使用精简脚本 `install_openclash_dev.sh`。

---

## ⚠️ 运行要求与注意事项

> [!IMPORTANT]
> 请通过 SSH 以 `root` 用户运行。安装脚本会修改软件包、部分 UCI 设置并重启 OpenClash，重要配置请提前备份。

- 脚本适用于 OpenWrt 和 ImmortalWrt，不适用于普通 Debian、Ubuntu 等通用 Linux 系统。
- 支持 `opkg` 和新版 Snapshot 使用的 `apk`，并自动适配 `fw3/iptables` 与 `fw4/nftables`。
- 安装脚本会安装缺少的依赖、安装或升级 OpenClash、写入部分 UCI 设置并重启 OpenClash。重要配置请提前备份。
- 两个安装脚本都会把 OpenClash 更新分支设为 `dev`；完整脚本还会启用 `skip_safe_path_check`，并把默认 GitHub 下载源设为 `https://testingcf.jsdelivr.net/`。
- 默认软件源不可用时，脚本会临时切换到南京大学镜像重试，并在完成或退出时恢复原软件源配置。
- 安装包会锁定到执行时官方 `package` 分支的提交，并校验文件大小和 SHA-256，避免分支在下载过程中变化导致文件混用。
- 脚本会验证下载资源和 OpenClash 服务能否正常启动，但不会检查或改写用户自己的代理配置内容。
- 安装过程中不要同时运行另一个 OpenClash 安装或更新任务；脚本自带运行锁，检测到重复任务时会退出。

---

## 📚 脚本说明

### 🌟 `install_openclash_dev_update.sh`

<p>
  <img src="https://img.shields.io/badge/Mode-Full%20Update-brightgreen?style=flat-square" alt="Full Update">
  <img src="https://img.shields.io/badge/Core-Meta%20%7C%20Smart-ff69b4?style=flat-square" alt="Meta and Smart">
  <img src="https://img.shields.io/badge/Resources-Full%20Sync-blue?style=flat-square" alt="Full resource sync">
</p>

完整安装与维护入口，执行顺序如下：

1. 检测包管理器、防火墙和现有 OpenClash 版本；
2. 更新软件源并补齐依赖；
3. 获取并校验官方 `package` 分支的最新 Dev 安装包；
4. 将 OpenClash 更新分支设为 `dev`、启用 `skip_safe_path_check`、设置 GitHub 下载源，并写入正确的内核架构；
5. 更新当前启用的 Meta 或 Smart 内核；
6. Smart 模式启用 LGBM 时，根据可用空间选择合适的模型并校验；
7. 更新 Geo 数据库、大陆 IP 白名单和已配置的订阅；
8. 如存在 `/etc/config/openclash-set`，最后执行该文件中的用户个性化设置；
9. 启用并重启 OpenClash，确认服务状态和内核进程正常。

> [!NOTE]
> 脚本不会因为设备未配置订阅而失败；没有订阅时会直接跳过订阅更新。

### ⚡ `install_openclash_dev.sh`

<p>
  <img src="https://img.shields.io/badge/Mode-Lightweight-00A86B?style=flat-square" alt="Lightweight mode">
  <img src="https://img.shields.io/badge/Scope-Plugin%20%2B%20Core-blue?style=flat-square" alt="Plugin and core">
  <img src="https://img.shields.io/badge/Service-Startup%20Verified-success?style=flat-square" alt="Startup verified">
</p>

精简安装与更新入口。它仍会完成环境检测、软件源更新、依赖安装、最新 Dev 插件安装、CPU 架构识别、内核更新以及服务启动验证，但不会执行以下操作：

- 更新 Smart LGBM 模型；
- 更新 Geo 数据库和大陆 IP 白名单；
- 更新订阅；
- 执行 `/etc/config/openclash-set`。

> [!NOTE]
> “精简”只表示缩小更新范围，并不表示跳过依赖检查、软件源处理或启动验证。

### 🔍 `check_cpu_version.sh`

<p>
  <img src="https://img.shields.io/badge/Function-CPU%20Detect-blue?style=flat-square" alt="CPU detection">
  <img src="https://img.shields.io/badge/Architecture-Multi--Arch-orange?style=flat-square" alt="Multi architecture">
  <img src="https://img.shields.io/badge/System%20Changes-None-lightgrey?style=flat-square" alt="No system changes">
</p>

读取 `uname -m`、`/proc/cpuinfo`、CPU 指令集、MIPS FPU 状态及 LoongArch 内核版本，输出与 OpenClash 内核资源一致的架构名称。

其中 x86_64 会进一步区分：

- `linux-amd64-v1`：通用 x86_64；
- `linux-amd64-v2`：支持 SSE4.2 等 v2 指令集；
- `linux-amd64-v3`：支持 AVX、AVX2、BMI、FMA 等 v3 指令集。

该脚本正常使用时不需要参数。`--self-check` 仅用于仓库维护和回归测试，不是普通用户的安装选项。

---

## 🛠️ 下载失败时

如果所在网络无法访问 jsDelivr，可把命令中的下载地址替换为 GitHub Raw。例如完整脚本可使用：

```sh
wget -O /tmp/install_openclash.sh 'https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/shell/install_openclash_dev_update.sh' && sh /tmp/install_openclash.sh
```

脚本启动后会自行使用多个来源获取 OpenClash 安装包和内核。若仍然失败，请保留终端中的第一条明确错误信息，并同时检查：

```sh
df -h
date
opkg update
```

使用 APK 包管理器的 Snapshot 系统，将最后一条替换为：

```sh
apk update
```

> [!NOTE]
> OpenClash 运行日志位于 `/tmp/openclash.log`。

---

## 📦 归档脚本

> [!WARNING]
> [`archived/`](archived/) 中的脚本已经停止维护，仅供历史查阅，不建议在当前系统中运行。具体列表和归档原因见 [`archived/README.md`](archived/README.md)。
