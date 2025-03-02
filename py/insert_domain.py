import sys
import subprocess
import pyperclip
import tldextract
import pygetwindow as gw
import socket
import geoip2.database
import requests
import tempfile
import os
import json
import base64
import dns.message
from datetime import datetime
from urllib.parse import urlencode
import urllib3

# 禁用SSL警告
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 新增：IPv4地址验证函数
def is_valid_ipv4(address):
    """严格验证IPv4地址格式"""
    try:
        socket.inet_pton(socket.AF_INET, address)
        return True
    except (socket.error, OSError):
        return False

# 检查并安装依赖（已修复）
def check_dependencies():
    required = {
        'pyperclip': 'pyperclip',
        'tldextract': 'tldextract',
        'pygetwindow': 'pygetwindow',
        'geoip2': 'geoip2',
        'requests': 'requests',
        'pyautogui': 'pyautogui',
        'dns': 'dnspython'
    }
    
    missing = []
    for pkg in required:
        try:
            __import__(pkg)
        except ImportError:
            missing.append(required[pkg])
    
    if missing:
        print("\n正在安装缺失依赖...")
        subprocess.check_call(
            [sys.executable, '-m', 'pip', 'install', *missing],
            stdout=subprocess.DEVNULL
        )
        print("依赖安装完成，请重新运行脚本\n")
        sys.exit(1)

check_dependencies()

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

STYLES = {
    "info": f"{COLORS['cyan']}ℹ️  INFO{COLORS['reset']}",
    "success": f"{COLORS['green']}✅ SUCCESS{COLORS['reset']}",
    "warning": f"{COLORS['yellow']}⚠️  WARNING{COLORS['reset']}",
    "error": f"{COLORS['red']}❌ ERROR{COLORS['reset']}",
    "title": f"{COLORS['bold']}{COLORS['cyan']}",
    "divider": f"{COLORS['cyan']}{'='*60}{COLORS['reset']}"
}

NON_CHINA_PROVIDERS = [
    'cloudflare', 'aws', 'google', 'cloudns.net', 'gandi', 
    'dnsowl', 'domaincontrol', 'he.net', 'name.com', 'azure',
    'share-dns', 'station188', 'cloudcone.net', 'siteground.net',
    'registrar-servers', 'foundationdns.org', 'fastly', 'akamai', 'incapsula',
    'vercel-dns.com'
]

DOH_SERVERS = [
    {
        'host': 'dns.alidns.com',
        'path': '/dns-query',
        'params_type': 'dns-wire'
    },
    {
        'host': 'doh.pub',
        'path': '/dns-query',
        'params_type': 'standard'
    },
    {
        'host': 'dns.qq.com',
        'path': '/resolve',
        'params_type': 'standard'
    }
]

DOH_HEADERS = {
    'accept': 'application/dns-json'
}

GEOIP_DB_URL = 'https://raw.githubusercontent.com/Loyalsoldier/geoip/release/GeoLite2-Country.mmdb'

