import sys
import concurrent.futures
import tldextract
import geoip2.database
import requests
import os
import time
from datetime import datetime
from urllib.parse import urlparse
import tempfile
import shutil
import urllib3
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

# 新配置：使用不限QPS的DOH服务器
# 修改DOH服务器配置
# 在DOH_SERVERS配置下方添加线程配置
# 修改DOH服务器配置为DNSPod（支持国内访问）
DOH_SERVERS = [
    {
        'host': 'doh.pub', 
        'path': '/dns-query',
        'ip_cache': '1.12.12.12',  # DNSPod国内节点1
        'last_request': 0  # 最后请求时间戳
    },
    {
        'host': 'doh.pub',
        'path': '/dns-query',
        'ip_cache': '120.53.53.53',  # DNSPod国内节点2
        'last_request': 0
    }
]

# 新增线程池和超时配置（必须添加在类定义之前）
MAX_WORKERS = 30  # 线程并发数
REQUEST_TIMEOUT = 10  # 请求超时(秒)
GEOIP_DB_URL = "https://github.com/Loyalsoldier/geoip/raw/release/GeoLite2-Country.mmdb"

# 在文件开头添加socket模块导入
import socket  # 新增导入

# 在类中添加缓存字典
class DomainValidator:
    def __init__(self):
        self.a_record_cache = {}  # 新增A记录缓存
        self.session = requests.Session()
        # 配置SSL协议版本
        self.session.mount('https://', requests.adapters.HTTPAdapter(
            max_retries=3,
            pool_maxsize=MAX_WORKERS,  # 现在可以正确引用
            pool_block=True
        ))
        # 添加重试策略
        retry = requests.packages.urllib3.util.retry.Retry(
            total=3,
            backoff_factor=0.3,
            status_forcelist=(500, 502, 504)
        )
        self.session.mount('https://', requests.adapters.HTTPAdapter(max_retries=retry))
        self.geoip_path = self.download_geoip()  # 原方法未实现
        self.session.verify = False  # 保持原有逻辑但添加警告说明
        self.session.trust_env = False  # 禁用系统代理证书验证
        self.check_geoip_database()  # 新增数据库校验
        
    def check_geoip_database(self):
        """地理数据库校验"""
        test_ips = {
            '114.114.114.114': 'CN',  # 中国DNS
            '8.8.8.8': 'US',          # 谷歌DNS
            '1.1.1.1': 'AU'           # Cloudflare
        }
        
        with geoip2.database.Reader(self.geoip_path) as reader:
            for ip, expect in test_ips.items():
                try:
                    actual = reader.country(ip).country.iso_code
                    print(f"[GEOCHECK] {ip} 期望:{expect} 实际:{actual} {'✓' if actual==expect else '✗'}")
                except Exception as e:
                    print(f"[GEOCHECK] 数据库校验失败 {ip}: {str(e)}")

    # 新增缺失的方法实现
    def download_geoip(self):
        """实现地理数据库下载逻辑"""
        temp_dir = tempfile.gettempdir()
        geoip_path = os.path.join(temp_dir, 'GeoLite2-Country.mmdb')
        
        if os.path.exists(geoip_path):
            print("检测到已存在的GeoIP数据库")
            return geoip_path
            
        print("正在下载GeoIP数据库(约5MB)...")
        try:
            response = requests.get(GEOIP_DB_URL, stream=True, timeout=30)
            response.raise_for_status()
            
            total_size = int(response.headers.get('content-length', 0))
            downloaded = 0
            
            with open(geoip_path, 'wb') as f:
                for chunk in response.iter_content(chunk_size=8192):
                    f.write(chunk)
                    downloaded += len(chunk)
                    print(f"\r下载进度: {downloaded/1024/1024:.2f}MB", end='')
                
            print("\n数据库下载完成")
            return geoip_path
        except Exception as e:
            raise RuntimeError(f"GeoIP数据库下载失败: {str(e)}")

    # 新增IPv4验证方法
    def is_valid_ipv4(self, address):
        try:
            socket.inet_pton(socket.AF_INET, address)
            return True
        except (socket.error, OSError):
            return False

    def resolve_doh_ip(self, server):
        # 直接返回预置IP
        return server['ip_cache']

    def doh_request(self, server, params):
        """带QPS控制的请求方法"""
        # 调整为QPS19 (52.6ms间隔)
        elapsed = time.time() - server['last_request']
        if elapsed < 0.0526:  # 修改间隔时间
            time.sleep(0.0526 - elapsed)
        
        try:
            url = f"https://{server['ip_cache']}{server['path']}"
            headers = {'Host': server['host']}  # 修正Host头
            
            response = self.session.get(
                url,
                params=params,
                headers=headers,
                timeout=REQUEST_TIMEOUT,
                verify=True
            )
            server['last_request'] = time.time()
            return response
        except Exception as e:
            print(f"DOH请求失败: {str(e)}")
            return None

    def query_ns_records(self, domain):
        print(f"[DEBUG][NS] 开始查询 {domain} 的NS记录")
        for server in DOH_SERVERS:
            response = self.doh_request(server, {'name': domain, 'type': 'NS'})
            try:
                # 修复Host头配置错误
                headers = {'Host': server['host']}  # 改为使用server配置中的host
                
                if response and response.status_code == 200:
                    data = response.json()
                    ns_list = [ans['data'].rstrip('.') for ans in data.get('Answer', [])
                              if ans.get('type') == 2]
                    print(f"[DEBUG][NS] {domain} 的NS记录查询结果: {ns_list}")
                    return ns_list
                elif response:
                    print(f"[WARN][NS] 非200响应: {response.status_code}")
            except Exception as e:
                print(f"[ERROR][NS] 查询失败: {str(e)}")
        print(f"[WARN][NS] {domain} 未找到有效NS记录")
        return []

    def query_a_record(self, domain):
        print(f"[DEBUG][A] 开始查询 {domain} 的A记录")
        
        # 检查缓存
        if domain in self.a_record_cache:
            print(f"[CACHE] 命中A记录缓存: {domain}")
            return self.a_record_cache[domain]
            
        # 强制指定A记录类型
        for server in DOH_SERVERS:
            response = self.doh_request(server, {'name': domain, 'type': 'A'})  # 确保查询A记录
            try:
                # 修复Host头配置错误
                headers = {'Host': server['host']}  # 改为使用server配置中的host
                
                if response and response.status_code == 200:
                    data = response.json()
                    # 严格过滤A记录
                    a_records = [
                        ans['data'] for ans in data.get('Answer', [])
                        if ans.get('type') == 1  # 确保只处理A记录
                        and self.is_valid_ipv4(ans['data'])
                    ]
                    print(f"[DEBUG][A] {domain} 的A记录解析结果: {a_records}")
                    
                    # 写入缓存
                    self.a_record_cache[domain] = a_records
                    return a_records
                elif response:
                    print(f"[WARN][A] 非200响应: {response.status_code}")
            except Exception as e:
                print(f"[ERROR][A] 查询失败: {str(e)}")
        print(f"[WARN][A] {domain} 未找到有效A记录")
        return []

    def validate_domain(self, domain):
        try:
            print(f"[{datetime.now().strftime('%H:%M:%S')}] 正在验证: {domain}")
            ext = tldextract.extract(domain)
            main_domain = f"{ext.domain}.{ext.suffix}"
            
            # 获取NS服务器列表
            ns_servers = self.query_ns_records(main_domain)
            if not ns_servers:
                print(f"[RESULT] {domain} 失败原因: 无NS记录")
                return False
                
            print(f"[DEBUG][NS] {domain} 的NS服务器列表: {ns_servers}")
            
            # 严格模式：所有NS服务器必须在中国
            all_ns_in_china = True
            with geoip2.database.Reader(self.geoip_path) as reader:
                for ns in ns_servers:
                    ns_ips = self.query_a_record(ns)
                    print(f"[DEBUG] 检查NS服务器: {ns} 解析IP: {ns_ips}")
                    
                    ns_in_china = False
                    for ip in ns_ips:
                        try:
                            country = reader.country(ip).country.iso_code
                            print(f"[GEOIP] {ns} 的IP {ip} 国家代码: {country}")
                            if country == 'CN':
                                ns_in_china = True
                                break
                        except Exception as e:
                            print(f"地理查询异常: {str(e)}")
                            continue
                    
                    if not ns_in_china:
                        print(f"[RESULT] {domain} 失败原因: {ns} 无中国IP")
                        all_ns_in_china = False  # 新增关键逻辑
                        break  # 发现无效NS立即终止循环
            
            if all_ns_in_china:
                print(f"[RESULT] {domain} 验证通过")
            else:
                print(f"[RESULT] {domain} 验证失败")
            
            return all_ns_in_china
        except Exception as e:
            print(f"[ERROR] 验证异常 {domain}: {str(e)}")
            return False

