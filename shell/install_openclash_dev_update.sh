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
echo
sleep 1
echo "OpenClash dev 一键安装/更新脚本开始运行..."
echo "即将安装/升级插件和内核至最新 dev 版本，并更新所有数据库、白名单、订阅至最新版"
echo
sleep 1

# 检测系统使用的包管理器，并设置对应后缀和安装命令
echo "--------------------[ 检查包管理器 ]--------------------"
# 检测 OPKG 包管理器
if command -v opkg >/dev/null 2>&1; then
    PKG_MGR="opkg"
    EXT="ipk"
    INSTALL_CMD="opkg install --force-reinstall"
    echo "检测到包管理器：OPKG"
# 检测 APK 包管理器
elif command -v apk >/dev/null 2>&1; then
    PKG_MGR="apk"
    EXT="apk"
    INSTALL_CMD="apk add -q --force-overwrite --clean-protected --allow-untrusted"
    echo "检测到包管理器：APK"
else
    echo "未检测到 OPKG 或 APK，无法继续安装。"
    exit 1
fi

echo "准备下载 .$EXT 包。"
echo 

# 获取 JSON 数据并解析对应后缀的文件名
echo "--------------------[ 获取包信息 ]----------------------"
echo "正在从 OpenClash 官方仓库读取 dev 版本文件信息..."
# 获取 JSON 数据
JSON_OUTPUT=$(wget -qO- "$REPO_API_URL")
# 解析 JSON 数据，获取文件名
FILE_NAME=$(echo "$JSON_OUTPUT" \
    | grep -oE '"name":\s*"[^\"]+\.'"$EXT"'"' \
    | sed -E 's/.*"([^\"]+)".*/\1/' \
    | head -n 1)
# 判断文件名是否为空
if [ -z "$FILE_NAME" ]; then
    echo "未找到 .$EXT 文件，请检查目录或网络连接。"
    exit 1
fi
# 输出文件名
echo "解析到的文件名：$FILE_NAME"
# 构造下载链接和临时文件名
DOWNLOAD_URL="$RAW_FILE_PREFIX/$FILE_NAME"
TEMP_FILE="openclash.$EXT"
echo 

# 下载对应包
echo "--------------------[ 下载 OpenClash 包 ]----------------"
echo "正在从 OpenClash 官方仓库下载 dev 版本 $FILE_NAME..."
wget --show-progress --progress=bar:force:noscroll -O "$TEMP_FILE" "$DOWNLOAD_URL" 2>/dev/null || wget -O "$TEMP_FILE" "$DOWNLOAD_URL"
if [ $? -ne 0 ]; then
    echo "下载失败，请检查网络连接或下载链接：$DOWNLOAD_URL"
    exit 1
fi

# 下载成功提示
echo "下载成功：$TEMP_FILE"
echo 

# 安装对应包
echo "--------------------[ 安装 OpenClash 包 ]----------------"
echo "正在使用 $PKG_MGR 安装 $FILE_NAME..."
# 使用包管理器安装对应包
$INSTALL_CMD "$TEMP_FILE"
RET=$?
# 判断安装是否成功
if [ $RET -ne 0 ]; then
    echo "OpenClash dev 安装失败，请检查系统环境。"
    rm -f "$TEMP_FILE"
    exit 1
fi
# 安装成功提示
echo "OpenClash dev 最新版安装成功！"
echo 

