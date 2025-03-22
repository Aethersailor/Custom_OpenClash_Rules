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
import dns.resolver
import socket
urllib3.disable_warnings(urllib3.exceptions.InsecureRequestWarning)

MAX_WORKERS = 30  # 线程并发数
REQUEST_TIMEOUT = 10  # 请求超时(秒)
GEOIP_DB_URL = "https://github.com/Loyalsoldier/geoip/raw/release/GeoLite2-Country.mmdb"
DNS_SERVER = '192.168.1.10'  # 本地DNS服务器地址
DNS_PORT = 53                # 标准DNS端口
DNS_TIMEOUT = 5              # DNS查询超时时间


class DomainValidator:
    def __init__(self):
        self.a_record_cache = {}
        # 配置DNS解析器
        self.resolver = dns.resolver.Resolver()
        self.resolver.nameservers = [DNS_SERVER]
        self.resolver.port = DNS_PORT
        self.resolver.timeout = DNS_TIMEOUT
        self.resolver.lifetime = DNS_TIMEOUT
        
        # 删除原有session配置，保留其他初始化代码
        self.geoip_path = self.download_geoip()
        self.check_geoip_database()

    def query_ns_records(self, domain):
        print(f"[DEBUG][NS] 开始查询 {domain} 的NS记录")
        try:
            # 使用DNS协议查询NS记录
            answer = self.resolver.resolve(domain, 'NS', raise_on_no_answer=False)
            ns_list = [rr.target.to_text().rstrip('.') for rr in answer.rrset] if answer.rrset else []
            print(f"[DEBUG][NS] {domain} 的NS记录查询结果: {ns_list}")
            return ns_list
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
            print(f"[WARN][NS] {domain} 未找到NS记录")
            return []
        except Exception as e:
            print(f"[ERROR][NS] 查询失败: {str(e)}")
            return []

    def query_a_record(self, domain):
        print(f"[DEBUG][A] 开始查询 {domain} 的A记录")
        # 检查缓存
        if domain in self.a_record_cache:
            print(f"[CACHE] 命中A记录缓存: {domain}")
            return self.a_record_cache[domain]
            
        try:
            # 使用DNS协议查询A记录
            answer = self.resolver.resolve(domain, 'A', raise_on_no_answer=False)
            a_records = [rr.address for rr in answer.rrset] if answer.rrset else []
            print(f"[DEBUG][A] {domain} 的A记录解析结果: {a_records}")
            self.a_record_cache[domain] = a_records
            return a_records
        except (dns.resolver.NoAnswer, dns.resolver.NXDOMAIN):
            print(f"[WARN][A] {domain} 未找到A记录")
            return []
        except Exception as e:
            print(f"[ERROR][A] 查询失败: {str(e)}")
            return []

# 删除不再需要的DOH相关方法：doh_request, resolve_doh_ip
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
        
        # 删除存在性检查，直接下载
        print("强制下载GeoIP数据库(约5MB)...")
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






    def validate_domain(self, domain):
        try:
            # 移除开始时间戳的打印
            ext = tldextract.extract(domain)
            
            if ext.suffix in ['cn', 'top']:
                # 修改为单行简洁输出
                print(f"[过滤] 跳过 {domain}")
                return False
                
            main_domain = f"{ext.domain}.{ext.suffix}"
            ns_servers = self.query_ns_records(main_domain)
            
            # 简化NS记录查询成功的输出
            if not ns_servers:
                print(f"[失败] {domain}: 无NS记录")
                return False
                
            print(f"[DEBUG][NS] {domain} 的NS服务器列表: {ns_servers}")
            
            # 改为宽松模式：任一NS服务器在中国即通过
            any_ns_in_china = False
            with geoip2.database.Reader(self.geoip_path) as reader:
                for ns in ns_servers:
                    ns_ips = self.query_a_record(ns)
                    print(f"[DEBUG] 检查NS服务器: {ns} 解析IP: {ns_ips}")
                    
                    for ip in ns_ips:
                        try:
                            country = reader.country(ip).country.iso_code
                            print(f"[GEOIP] {ns} 的IP {ip} 国家代码: {country}")
                            if country == 'CN':
                                print(f"[RESULT] {domain} 成功原因: {ns} 存在中国IP {ip}")
                                any_ns_in_china = True
                                break  # 发现有效IP即跳出当前NS检查
                        except Exception as e:
                            print(f"地理查询异常: {str(e)}")
                            continue
                    
                    if any_ns_in_china:  # 发现有效NS后立即终止全部检查
                        break
            
            if any_ns_in_china:
                print(f"[RESULT] {domain} 验证通过")
            else:
                print(f"[RESULT] {domain} 验证失败")
            
            return any_ns_in_china
        except Exception as e:
            print(f"[ERROR] 验证异常 {domain}: {str(e)}")
            return False

def process_file(input_path, output_path):
    print(f"开始处理文件: {input_path}")
    validator = DomainValidator()
    valid_domains = []
    
    with open(input_path, 'r', encoding='utf-8', errors='ignore') as f:
        domains = [line.strip() for line in f if line.strip()]
    
    total = len(domains)
    print(f"待处理域名总数: {total}")
    
    # 新增统计指标
    processed = 0
    skipped = 0
    failed = 0
    
    with concurrent.futures.ThreadPoolExecutor(max_workers=MAX_WORKERS) as executor:
        future_to_domain = {executor.submit(validator.validate_domain, domain): domain for domain in domains}
        
        for future in concurrent.futures.as_completed(future_to_domain):
            processed += 1
            domain = future_to_domain[future]
            
            # 进度显示（每10%更新一次）
            if processed % (total//10 or 1) == 0:
                print(f"▏ 进度: {processed/total:.0%} | 已处理: {processed} 有效: {len(valid_domains)} 跳过: {skipped} 失败: {failed}")
                
            try:
                result = future.result()
                if result:
                    valid_domains.append(domain)
                else:
                    if domain.lower().endswith(('.cn', '.top')):
                        skipped += 1
                    else:
                        failed += 1
            except Exception as e:
                print(f"\n[!] 严重错误 {domain}: {str(e)}")
                failed += 1

    # 优化结果输出
    print(f"\n{' 验证完成 ':━^40}")
    print(f"▪ 总处理量: {total}")
    print(f"▪ 有效域名: {len(valid_domains)} (占比: {len(valid_domains)/total:.1%})")
    print(f"▪ 过滤跳过: {skipped}")
    print(f"▪ 验证失败: {failed}")
    print(f"结果文件: {output_path}")

    # 保存结果时也使用utf-8编码
    with open(output_path, 'w', encoding='utf-8') as f:
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