def process_file(input_path, output_path):
    # 修正变量顺序错误
    print(f"开始处理文件: {input_path}")
    validator = DomainValidator()
    valid_domains = []
    
    with open(input_path, 'r') as f:
        domains = [line.strip() for line in f if line.strip()]  # 必须先定义domains变量
    
    print(f"总域名数量: {len(domains)}")  # 移动到domains变量之后
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_domain = {
            executor.submit(validator.validate_domain, domain): domain 
            for domain in domains
        }
        
        for future in concurrent.futures.as_completed(future_to_domain):
            domain = future_to_domain[future]
            try:
                if future.result():
                    valid_domains.append(domain)
                    print(f"[{datetime.now().strftime('%H:%M:%S')}] 有效域名: {domain}")
            except Exception as e:
                print(f"验证失败 {domain}: {str(e)}")
    
    # 保存结果
    with open(output_path, 'w') as f:
        f.write("\n".join(sorted(valid_domains)))

    # 添加结果统计
    print(f"\n验证完成！有效域名数量: {len(valid_domains)}")
    print(f"结果已保存至: {output_path}")

if __name__ == "__main__":
    def get_valid_path(prompt):
        while True:
            try:
                path = input(prompt).strip(' "\'')
                if os.path.exists(path):
                    return path
                print(f"文件不存在，请重新输入: {path}")
            except KeyboardInterrupt:
                print("\n操作已取消")
                sys.exit(0)

    try:
        input_file = get_valid_path("请输入要处理的域名文件路径: ")
        
        # 自动生成输出路径
        script_dir = os.path.dirname(os.path.abspath(__file__))
        input_basename = os.path.splitext(os.path.basename(input_file))[0]
        output_file = os.path.join(script_dir, f"{input_basename}_china.txt")
        
        process_file(input_file, output_file)
    except Exception as e:
        print(f"\n发生未处理异常: {str(e)}")
        import traceback
        traceback.print_exc()
    finally:
        input("\n按回车键退出...")