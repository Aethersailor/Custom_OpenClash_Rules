import subprocess
import pyperclip
import tldextract
import pygetwindow as gw
import time
import socket
import geoip2.database
import requests
import tempfile
import os
from datetime import datetime

# 颜色定义
COLORS = {
    "reset": "\033[0m",
    "cyan": "\033[96m",
    "green": "\033[92m",
    "yellow": "\033[93m",
    "red": "\033[91m",
    "bold": "\033[1m",
    "underline": "\033[4m"
}

# 输出样式模板
STYLES = {
    "info": f"{COLORS['cyan']}ℹ️  INFO{COLORS['reset']}",
    "success": f"{COLORS['green']}✅ SUCCESS{COLORS['reset']}",
    "warning": f"{COLORS['yellow']}⚠️  WARNING{COLORS['reset']}",
    "error": f"{COLORS['red']}❌ ERROR{COLORS['reset']}",
    "title": f"{COLORS['bold']}{COLORS['cyan']}",
    "divider": f"{COLORS['cyan']}{'='*60}{COLORS['reset']}"
}

# 非中国服务商关键词列表
NON_CHINA_PROVIDERS = [
    'cloudflare', 'aws', 'google', 'gandi', 'dnsowl', 'domaincontrol', 
    'he.net', 'name.com', 'azure', 'share-dns', 'station188',
    'cloudcone.net', 'siteground.net', 'registrar-servers', 'foundationdns.org'
]

# GEOIP数据库URL
GEOIP_DB_URL = 'https://raw.githubusercontent.com/Loyalsoldier/geoip/release/GeoLite2-Country.mmdb'

