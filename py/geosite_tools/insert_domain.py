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
import base64
import dns.message
import dns.resolver
from datetime import datetime
from urllib.parse import urlencode
import urllib3
import sys
import subprocess
import tkinter  # 新增GUI库导入
from tkinter import Tk
from tkinter.filedialog import askopenfilename
from dns import rdatatype  # 添加在文件开头的导入部分
NS_CACHE = {}  # 缓存结构：{ns_domain: (ip, timestamp)}
CACHE_TTL = 3600  # 缓存有效期1小时
CLOUDFLARE_DNS = ['192.168.1.10']  # 新增备用DNS服务器
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

# 修正后的依赖检查函数 (约第32行)
def check_dependencies():
    required = {
        'tldextract': 'tldextract',  # ✅ 移除pyperclip
        'geoip2': 'geoip2',
        'requests': 'requests',
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

# 修改GEOIP数据库下载地址配置
GEOIP_DB_URLS = [
    'https://raw.githubusercontent.com/Loyalsoldier/geoip/release/GeoLite2-Country.mmdb',
    'https://github.boki.moe/https://raw.githubusercontent.com/Loyalsoldier/geoip/release/GeoLite2-Country.mmdb'
]

# 在导入部分添加（约第15行）


# 删除原有的DOH_SERVERS和DOH_HEADERS定义（约第93-113行）
# 替换query_ns_with_doh函数（约第214行）
def query_ns_record(domain):  # 原query_ns_with_doh
    """使用Cloudflare DNS进行普通DNS查询"""
    try:
        resolver = dns.resolver.Resolver(configure=False)
        resolver.nameservers = CLOUDFLARE_DNS  # 修改为使用服务器列表
        answers = resolver.resolve(domain, 'NS', lifetime=5)
        return [str(r.target).rstrip('.').lower() for r in answers]
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
        print_status(STYLES['error'], "未找到NS记录")
        return None
    except dns.exception.Timeout:
        print_status(STYLES['error'], "DNS查询超时")
        return None
    except Exception as e:
        print_status(STYLES['error'], f"DNS查询失败: {str(e)}")
        return None

def query_a_record(domain):
    """使用Cloudflare DNS查询A记录"""
    try:
        resolver = dns.resolver.Resolver(configure=False)
        resolver.nameservers = CLOUDFLARE_DNS  # 修改为使用服务器列表
        answers = resolver.resolve(domain, 'A', lifetime=5)
        return [str(r) for r in answers if is_valid_ipv4(str(r))]
    except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
        print_status(STYLES['warning'], f"无有效A记录: {domain}")  # 新增状态提示
        return None
    except dns.exception.Timeout:
        print_status(STYLES['error'], "DNS查询超时")
        return None
    except Exception as e:
        print_status(STYLES['error'], f"查询异常: {str(e)}")
        return None

# 删除parse_dns_wire和process_doh_response函数（约第246-274行）


def print_section(title):
    print(f"\n{STYLES['divider']}")
    print(f"{STYLES['title']}{title.upper()}{COLORS['reset']}")
    print(f"{STYLES['divider']}\n")
def print_status(style, message):
    print(f"[{datetime.now().strftime('%H:%M:%S')}] {style}: {message}")
def extract_domain(url):
    ext = tldextract.extract(url)
    return f"{ext.domain}.{ext.suffix}"
def get_ip_from_ns(ns_domain, geoip_db_path):  # 新增geoip参数
    """带缓存的双重验证获取IPv4地址"""
    current_time = time.time()
    cached = NS_CACHE.get(ns_domain)
    if cached and current_time - cached[1] < CACHE_TTL:
        geo_info = get_geo_info(cached[0], geoip_db_path) or "未知归属地"
        print_status(STYLES['success'], f"缓存命中: {ns_domain} -> {cached[0]} ({geo_info})")
        return cached[0]
    
    print_status(STYLES['info'], f"开始解析NS服务器: {ns_domain}")
    
    # 更新调用名称
    ips = query_a_record(ns_domain)  # 原query_a_with_doh
    valid_ips = ips or []  # ✅ 移除冗余验证
    
    # 第二重解析：使用1.1.1.1 DNS解析
    if not valid_ips:
        print_status(STYLES['warning'], "DoH未返回有效IPv4，尝试Cloudflare解析")
        try:
            resolver = dns.resolver.Resolver(configure=False)
            resolver.nameservers = CLOUDFLARE_DNS  # 使用服务器列表
            
            # 查询A记录（IPv4）并设置超时
            answers = resolver.resolve(ns_domain, 'A', lifetime=5)
            valid_ips = [str(r) for r in answers if is_valid_ipv4(str(r))]
            
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN) as e:
            print_status(STYLES['error'], f"DNS记录不存在: {str(e)}")
            return None
        except dns.exception.Timeout:
            print_status(STYLES['error'], "DNS查询超时")
            return None
        except Exception as e:
            print_status(STYLES['error'], f"DNS解析失败: {str(e)}")
            return None
    
    if valid_ips:
        selected_ip = valid_ips[0]
        NS_CACHE[ns_domain] = (selected_ip, current_time)
        geo_info = get_geo_info(selected_ip, geoip_db_path) or "未知归属地"
        print_status(STYLES['success'], f"有效IPv4地址已缓存: {selected_ip} ({geo_info})")
        return selected_ip
    
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
    # 增强章节分隔效果
    print_status(STYLES['info'], "启动域名验证流程")
    print_status(STYLES['info'], f"开始验证域名: {new_domain}")
    ns_servers = query_ns_record(new_domain)
    
    if not ns_servers:
        print_status(STYLES['error'], "未获取到有效NS记录")
        return False
    
    print_status(STYLES['success'], f"获取到{len(ns_servers)}条NS记录: {', '.join(ns_servers)}")
    
    # 初始化验证标志
    china_found = False
    
    for idx, ns_domain in enumerate(ns_servers, 1):
        print_status(STYLES['info'], f"验证NS服务器 ({idx}/{len(ns_servers)})：{ns_domain}")
        
        # 保留非中国服务商检测作为警告
        if check_non_china_provider(ns_domain):
            print_status(STYLES['warning'], f"检测到非中国服务商：{ns_domain}")

        ip_address = get_ip_from_ns(ns_domain, geoip_db_path)
        if not ip_address:
            continue  # 跳过解析失败的记录继续检查其他NS
            
        country = get_geo_info(ip_address, geoip_db_path)
        if not country:
            continue  # 跳过归属地查询失败记录
            
        # 关键修改点：只要有一个中国IP立即标记验证通过
        if country == "China":
            geo_info = get_geo_info(ip_address, geoip_db_path) or "未知归属地"
            print_status(STYLES['success'], f"找到中国归属地: {ip_address} ({geo_info})")
            china_found = True
            break
    
    # 最终判断：只要有一个有效中国IP即返回True
    if china_found:
        print_status(STYLES['success'], "至少存在一个中国NS服务器，验证通过")
        return True
        
    print_status(STYLES['error'], "所有NS服务器均未通过中国归属地验证")
    return False
