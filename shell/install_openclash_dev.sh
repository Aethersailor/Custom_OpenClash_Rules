#!/bin/sh

# 定义变量
REPO_API_URL="https://api.github.com/repos/vernesong/OpenClash/contents/dev?ref=package"
RAW_FILE_PREFIX="https://testingcf.jsdelivr.net/gh/vernesong/OpenClash@refs/heads/package/dev"

# 清空屏幕并显示欢迎信息
clear
echo "##########################################################"
echo "#                Custom_OpenClash_Rules                  #"
echo "# https://github.com/Aethersailor/Custom_OpenClash_Rules #"
echo "##########################################################"
sleep 1
echo "OpenClash dev 一键安装/更新脚本开始运行..."
echo "即将安装/升级插件和内核至最新 dev 版本"
sleep 1

# 检测系统使用的包管理器，并设置对应后缀和安装命令
if command -v opkg >/dev/null 2>&1; then
    PKG_MGR="opkg"
    EXT="ipk"
    INSTALL_CMD="opkg install --force-reinstall"
    echo "检测到包管理器：OPKG (OpenWrt 传统版本)"
elif command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
    EXT="apk"
    INSTALL_CMD="apk add -q --force-overwrite --clean-protected --allow-untrusted"
    echo "检测到包管理器：APK (OpenWrt Snapshot 新版本)"
else
    echo "错误：未检测到支持的包管理器"
    echo "支持的包管理器："
    echo "  - OPKG (OpenWrt 传统版本)"
    echo "  - APK  (OpenWrt Snapshot 新版本)"
    echo "请确保在支持的系统上运行此脚本。"
    exit 1
fi

echo "准备下载 .$EXT 包。"

# 获取 JSON 数据并解析对应后缀的文件名
echo "正在从 OpenClash 官方仓库读取 dev 版本文件信息..."
JSON_OUTPUT=$(curl -s "$REPO_API_URL")
FILE_NAME=$(echo "$JSON_OUTPUT" \
    | grep -oE '"name":\s*"[^"]+\.'"$EXT"'"' \
    | sed -E 's/.*"([^"]+)".*/\1/' \
    | head -n 1)

if [ -z "$FILE_NAME" ]; then
    echo "未找到 .$EXT 文件，请检查目录或网络连接。"
    exit 1
fi

echo "解析到的文件名：$FILE_NAME"

# 构造下载链接和临时文件名
DOWNLOAD_URL="$RAW_FILE_PREFIX/$FILE_NAME"
TEMP_FILE="openclash.$EXT"

# 下载对应包
echo "正在从 OpenClash 官方仓库下载 dev 版本 $FILE_NAME..."
wget -q -O "$TEMP_FILE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "下载失败，请检查网络连接或下载链接：$DOWNLOAD_URL"
    exit 1
fi

# 下载成功提示
echo "下载成功：$TEMP_FILE"

# 安装对应包
echo "正在使用 $PKG_MGR 安装 $FILE_NAME..."
$INSTALL_CMD "$TEMP_FILE"
RET=$?

if [ $RET -ne 0 ]; then
    echo "OpenClash Dev 安装失败，请检查系统环境。"
    rm -f "$TEMP_FILE"
    exit 1
fi

# 安装成功提示
echo "OpenClash Dev 最新版安装成功！"

# 清理临时文件
rm -f "$TEMP_FILE"

# 执行配置命令
echo "更新 OpenClash 设置..."
uci set openclash.config.release_branch=dev
uci set openclash.config.skip_safe_path_check=1
uci set openclash.config.github_address_mod='https://testingcf.jsdelivr.net/'
uci commit openclash
if [ $? -ne 0 ]; then
  echo "设置更新失败，请检查命令和日志。"
  exit 1
fi
echo "设置更新完成！已切换 OpenClash 更新分支为 Developer，并使用 https://testingcf.jsdelivr.net/ 加速访问 GitHub。"

# 开始更新 Meta 内核
echo "开始更新 Meta 内核..."
/usr/share/openclash/openclash_core.sh
if [ $? -ne 0 ]; then
  echo "Meta 内核更新失败，请检查日志。"
  exit 1
fi
echo "Meta 内核更新完成！"

sleep 3
echo "启动 OpenClash ..."
uci set openclash.config.enable='1'
uci commit openclash
/etc/init.d/openclash restart >/dev/null 2>&1
echo "脚本运行完毕！"