def get_config_path():
    """获取配置文件路径"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.join(script_dir, "dnsmasq-china-list")
    config_path = os.path.join(target_dir, "accelerated-domains.china.conf")
    
    if not os.path.exists(target_dir):
        print_status(STYLES['error'], f"目标目录不存在: {target_dir}")
        print_status(STYLES['info'], "请确保脚本与dnsmasq-china-list目录处于同一级")
        return None
    
    if not os.path.exists(config_path):
        print_status(STYLES['error'], f"配置文件不存在: {config_path}")
        print_status(STYLES['info'], "请确保accelerated-domains.china.conf文件存在")
        return None
    
    return config_path

def print_section(title):
    """打印分节标题"""
    print(f"\n{STYLES['divider']}")
    print(f"{STYLES['title']}{title.upper()}{COLORS['reset']}")
    print(f"{STYLES['divider']}\n")

def print_status(style, message):
    """带样式的状态输出"""
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {style}: {message}")

def extract_domain(url):
    """提取主域名"""
    ext = tldextract.extract(url)
    return f"{ext.domain}.{ext.suffix}"

def get_ip_from_ns(ns_domain):
    """解析NS服务器IP"""
    try:
        return socket.gethostbyname(ns_domain)
    except socket.gaierror as e:
        print_status(STYLES['error'], f"DNS解析失败 [{ns_domain}]: {e}")
        return None

def get_geo_info(ip_address, geoip_db_path):
    """查询IP归属地"""
    try:
        with geoip2.database.Reader(geoip_db_path) as reader:
            return reader.country(ip_address).country.name
    except Exception as e:
        print_status(STYLES['error'], f"归属地查询失败 [{ip_address}]: {e}")
        return None

def download_geoip_db():
    """下载GEOIP数据库"""
    try:
        print_section("初始化地理数据库")
        temp_dir = tempfile.gettempdir()
        geoip_db_path = os.path.join(temp_dir, 'GeoLite2-Country.mmdb')
        
        if os.path.exists(geoip_db_path):
            os.remove(geoip_db_path)
            print_status(STYLES['info'], "已清理旧版地理数据库")

        print_status(STYLES['info'], "开始下载最新地理数据库...")
        response = requests.get(GEOIP_DB_URL, stream=True)
        response.raise_for_status()

        total_size = int(response.headers.get('content-length', 0))
        with open(geoip_db_path, 'wb') as f:
            downloaded = 0
            for chunk in response.iter_content(chunk_size=8192):
                f.write(chunk)
                downloaded += len(chunk)
                progress = downloaded / total_size * 100 if total_size > 0 else 100
                print(f"\r下载进度: {progress:.1f}%", end='')
        print("\n")
        return geoip_db_path
    except Exception as e:
        print_status(STYLES['error'], f"数据库下载失败: {e}")
        return None

def check_non_china_provider(ns_domain):
    """检查非中国服务商"""
    return any(provider in ns_domain.lower() for provider in NON_CHINA_PROVIDERS)

def validate_ns_records(new_domain, geoip_db_path):
    """验证NS记录有效性"""
    print_section("域名验证流程")
    print_status(STYLES['info'], f"开始验证域名: {new_domain}")
    
    try:
        result = subprocess.run(
            ['nslookup', '-type=NS', new_domain],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        
        ns_servers = [
            line.split('=')[-1].strip().rstrip('.') 
            for line in result.stdout.splitlines() 
            if "nameserver" in line.lower()
        ]
        
        if not ns_servers:
            print_status(STYLES['warning'], "未找到有效的NS记录")
            return False

        for idx, ns_domain in enumerate(ns_servers, 1):
            print_status(STYLES['info'], f"验证NS服务器 ({idx}/{len(ns_servers)})：{ns_domain}")
            
            if check_non_china_provider(ns_domain):
                print_status(STYLES['warning'], f"检测到非中国服务商：{ns_domain}")
                return False
            
            ip_address = get_ip_from_ns(ns_domain)
            if not ip_address:
                return False
            
            country = get_geo_info(ip_address, geoip_db_path)
            if not country:
                return False
            if country != "China":
                print_status(STYLES['warning'], f"非中国归属地: {country}")
                return False
            print_status(STYLES['success'], f"验证通过: {ip_address} ({country})")
        
        return True
        
    except subprocess.CalledProcessError as e:
        print_status(STYLES['error'], f"NS查询失败: {e.stderr}")
        return False

def check_existing_entry(file_path, new_domain):
    """检查规则是否已存在"""
    entry = f"server=/{new_domain}/114.114.114.114"
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return any(line.strip().startswith(entry) for line in f)
    except Exception as e:
        print_status(STYLES['error'], f"文件读取失败: {e}")
        return True

def find_insert_position(lines, new_domain):
    """找到正确的插入位置"""
    new_entry = f"server=/{new_domain}/114.114.114.114"
    for i, line in enumerate(lines):
        line = line.strip()
        # 只处理有效的规则行
        if line.startswith("server=/") and line.endswith("/114.114.114.114"):
            existing_domain = line.split('/')[1]
            if existing_domain > new_domain:
                return i
    return len(lines)  # 如果没有更大的域名，插入到末尾

def insert_domain():
    print_section("dnsmasq-china-list 规则修改工具启动")
    print(f"{STYLES['title']}版本: 2.4 | 作者: Aethersailor | 协议: MIT{COLORS['reset']}\n")
    
    config_path = get_config_path()
    if not config_path:
        return

    geoip_db_path = download_geoip_db()
    if not geoip_db_path:
        return

    while True:
        try:
            user_input = input(f"\n{COLORS['cyan']}请输入域名/URL（或输入 exit 退出）{COLORS['reset']}: ").strip()
            
            if user_input.lower() == 'exit':
                print_section("程序退出")
                print_status(STYLES['info'], "感谢使用！")
                break

            new_domain = extract_domain(user_input)
            if new_domain.endswith('.cn'):
                print_status(STYLES['warning'], ".cn域名自动跳过")
                continue
                
            if check_existing_entry(config_path, new_domain):
                print_status(STYLES['warning'], "规则已存在，跳过处理")
                continue
                
            if validate_ns_records(new_domain, geoip_db_path):
                with open(config_path, 'r+', encoding='utf-8') as f:
                    lines = f.readlines()
                    new_entry = f"server=/{new_domain}/114.114.114.114\n"
                    
                    # 找到插入位置
                    insert_pos = find_insert_position(lines, new_domain)
                    lines.insert(insert_pos, new_entry)
                    
                    f.seek(0)
                    f.writelines(lines)
                    f.truncate()
                    
                    pyperclip.copy(f"accelerated-domains: {new_domain}")
                    print_status(STYLES['success'], f"已添加并复制到剪贴板")
                    
                    if gw.getWindowsWithTitle('GitHub Desktop'):
                        gw.getWindowsWithTitle('GitHub Desktop')[0].activate()
                        print_status(STYLES['info'], "已激活GitHub Desktop窗口")
            else:
                print_status(STYLES['error'], "域名验证未通过，跳过添加")
                
        except KeyboardInterrupt:
            print_status(STYLES['error'], "操作已中止")
            break

if __name__ == "__main__":
    insert_domain()