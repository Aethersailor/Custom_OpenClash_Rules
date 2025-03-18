import sys
import subprocess
import pyperclip
import tldextract
import socket
import geoip2.database
import requests
import tempfile
import os
import json
import time
import platform
import dns.message
from datetime import datetime
from urllib.parse import urlencode
import urllib3
from dns import rdatatype  # 添加在文件开头的导入部分
import threading
from queue import Queue
import base64
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
# 新增元信息声明
__version__ = "3.1"
__author__ = "Aethersailor"
__license__ = "CC BY-NC-SA 4.0"
__repository__ = "https://github.com/Aethersailor/Custom_OpenClash_Rules"

# 原有依赖检查函数
def check_dependencies():
    required = {
        'pyperclip': 'pyperclip', 
        'tldextract': 'tldextract',  # ✅ 用于域名解析
        'geoip2': 'geoip2',          # ✅ IP地理定位
        'requests': 'requests',      # ✅ HTTP请求
        'dns': 'dnspython'           # ✅ DNS解析
        # 已移除：
        # 'pygetwindow': 'pygetwindow', 
        # 'pyautogui': 'pyautogui'
    }
    missing = []
    for pkg in required:
        try:
            __import__(pkg)
        except ImportError:
            missing.append(required[pkg])
    
    if missing:
        print("\n正在安装缺失依赖...")
        try:
            subprocess.check_call(
                [sys.executable, '-m', 'pip', 'install', *missing],
                stdout=subprocess.DEVNULL
            )
        except Exception as e:
            print_status(STYLES['error'], f"依赖安装失败: {str(e)}")
            input("按回车键退出...")
            sys.exit(1)
            
        print("依赖安装完成，请重新运行脚本\n")
        input("按回车键退出...")  # 新增等待
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
# 修改输出样式定义（移除divider）
STYLES = {
    "info": f"{COLORS['cyan']}ℹ️  INFO{COLORS['reset']}",
    "success": f"{COLORS['green']}✅ SUCCESS{COLORS['reset']}",
    "warning": f"{COLORS['yellow']}⚠️  WARN {COLORS['reset']}", 
    "error": f"{COLORS['red']}❌ ERROR{COLORS['reset']}",
    "title": f"{COLORS['bold']}{COLORS['cyan']}✨ {COLORS['underline']}"
    # 移除divider样式定义
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
# 修改GEOIP数据库下载地址配置
GEOIP_DB_URLS = [
    'https://raw.githubusercontent.com/Loyalsoldier/geoip/release/GeoLite2-Country.mmdb',
    'https://github.boki.moe/https://raw.githubusercontent.com/Loyalsoldier/geoip/release/GeoLite2-Country.mmdb'
]
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
        # 修改为明确的类型获取方式
        if rrset.rdtype == dns.rdatatype.from_text('NS'):
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
    # 移除divider样式引用，改用固定分隔线
    divider = "═" * 60
    print(f"\n{COLORS['cyan']}{divider}{COLORS['reset']}")
    print(f"{STYLES['title']}{title.upper()}{COLORS['reset']}")
    print(f"{COLORS['cyan']}{divider}{COLORS['reset']}\n")
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
        # 移除旧的分隔线打印方式
        print_status(STYLES['info'], "初始化地理数据库")
        temp_dir = tempfile.gettempdir()
        geoip_db_path = os.path.join(temp_dir, 'GeoLite2-Country.mmdb')
        
        if os.path.exists(geoip_db_path):
            os.remove(geoip_db_path)
            print_status(STYLES['info'], "已清理旧版地理数据库")

        # 新增备用下载逻辑
        for db_url in GEOIP_DB_URLS:
            print_status(STYLES['info'], f"尝试下载: {db_url}")
            try:
                response = requests.get(db_url, stream=True)
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
                print_status(STYLES['warning'], f"下载失败: {str(e)}，尝试备用地址...")
                continue
                
        print_status(STYLES['error'], "所有下载地址均不可用")
        return None
    except Exception as e:
        print_status(STYLES['error'], f"数据库下载失败: {e}")
        return None
def check_non_china_provider(ns_domain):
    return any(provider in ns_domain.lower() for provider in NON_CHINA_PROVIDERS)
def validate_ns_records(new_domain, geoip_db_path):
    # 移除硬编码的分隔线打印
    print_status(STYLES['info'], "开始域名验证流程")
    
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
    # 在文件顶部添加导入（约第10行）
    import threading
    from queue import Queue
    print_section("dnsmasq-china-list 域名规则管理工具启动")
    print(f"{STYLES['title']}版本: {__version__} | 作者: {__author__} | 协议: {__license__}")
    print(f"{STYLES['title']}仓库: {__repository__}{COLORS['reset']}\n")
    
    # 新增剪贴板初始化清理
    try:
        pyperclip.copy("")  # 清空剪贴板
        print_status(STYLES['info'], "已初始化剪贴板缓冲区")
    except Exception as e:
        print_status(STYLES['warning'], f"剪贴板清空失败，请手动清空剪贴板后继续: {str(e)}")

    config_path = get_config_path()
    if not config_path:
        return
    
    geoip_db_path = download_geoip_db()
    if not geoip_db_path:
        return

    # 新增剪贴板监控相关变量
    processing_queue = Queue()
    last_clipboard_content = None
    processed_history = set()
    clipboard_lock = threading.Lock()

    def process_domain(domain):
        """核心处理逻辑"""
        try:
            # 移除这里的print_section调用
            # 调整顺序：先检查存在性
            if check_existing_entry(config_path, domain):
                print_status(STYLES['warning'], f"已存在记录: {domain}")
                return
    
            # 存在性检查通过后再执行验证
            if not validate_ns_records(domain, geoip_db_path):
                print_status(STYLES['error'], f"验证失败: {domain}")
                return
    
            with open(config_path, 'r+', encoding='utf-8') as f:
                lines = f.readlines()
                if any(f"server=/{domain}/" in line for line in lines):
                    print_status(STYLES['warning'], f"重复记录: {domain}")
                    return
    
                insert_pos = find_insert_position(lines, domain)
                lines.insert(insert_pos, f"server=/{domain}/114.114.114.114\n")
                f.seek(0)
                f.writelines(lines)
    
            print_status(STYLES['success'], f"成功添加: {domain}")
            pyperclip.copy("")  # 清空剪贴板
            
            # ======== 修改后的git提交逻辑 ========
            script_dir = os.path.dirname(os.path.abspath(__file__))
            target_dir = os.path.join(script_dir, "dnsmasq-china-list")
            
            try:
                os.chdir(target_dir)
                subprocess.run(['git', 'add', 'accelerated-domains.china.conf'], check=True)
                commit_msg = f"accelerated-domains: add {domain}"
                subprocess.run(['git', 'commit', '-m', commit_msg], check=True)
                print_status(STYLES['success'], "已提交更改到本地仓库")  # 修改提示信息
            except subprocess.CalledProcessError as e:
                print_status(STYLES['warning'], f"Git提交失败: {str(e)}")
            finally:
                os.chdir(script_dir)
            # ======== 修改结束 ========
                
        except Exception as e:
            print_status(STYLES['error'], f"处理异常: {str(e)}")
            raise

    # 新增：将包装函数定义移动到insert_domain作用域内
    def process_domain_wrapper(domain):
        """带错误处理的任务包装器"""
        try:
            print_section(f"域名处理中: {domain}")
            process_domain(domain)
        except Exception as e:
            print_status(STYLES['error'], f"处理失败: {str(e)}")

    def clipboard_monitor():
        """剪贴板监控线程"""
        nonlocal last_clipboard_content
        while True:
            try:
                with clipboard_lock:
                    current_content = pyperclip.paste().strip(' "\'')
                    
                if current_content:
                    # 新增内容变化检测
                    if current_content == last_clipboard_content:
                        time.sleep(0.5)
                        continue
                        
                    domain = extract_domain(current_content)
                    # 调整检测顺序
                    if domain in processed_history:
                        print_status(STYLES['warning'], f"检测到历史域名: {domain}")
                        last_clipboard_content = current_content  # 更新最后内容防止重复
                        continue
                    if domain.endswith('.cn'):
                        print_status(STYLES['warning'], f"已忽略.cn域名: {domain}")
                        last_clipboard_content = current_content  # 新增：更新最后内容
                        continue
                        
                    processing_queue.put(domain)
                    processed_history.add(domain)
                    last_clipboard_content = current_content
                    print_status(STYLES['success'], f"已加入队列: {domain}")
                    
                time.sleep(0.5)
            except Exception as e:  # 捕获剪贴板访问异常
                print_status(STYLES['error'], f"剪贴板监控异常: {str(e)}")
                time.sleep(1)

    # 启动监控线程
    monitor_thread = threading.Thread(target=clipboard_monitor, daemon=True)
    monitor_thread.start()

    print_status(STYLES['info'], "剪贴板监控已启动 (自动忽略.cn域名)")
    print_status(STYLES['info'], "检测到新域名将自动加入处理队列")

    # 主处理循环
    while True:
        try:
            if not processing_queue.empty():
                domain = processing_queue.get()
                # 移除此处的print_section调用
                
                # 启动独立线程处理任务
                processing_thread = threading.Thread(
                    target=process_domain_wrapper,
                    args=(domain,)
                )
                processing_thread.start()
                processing_thread.join()  # 等待当前任务完成
                
                # 清理历史记录避免内存泄漏
                if len(processed_history) > 100:
                    processed_history.clear()
            else:
                time.sleep(1)
                
        except KeyboardInterrupt:
            print_status(STYLES['error'], "操作已中止")
            break

# 修复1：移除文件末尾的重复 main 代码块（删除以下部分）
if __name__ == "__main__":
    try:
        insert_domain()
        # 保持主线程存活
        while True:
            time.sleep(3600)
    except KeyboardInterrupt:
        print_status(STYLES['error'], "\n程序已终止")
    except Exception as e:
        print(f"\n{STYLES['error']}: 致命错误 - {str(e)}")
        import traceback
        traceback.print_exc()
    finally:
        if sys.platform.startswith('win'):
            import msvcrt
            print("\n按任意键退出...")
            msvcrt.getch()
        else:
            print("\n按回车键退出...")
            sys.stdin.read(1)

