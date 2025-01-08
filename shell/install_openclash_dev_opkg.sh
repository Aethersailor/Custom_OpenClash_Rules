#!/bin/sh

# 定义变量
REPO_API_URL="https://api.github.com/repos/vernesong/OpenClash/contents/dev?ref=package"
RAW_FILE_PREFIX="https://gh-proxy.com/https://raw.githubusercontent.com/vernesong/OpenClash/package/dev"
TEMP_FILE="openclash.ipk"

# 获取 JSON 数据并解析 .ipk 文件名
echo "正在获取文件信息..."
JSON_OUTPUT=$(curl -s $REPO_API_URL)
IPK_FILE=$(echo "$JSON_OUTPUT" | awk -F'"' '/"name":/ && /.ipk"/ {print $4}' | head -n 1)

# 打印调试信息
echo "API 输出内容:"
echo "$JSON_OUTPUT"
echo "解析到的文件名: $IPK_FILE"

# 检查是否成功获取文件名
if [ -z "$IPK_FILE" ]; then
  echo "未找到 .ipk 文件，请检查目录或网络连接。"
  exit 1
fi

# 构造下载链接
DOWNLOAD_URL="$RAW_FILE_PREFIX/$IPK_FILE"

# 下载 .ipk 文件
echo "正在下载 $IPK_FILE..."
wget -O $TEMP_FILE $DOWNLOAD_URL
if [ $? -ne 0 ]; then
  echo "下载失败，请检查网络连接或下载链接：$DOWNLOAD_URL"
  exit 1
fi

# 安装 .ipk 文件
echo "正在安装 $IPK_FILE..."
opkg upgrade $TEMP_FILE --force-reinstall
if [ $? -ne 0 ]; then
  echo "安装失败，请检查系统环境。"
  rm -f $TEMP_FILE
  exit 1
fi

# 清理临时文件
rm -f $TEMP_FILE
echo "OpenClash 最新 dev 版本安装完成！"

echo "正在更新配置，切换为 Dev 版本..."
uci set openclash.config.release_branch=dev
uci commit openclash
if [ $? -ne 0 ]; then
  echo "配置更新失败，请检查命令和日志。"
  exit 1
fi
echo "配置更新完成！"

# 开始更新 Meta 内核
echo "开始更新 Meta 内核..."
/usr/share/openclash/openclash_core.sh
if [ $? -ne 0 ]; then
  echo "Meta 内核更新失败，请检查日志。"
  exit 1
fi

# 完成更新提示
echo "Meta 内核更新完成！"