def check_existing_entry(file_path, new_domain):
    entry = f"server=/{new_domain}/114.114.114.114"
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            return any(line.strip() == entry for line in f)  # ✅ 精确匹配
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
# 在文件顶部添加time模块导入
import time
# 新增：IPv4地址验证函数
def insert_domain():
    print_section("dnsmasq-china-list 域名规则管理工具启动")
    print(f"{STYLES['title']}版本: {__version__} | 作者: {__author__} | 协议: {__license__}")
    print(f"{STYLES['title']}仓库: {__repository__}{COLORS['reset']}\n")
    
    config_path = get_config_path()
    if not config_path:
        return
    
    geoip_db_path = download_geoip_db()
    if not geoip_db_path:
        return

    def process_domain(domain):
        # 修改为同时过滤.cn和.top域名
        if domain.endswith(('.cn', '.top')):
            print_status(STYLES['warning'], ".cn或.top域名自动跳过")
            return
        if check_existing_entry(config_path, domain):
            print_status(STYLES['warning'], "规则已存在，跳过处理")
            return
        if validate_ns_records(domain, geoip_db_path):
            with open(config_path, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            new_entry = f"server=/{domain}/114.114.114.114\n"
            insert_pos = find_insert_position(lines, domain)
            lines.insert(insert_pos, new_entry)
            
            with open(config_path, 'w', newline='\n', encoding='utf-8') as f:
                f.writelines(lines)
            
            # 写入验证
            with open(config_path, 'r', encoding='utf-8') as f:
                written_content = f.read()
                if new_entry.strip() not in written_content:
                    raise RuntimeError(f"文件写入验证失败: {new_entry.strip()}")
            
            # Git操作
            target_dir = os.path.dirname(config_path)
            commit_msg = f"accelerated-domains: add {domain}"
            
            try:
                subprocess.run(
                    ['git', 'add', 'accelerated-domains.china.conf'],
                    cwd=target_dir,
                    check=True
                )
                subprocess.run(
                    ['git', 'commit', '-m', commit_msg],
                    cwd=target_dir,
                    check=True
                )
                print_status(STYLES['success'], "成功提交到Git仓库")
            except subprocess.CalledProcessError as e:
                print_status(STYLES['error'], f"Git操作失败: {str(e)}")
            except Exception as e:
                print_status(STYLES['error'], f"意外错误: {str(e)}")
        else:
            print_status(STYLES['error'], "域名验证未通过，跳过添加")

    # 新增剪贴板监控相关变量
    CLIPBOARD_CACHE = set()  # <mcsymbol name="CLIPBOARD_CACHE" filename="insert_domain.py" path="e:\Github\insert_domain.py" startline="1" type="variable"></mcsymbol>
    PROCESSING_QUEUE = []    # <mcsymbol name="PROCESSING_QUEUE" filename="insert_domain.py" path="e:\Github\insert_domain.py" startline="1" type="variable"></mcsymbol>
    last_clipboard = ""      # <mcsymbol name="last_clipboard" filename="insert_domain.py" path="e:\Github\insert_domain.py" startline="1" type="variable"></mcsymbol>

    def clipboard_monitor():
        """剪贴板监控核心逻辑"""
        nonlocal last_clipboard
        last_clipboard = pyperclip.paste().strip()
        print_status(STYLES['info'], "监控准备就绪，请复制新内容...")
        print_status(STYLES['info'], "---")
        
        while True:
            current_content = pyperclip.paste().strip()
            
            if current_content and current_content != last_clipboard:
                last_clipboard = current_content
                # === 新增多行处理 ===
                lines = [line.strip() for line in current_content.splitlines()]
                valid_domains = []
                
                # 提取有效域名并保留原有提示
                for line in lines:
                    if not line:  # 跳过空行
                        continue
                    domain = extract_domain(line)
                    if domain:
                        valid_domains.append(domain)
                    else:
                        print_status(STYLES['warning'], f"无效内容已跳过: {line}")
                
                # 处理缓存检查（保持原有提示格式）
                new_domains = []
                for domain in valid_domains:
                    if domain in CLIPBOARD_CACHE:
                        print_status(STYLES['warning'], f"跳过缓存域名: {domain}")
                        print_status(STYLES['info'], "---")
                        continue
                    new_domains.append(domain)
                # === 多行处理结束 ===
                
                if new_domains:
                    print_status(STYLES['success'], 
                        f"发现{len(new_domains)}新域名（共{len(lines)}行）")
                    PROCESSING_QUEUE.extend(new_domains)
        
            # 处理队列（原有逻辑完全保留）
            while PROCESSING_QUEUE:
                current_domain = PROCESSING_QUEUE.pop(0)
                print_status(STYLES['info'], f"处理剪贴板域名: {current_domain}")
                process_domain(current_domain)
                CLIPBOARD_CACHE.add(current_domain)
                print_status(STYLES['info'], "---")
                time.sleep(0.5)
        
            time.sleep(0.1)

    while True:
        try:
            user_input = input(f"\n{COLORS['cyan']}请输入域名/URL（回车选文件｜拖入txt｜exit退出）{COLORS['reset']}: ").strip(' "\'')
            
            # 新增剪贴板模式入口
            if user_input == '1':
                print_status(STYLES['info'], "进入剪贴板监控模式 (输入 exit 退出)")
                try:
                    clipboard_monitor()
                except KeyboardInterrupt:
                    print_status(STYLES['warning'], "退出剪贴板监控模式")
                    CLIPBOARD_CACHE.clear()
                    continue
                    
            # 原有退出和文件处理逻辑保持不变 ...
            if user_input.lower() == 'exit':
                print_section("程序退出")
                print_status(STYLES['info'], "感谢使用！")
                break

            # 修改文件检测逻辑（新增文件存在性检查）
            if user_input and os.path.isfile(user_input) and user_input.endswith('.txt'):
                print_status(STYLES['info'], f"检测到输入为文件，开始处理: {user_input}")
                try:
                    with open(user_input, 'r', encoding='utf-8') as f:
                        lines = f.readlines()
                        for line_num, line in enumerate(lines, 1):
                            line = line.strip()
                            if not line:
                                continue
                            print_status(STYLES['info'], f"处理第 {line_num} 行 → 原始内容: {line}")
                            domain = extract_domain(line)
                            process_domain(domain)
                            # 新增分隔线打印
                            print_status(STYLES['info'], "---")
                            time.sleep(1)
                except Exception as e:
                    print_status(STYLES['error'], f"文件处理失败: {str(e)}")
                continue

            new_domain = extract_domain(user_input)
            process_domain(new_domain)
                
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