def resolve_doh_ip(domain):
    """使用223.5.5.5解析DoH服务器地址（强制IPv4）"""
    try:
        result = subprocess.run(
            ['nslookup', '-type=A', domain, '223.5.5.5'],
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        
        lines = result.stdout.split('\n')
        for line in lines:
            if 'Addresses:' in line:
                return line.split()[-1]
            elif 'Address:' in line and '223.5.5.5' not in line:
                return line.split()[-1]
        return None
    except subprocess.CalledProcessError as e:
        print_status(STYLES['error'], f"解析失败 {domain}: {e.stderr}")
        return None

def query_ns_with_doh(domain):
    """使用DNS-over-HTTPS查询NS记录"""
    for server in DOH_SERVERS:
        print_status(STYLES['info'], f"尝试DoH服务器: {server['host']}")
        ip = resolve_doh_ip(server['host'])
        if not ip:
            continue

        try:
            if server['params_type'] == 'dns-wire':
                query = dns.message.make_query(domain, 'NS')
                params = {
                    'dns': base64.b64encode(query.to_wire()).decode('utf-8')
                }
            else:
                params = {'name': domain, 'type': 'NS'}

            url = f"https://{ip}{server['path']}"
            headers = {'Host': server['host']}
            headers.update(DOH_HEADERS)
            
            response = requests.get(
                url,
                params=params,
                headers=headers,
                timeout=5,
                verify=False,
                allow_redirects=False
            )
            
            if response.status_code == 200:
                data = response.json() if server['params_type'] == 'standard' else parse_dns_wire(response.content)
                return process_doh_response(data)
            else:
                print_status(STYLES['warning'], f"异常响应 [{response.status_code}]: {response.text[:200]}")

        except requests.exceptions.SSLError as e:
            print_status(STYLES['error'], f"SSL证书错误: {str(e)}")
        except Exception as e:
            print_status(STYLES['warning'], f"{server['host']} 查询失败: {str(e)}")
            continue
            
    print_status(STYLES['error'], "所有DoH服务器查询失败")
    return None

def parse_dns_wire(data):
    """解析DNS wire格式响应"""
    msg = dns.message.from_wire(data)
    result = {'Answer': [], 'Authority': []}
    
    for rrset in msg.answer:
        if rrset.rdtype == dns.rdatatype.NS:
            for item in rrset:
                result['Answer'].append({
                    'type': 2,
                    'data': str(item.target).rstrip('.')
                })
    
    for rrset in msg.authority:
        if rrset.rdtype == dns.rdatatype.NS:
            for item in rrset:
                result['Authority'].append({
                    'type': 2,
                    'data': str(item.target).rstrip('.')
                })
    
    return result

def query_a_with_doh(domain):
    """严格查询IPv4地址"""
    for server in DOH_SERVERS:
        ip = resolve_doh_ip(server['host'])
        if not ip:
            continue

        try:
            if server['params_type'] == 'dns-wire':
                query = dns.message.make_query(domain, 'A')
                params = {
                    'dns': base64.b64encode(query.to_wire()).decode('utf-8')
                }
            else:
                params = {'name': domain, 'type': 'A'}

            url = f"https://{ip}{server['path']}"
            headers = {'Host': server['host']}
            headers.update(DOH_HEADERS)
            
            response = requests.get(
                url,
                params=params,
                headers=headers,
                timeout=5,
                verify=False
            )
            
            if response.status_code == 200:
                data = response.json() if server['params_type'] == 'standard' else parse_dns_wire(response.content)
                # 新增IPv4过滤
                return [
                    answer['data'] for answer in data.get('Answer', [])
                    if answer.get('type') == 1 and is_valid_ipv4(answer['data'])
                ]
        except Exception:
            continue
    return None

def process_doh_response(data):
    """处理DoH响应并提取NS记录"""
    ns_servers = []
    
    for answer in data.get('Answer', []):
        if answer.get('type') == 2:
            ns_data = answer.get('data', '')
            if ns_data:
                ns_servers.append(ns_data.rstrip('.').lower())
    
    if not ns_servers:
        for authority in data.get('Authority', []):
            if authority.get('type') == 2:
                ns_data = authority.get('data', '')
                if ns_data:
                    ns_servers.append(ns_data.rstrip('.').lower())
    
    return list(set(ns_servers)) if ns_servers else None

def print_section(title):
    print(f"\n{STYLES['divider']}")
    print(f"{STYLES['title']}{title.upper()}{COLORS['reset']}")
    print(f"{STYLES['divider']}\n")

def print_status(style, message):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {style}: {message}")

def extract_domain(url):
    ext = tldextract.extract(url)
    return f"{ext.domain}.{ext.suffix}"

def get_ip_from_ns(ns_domain):
    """双重验证获取IPv4地址"""
    print_status(STYLES['info'], f"开始解析NS服务器: {ns_domain}")
    
    # 第一重解析：DoH查询
    ips = query_a_with_doh(ns_domain)
    valid_ips = [ip for ip in (ips or []) if is_valid_ipv4(ip)]
    
    # 第二重解析：系统DNS兜底
    if not valid_ips:
        print_status(STYLES['warning'], "DoH未返回有效IPv4，尝试系统DNS解析")
        try:
            ais = socket.getaddrinfo(ns_domain, 0, socket.AF_INET)  # 强制IPv4
            valid_ips = list({ai[4][0] for ai in ais})
        except socket.gaierror as e:
            print_status(STYLES['error'], f"系统解析失败: {str(e)}")
            return None
    
    if valid_ips:
        print_status(STYLES['success'], f"有效IPv4地址: {', '.join(valid_ips)}")
        return valid_ips[0]
    
    print_status(STYLES['error'], f"DNS解析失败 [{ns_domain}]")
    return None

def get_geo_info(ip_address, geoip_db_path):
    try:
        with geoip2.database.Reader(geoip_db_path) as reader:
            return reader.country(ip_address).country.name
    except Exception as e:
        print_status(STYLES['error'], f"归属地查询失败 [{ip_address}]: {e}")
        return None

def download_geoip_db():
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
    return any(provider in ns_domain.lower() for provider in NON_CHINA_PROVIDERS)

def validate_ns_records(new_domain, geoip_db_path):
    print_section("域名验证流程")
    print_status(STYLES['info'], f"开始验证域名: {new_domain}")
    
    ns_servers = query_ns_with_doh(new_domain)
    
    if not ns_servers:
        print_status(STYLES['error'], "未获取到有效NS记录")
        return False
    
    print_status(STYLES['success'], f"获取到{len(ns_servers)}条NS记录: {', '.join(ns_servers)}")
    
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

def check_existing_entry(file_path, new_domain):
    entry = f"server=/{new_domain}/114.114.114.114"
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return any(line.strip().startswith(entry) for line in f)
    except Exception as e:
        print_status(STYLES['error'], f"文件读取失败: {e}")
        return True

def find_insert_position(lines, new_domain):
    new_entry = f"server=/{new_domain}/114.114.114.114"
    for i, line in enumerate(lines):
        line = line.strip()
        if line.startswith("server=/") and line.endswith("/114.114.114.114"):
            existing_domain = line.split('/')[1]
            if existing_domain > new_domain:
                return i
    return len(lines)

def get_config_path():
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

def insert_domain():
    print_section("dnsmasq-china-list 域名规则管理工具启动")
    print(f"{STYLES['title']}版本: 3.1 | 作者: Aethersailor | 协议: MIT{COLORS['reset']}\n")
    
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
    try:
        insert_domain()
    except Exception as e:
        print(f"\n{STYLES['error']}: 发生未捕获异常")
        import traceback
        traceback.print_exc()
    finally:
        input("\n按回车键退出...")