# OpenClash 包安装完成后，更新 Smart 内核模型
echo "--------------------[ 更新 Smart 内核模型 ]----------------"
if [ $RET -eq 0 ]; then
  SMART_ENABLE=$(uci get openclash.config.smart_enable 2>/dev/null)
  if [ "$SMART_ENABLE" = "1" ]; then
    echo "检测到 Smart 内核已开启。"
    echo "正在下载 Smart 内核模型文件..."

    # 使用固定的 Model-large.bin 下载地址
    MODEL_URL="https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model-large.bin"
    MODEL_PATH="/etc/openclash/Model.bin"
    MODEL_URL_GHPROXY="https://gh-proxy.com/github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model-large.bin"
    MODEL_URL_GHFAST="https://ghfast.top/https://github.com/vernesong/mihomo/releases/download/LightGBM-Model/Model-large.bin"

    echo "正在测试加速链接速度..."
    
    # 同时测试两个 CDN 速度
    GHFAST_START=$(date +%s)
    GHPROXY_START=$(date +%s)
    
    # 后台同时运行两个测速
    wget -q --timeout=5 --spider "$MODEL_URL_GHFAST" 2>&1 &
    GHFAST_PID=$!
    wget -q --timeout=5 --spider "$MODEL_URL_GHPROXY" 2>&1 &
    GHPROXY_PID=$!
    
    # 等待5秒或进程结束
    sleep 5
    
    # 检查进程是否还在运行，如果还在运行则强制结束
    if kill -0 $GHFAST_PID 2>/dev/null; then
      kill $GHFAST_PID 2>/dev/null
      GHFAST_RET=1
    else
      wait $GHFAST_PID
      GHFAST_RET=$?
    fi
    
    if kill -0 $GHPROXY_PID 2>/dev/null; then
      kill $GHPROXY_PID 2>/dev/null
      GHPROXY_RET=1
    else
      wait $GHPROXY_PID
      GHPROXY_RET=$?
    fi
    
    # 计算实际耗时
    GHFAST_END=$(date +%s)
    GHPROXY_END=$(date +%s)
    GHFAST_TIME=$((GHFAST_END - GHFAST_START))
    GHPROXY_TIME=$((GHPROXY_END - GHPROXY_START))
    
    # 检查连接结果并设置时间
    if [ $GHFAST_RET -eq 0 ]; then
      GHFAST_AVAILABLE=1
    else
      GHFAST_TIME=999
      GHFAST_AVAILABLE=0
    fi
    
    if [ $GHPROXY_RET -eq 0 ]; then
      GHPROXY_AVAILABLE=1
    else
      GHPROXY_TIME=999
      GHPROXY_AVAILABLE=0
    fi
    
    # 选择最快的链接（排除超时情况）
    if [ "$GHFAST_TIME" = "999" ] && [ "$GHPROXY_TIME" = "999" ]; then
      FASTEST_URL="$MODEL_URL_GHFAST"
      FASTEST_NAME="ghfast.top"
    elif [ "$GHFAST_TIME" = "999" ]; then
      FASTEST_URL="$MODEL_URL_GHPROXY"
      FASTEST_NAME="gh-proxy.com"
    elif [ "$GHPROXY_TIME" = "999" ]; then
      FASTEST_URL="$MODEL_URL_GHFAST"
      FASTEST_NAME="ghfast.top"
    elif [ "$(echo "$GHFAST_TIME < $GHPROXY_TIME" | bc 2>/dev/null || echo "0")" = "1" ]; then
      FASTEST_URL="$MODEL_URL_GHFAST"
      FASTEST_NAME="ghfast.top"
    else
      FASTEST_URL="$MODEL_URL_GHPROXY"
      FASTEST_NAME="gh-proxy.com"
    fi
    
    echo "尝试通过 GitHub 反代 CDN（$FASTEST_NAME）下载内核模型文件..."
    wget --show-progress --progress=bar:force:noscroll -T 30 -O "$MODEL_PATH" "$FASTEST_URL" 2>/dev/null || wget -T 30 -O "$MODEL_PATH" "$FASTEST_URL"
    if [ $? -eq 0 ]; then
      echo "Smart 内核模型文件下载成功（$FASTEST_NAME）：$MODEL_PATH"
    else
      echo "$FASTEST_NAME 下载失败，尝试另一个加速链接..."
      if [ "$FASTEST_NAME" = "ghfast.top" ]; then
        FALLBACK_URL="$MODEL_URL_GHPROXY"
        FALLBACK_NAME="gh-proxy.com"
      else
        FALLBACK_URL="$MODEL_URL_GHFAST"
        FALLBACK_NAME="ghfast.top"
      fi
      
      echo "尝试通过 GitHub 反代 CDN（$FALLBACK_NAME）下载内核模型文件..."
      wget --show-progress --progress=bar:force:noscroll -T 30 -O "$MODEL_PATH" "$FALLBACK_URL" 2>/dev/null || wget -T 30 -O "$MODEL_PATH" "$FALLBACK_URL"
      if [ $? -eq 0 ]; then
        echo "Smart 内核模型文件下载成功（$FALLBACK_NAME）：$MODEL_PATH"
      else
        echo "反代 CDN 均失败，尝试通过 GitHub 直链下载..."
        wget --show-progress --progress=bar:force:noscroll -T 30 -O "$MODEL_PATH" "$MODEL_URL" 2>/dev/null || wget -T 30 -O "$MODEL_PATH" "$MODEL_URL"
        if [ $? -eq 0 ]; then
          echo "Smart 内核模型文件下载成功（GitHub 直链）：$MODEL_PATH"
        else
          echo "所有方式均失败，Smart 内核启动时会自动下载模型文件。"
        fi
      fi
    fi
  else
    echo "检测到 Smart 内核未启用。"
  fi
fi
echo 

# 清理临时文件
rm -f "$TEMP_FILE"

