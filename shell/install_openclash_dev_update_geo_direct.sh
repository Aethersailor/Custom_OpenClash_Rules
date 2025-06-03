#!/bin/sh

# 定义变量
REPO_API_URL="https://api.github.com/repos/vernesong/OpenClash/contents/dev?ref=package"
RAW_FILE_PREFIX="https://raw.githubusercontent.com/vernesong/OpenClash/package/dev"
TEMP_FILE="openclash.apk"

# 获取 JSON 数据并解析 .apk 文件名
echo "正在获取 dev 版本文件信息..."
JSON_OUTPUT=$(curl -s $REPO_API_URL)
APK_FILE=$(echo "$JSON_OUTPUT" | awk -F'"' '/"name":/ && /.apk"/ {print $4}' | head -n 1)

# 打印调试信息
#echo "API 输出内容:"
#echo "$JSON_OUTPUT"
echo "解析到的文件名: $APK_FILE"

# 检查是否成功获取文件名
if [ -z "$APK_FILE" ]; then
  echo "未找到 .apk 文件，请检查目录或网络连接。"
  exit 1
fi

# 构造下载链接
DOWNLOAD_URL="$RAW_FILE_PREFIX/$APK_FILE"

# 下载 .apk 文件
echo "正在下载 dev 版本 $APK_FILE..."
wget -O $TEMP_FILE $DOWNLOAD_URL
if [ $? -ne 0 ]; then
  echo "下载失败，请检查网络连接或下载链接：$DOWNLOAD_URL"
  exit 1
fi

# 安装 .apk 文件
echo "正在安装 $APK_FILE..."
apk add -q --force-overwrite --clean-protected --allow-untrusted $TEMP_FILE
if [ $? -ne 0 ]; then
  echo "OpenClash Dev 安装失败，请检查系统环境。"
  rm -f $TEMP_FILE
  exit 1
fi

# 执行配置命令
echo "正在更新配置，切换为 Dev 版本并开启“跳过安全路径检查”..."
uci set openclash.config.release_branch=dev
uci set openclash.config.skip_safe_path_check=1
uci commit openclash
if [ $? -ne 0 ]; then
  echo "配置更新失败，请检查命令和日志。"
  exit 1
fi
echo "配置更新完成！"

# 清理临时文件
rm -f $TEMP_FILE
echo "OpenClash 最新 dev 版本安装完成！"

# 开始更新 Meta 内核
echo "开始更新 Meta 内核..."
/usr/share/openclash/openclash_core.sh
if [ $? -ne 0 ]; then
  echo "Meta 内核更新失败，请检查日志。"
  exit 1
fi
echo "Meta 内核更新完成！"

# 开始更新 GeoIP 数据库
echo "开始更新 GeoIP Dat 数据库..."
/usr/share/openclash/openclash_geoip.sh
if [ $? -ne 0 ]; then
  echo "GeoIP Dat 数据库更新失败，请检查日志。"
  exit 1
fi
echo "GeoIP Dat 数据库更新完成！"

# 开始更新 IP 数据库
echo "开始更新 GeoIP MMDB 数据库..."
/usr/share/openclash/openclash_ipdb.sh
if [ $? -ne 0 ]; then
  echo "GeoIP MMDB 数据库更新失败，请检查日志。"
  exit 1
fi
echo "GeoIP MMDB 数据库更新完成！"

# 开始更新 GeoSite 数据库
echo "开始更新 GeoSite 数据库..."
/usr/share/openclash/openclash_geosite.sh
if [ $? -ne 0 ]; then
  echo "GeoSite 数据库更新失败，请检查日志。"
  exit 1
fi
echo "GeoSite 数据库更新完成！"

# 开始更新 GeoASN 数据库
echo "开始更新 GeoASN 数据库..."
/usr/share/openclash/openclash_geoasn.sh
if [ $? -ne 0 ]; then
  echo "GeoASN 数据库更新失败，请检查日志。"
  exit 1
fi
echo "GeoASN 数据库更新完成！"

# 开始更新大陆白名单
echo "开始更新大陆白名单..."
/usr/share/openclash/openclash_chnroute.sh
if [ $? -ne 0 ]; then
  echo "大陆白名单更新失败，请检查日志。"
  exit 1
fi
echo "大陆白名单更新完成！"

# 开始更新订阅
echo "正在更新订阅..."
/usr/share/openclash/openclash.sh
if [ $? -ne 0 ]; then
  echo "订阅更新失败，请检查日志。"
  exit 1
fi
echo "订阅更新完成！"

sleep 3
echo "启动 OpenClash ..."
/etc/init.d/openclash restart >/dev/null 2>&1
