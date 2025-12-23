# 一键脚本  
一些方便的一键脚本，欢迎使用。   

---

## **check_cpu_version.sh**

**功能说明：** 检测系统 CPU 架构和指令集支持级别

该脚本用于检测当前系统的 CPU 架构，并输出标准化的架构名称：
- **非 x86 架构**：输出官方架构名（如 `arm64`、`armv7`、`mips64le`、`loong64` 等）
- **x86_64 架构**：输出 amd64 微架构级别（`amd64-v1` ~ `amd64-v4`）

**支持的架构映射：**
- `aarch64` → `arm64`
- `x86_64` → `amd64-v1/v2/v3/v4`（根据 CPU 指令集自动判断）
- `armv7l` → `armv7`
- `mips64el` → `mips64le`
- `loongarch64` → `loong64`
- 以及其他常见架构

**使用场景：** 适用于需要根据 CPU 能力选择合适的二进制文件或编译优化级别的场景（如编译 Go 程序、下载对应架构的预编译二进制等）。

**使用命令：**
```bash
sh check_cpu_version.sh
# 或在线执行
wget -qO- https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/check_cpu_version.sh | sh
```

**示例输出：**
```text
# ARM64 设备
linux-arm64

# x86_64 支持 AVX2 的设备
linux-amd64-v3

# MIPS 硬浮点设备
linux-mips-hardfloat

# LoongArch ABI2 设备
linux-loong64-abi2
```

---

## **install_openclash_dev.sh**

**功能说明：** 一键安装 OpenClash Dev 版本（基础版）

该脚本提供 OpenClash Dev 版本的快速安装功能，自动完成以下操作：
1. 检测系统包管理器（OPKG/APK）
2. 从官方仓库下载最新 Dev 版本安装包
3. 安装 OpenClash Dev
4. 配置更新分支为 Dev，启用 jsdelivr CDN 加速
5. 更新 Meta 内核至最新版本
6. 启动 OpenClash 服务

**兼容性：** 支持 OPKG（OpenWrt）和 APK（OpenWrt Snapshot）包管理器

**适用场景：** 适合已经配置好依赖环境，只需要安装或升级 OpenClash 本体和内核的用户。

**使用命令：**
```bash
wget -qO- https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/install_openclash_dev.sh | sh
```

---

## **install_openclash_dev_update.sh**

**功能说明：** 一键安装更新 OpenClash 为最新 Dev 版本（完整版）

这是功能最完整的 OpenClash Dev 自动化安装脚本，适合首次安装或完整更新。脚本会自动完成以下操作：

**主要功能：**
1. ✅ 检测系统包管理器（OPKG/APK）和防火墙架构（nftables/iptables）
2. ✅ 自动安装所有必需依赖（根据防火墙类型选择对应依赖包）
3. ✅ 下载并安装最新 OpenClash Dev 版本
4. ✅ 加载个性化配置（如果存在 `/etc/config/openclash-set`）
5. ✅ 配置更新分支为 Dev，启用 jsdelivr CDN 加速
6. ✅ 更新所有内核和数据库：
   - Meta 内核
   - Smart 内核模型（如果启用）
   - GeoIP Dat/MMDB 数据库
   - GeoSite 数据库
   - GeoASN 数据库
   - 大陆 IP 白名单
7. ✅ 更新订阅配置
8. ✅ 启动 OpenClash 服务

**特色功能：**
- **Smart 内核支持**：自动检测 Smart 内核模式，下载大型模型文件（Model-large.bin），使用国内 CDN 加速和阿里云 DoH 解析
- **个性化配置**：支持通过 `/etc/config/openclash-set` 脚本加载自定义配置
- **防火墙自适应**：根据系统防火墙类型（fw4/fw3/nftables/iptables）自动安装对应依赖

**兼容性：** 支持 OPKG（OpenWrt）和 APK（OpenWrt Snapshot）包管理器

**适用场景：** 
- 首次安装 OpenClash Dev
- 从 Master 版本切换到 Dev 版本
- 系统固件值守更新后恢复 Dev 版本
- 完整更新所有组件到最新状态

**使用命令：**
```bash
wget -qO- https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/shell/install_openclash_dev_update.sh | sh
```

---

## 归档文件夹

`archived/` 文件夹包含已弃用的脚本文件，保留用于历史参考。详情请查看 [archived/README.md](archived/README.md)。