# 加载 OpenClash 预设配置（如果存在）
echo "--------------------[ 加载个性化预设配置 ]----------------"
if [ -f /etc/config/openclash-set ]; then
  echo "检测到个性化预设配置文件，正在加载..."
  # 请将 预设配置以 shell 的方式写入 /etc/config/openclash-set 文件
  sh /etc/config/openclash-set
  if [ $? -ne 0 ]; then
    echo "加载个性化预设配置时出现错误，请检查 /etc/config/openclash-set 内容。"
    exit 1
  fi
  echo "个性化预设配置加载完成！"
fi
echo 

# 执行配置命令
echo "--------------------[ 更新 OpenClash 设置 ]----------------"
echo "更新 OpenClash 设置..."
# 切换到 dev 分支
uci set openclash.config.release_branch=dev
# 关闭面板路径检查
uci set openclash.config.skip_safe_path_check=1
# 设置使用 jsdelivr 加速访问 GitHub
uci set openclash.config.github_address_mod='https://testingcf.jsdelivr.net/'
# 提交配置
uci commit openclash
if [ $? -ne 0 ]; then
  echo "设置更新失败，请检查命令和日志。"
  exit 1
fi
echo "设置更新完成！已切换 OpenClash 更新分支为 Developer，并使用 https://testingcf.jsdelivr.net/ 加速访问 GitHub。"
echo 

# 调用 OpenClash 自带脚本更新内核
echo "--------------------[ 更新内核 ]--------------------------"
echo "开始更新内核..."
/usr/share/openclash/openclash_core.sh
if [ $? -ne 0 ]; then
  echo "内核更新失败，请检查日志。"
  exit 1
fi
echo "内核更新完成！"
echo 

# 调用 OpenClash 自带脚本更新 GeoIP Dat 数据库
echo "--------------------[ 更新 GeoIP Dat 数据库 ]-------------"
echo "开始更新 GeoIP Dat 数据库..."
/usr/share/openclash/openclash_geoip.sh
if [ $? -ne 0 ]; then
  echo "GeoIP Dat 数据库更新失败，请检查日志。"
  exit 1
fi
echo "GeoIP Dat 数据库更新完成！"
echo 

# 调用 OpenClash 自带脚本更新 GeoIP MMDB 数据库
echo "--------------------[ 更新 GeoIP MMDB 数据库 ]------------"
echo "开始更新 GeoIP MMDB 数据库..."
/usr/share/openclash/openclash_ipdb.sh
if [ $? -ne 0 ]; then
  echo "GeoIP MMDB 数据库更新失败，请检查日志。"
  exit 1
fi
echo "GeoIP MMDB 数据库更新完成！"
echo 

# 调用 OpenClash 自带脚本更新 GeoSite 数据库
echo "--------------------[ 更新 GeoSite 数据库 ]---------------"
echo "开始更新 GeoSite 数据库..."
/usr/share/openclash/openclash_geosite.sh
if [ $? -ne 0 ]; then
  echo "GeoSite 数据库更新失败，请检查日志。"
  exit 1
fi
echo "GeoSite 数据库更新完成！"
echo 

# 调用 OpenClash 自带脚本更新 GeoASN 数据库
echo "--------------------[ 更新 GeoASN 数据库 ]----------------"
echo "开始更新 GeoASN 数据库..."
/usr/share/openclash/openclash_geoasn.sh
if [ $? -ne 0 ]; then
  echo "GeoASN 数据库更新失败，请检查日志。"
  exit 1
fi
echo "GeoASN 数据库更新完成！"
echo 

# 调用 OpenClash 自带脚本更新大陆 IP白名单
echo "--------------------[ 更新大陆 IP白名单 ]--------------------"
echo "开始更新大陆 IP 白名单..."
/usr/share/openclash/openclash_chnroute.sh
if [ $? -ne 0 ]; then
  echo "大陆 IP 白名单更新失败，请检查日志。"
  exit 1
fi
echo "大陆 IP 白名单更新完成！"
echo 

# 调用 OpenClash 自带脚本更新订阅
echo "--------------------[ 更新订阅 ]--------------------------"
echo "正在更新订阅..."
echo 
/usr/share/openclash/openclash.sh
if [ $? -ne 0 ]; then
  echo "订阅更新失败，请检查日志。"
  exit 1
fi
echo 
echo "订阅更新完成！"
echo 

sleep 3
echo "--------------------[ 启动插件 ]--------------------------"
echo "启动 OpenClash ..."
# 设置 OpenClash 开机自启
uci set openclash.config.enable='1'
# 提交配置
uci commit openclash
# 启动 OpenClash
/etc/init.d/openclash restart >/dev/null 2>&1
echo "OpenClash 启动完成！"
echo 
echo "脚本运行完毕！"
