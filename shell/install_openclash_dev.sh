#!/bin/sh

# 定义变量
REPO_API_URL="https://api.github.com/repos/vernesong/OpenClash/contents/package/dev"
RAW_FILE_PREFIX="https://raw.githubusercontent.com/vernesong/OpenClash/refs/heads/package/dev"
TEMP_FILE="openclash.apk"

# 获取 .apk 文件名
APK_FILE=$(curl -s $REPO_API_URL | grep '"name":' | grep '.apk"' | sed 's/.*"name": "//;s/".*//')

# 检查是否成功获取文件名
if [ -z "$APK_FILE" ]; then
  echo "未找到 .apk 文件，请检查目录或网络连接。"
  exit 1
fi

# 构造下载链接
DOWNLOAD_URL="$RAW_FILE_PREFIX/$APK_FILE"

# 下载 .apk 文件
echo "正在下载 $APK_FILE..."
wget -O $TEMP_FILE $DOWNLOAD_URL
if [ $? -ne 0 ]; then
  echo "下载失败，请检查网络连接或下载链接：$DOWNLOAD_URL"
  exit 1
fi

# 安装 .apk 文件
echo "正在安装 $APK_FILE..."
apk add $TEMP_FILE --allow-untrusted
if [ $? -ne 0 ]; then
  echo "安装失败，请检查系统环境。"
  rm -f $TEMP_FILE
  exit 1
fi

# 清理临时文件
rm -f $TEMP_FILE
echo "安装完成！"