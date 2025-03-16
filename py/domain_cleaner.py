import sys
import os
import tldextract
import requests  # 新增requests库导入
from urllib.parse import urlparse  # 新增URL解析
import glob

# 在文件开头添加try-except处理导入
try:
    import pyperclip
    clipboard_available = True
except ImportError:
    clipboard_available = False

def is_valid_domain(domain):
    """验证域名格式有效性"""
    if not domain or domain.startswith('.') or domain.endswith('.'):
        return False
    parts = domain.split('.')
    if len(parts) < 2:  # 排除单段内容如"cn"
        return False
    # RFC 1034标准验证
    for part in parts:
        if not part or len(part) > 63:
            return False
        if not part.isalnum() and '-' in part:
            if part.startswith('-') or part.endswith('-'):
                return False
        elif not part.isalnum():
            return False
    return True

def extract_main_domain(line):
    """提取主域名核心逻辑"""
    # 清理URL前缀
    if line.startswith(('http://', 'https://')):
        line = line.split('/')[2]
    # 去除端口号
    line = line.split(':')[0]
    # 使用tldextract获取注册域名
    ext = tldextract.extract(line)
    main_domain = ext.registered_domain.lower()
    
    # 过滤.cn域名和无效格式
    if not main_domain or main_domain.endswith('.cn'):
        return None
    # 确保一级域名（如example.com）
    return main_domain if main_domain.count('.') == 1 else None

def load_china_domains():
    """加载国内域名列表"""
    china_list = set()
    conf_path = os.path.join(os.path.dirname(__file__), 'dnsmasq-china-list', 'accelerated-domains.china.conf')
    
    if os.path.exists(conf_path):
        with open(conf_path, 'r', encoding='utf-8') as f:
            for line in f:
                if line.startswith('server=/'):
                    # 修复域名解析位置错误（原索引2应改为1）
                    domain = line.split('/')[1].split('/')[0].lower()  # 正确获取域名部分
                    china_list.add(domain)
    else:
        print("警告：未找到国内域名列表文件")
    return china_list

def process_domain_file(file_path=None, content=None, output_path=None):  # 修改参数列表
    """核心处理函数"""
    processed = set()
    output_lines = []
    china_domains = load_china_domains()
    china_duplicates = 0

    # 新增内容处理分支
    if content:
        raw_lines = [line.strip() for line in content.split('\n') if line.strip() and not line.startswith('#')]
    else:
        with open(file_path, 'r', encoding='utf-8') as f:
            raw_lines = [line.strip() for line in f if line.strip() and not line.startswith('#')]

    # 第一阶段：文件内部去重
    for stripped_line in raw_lines:
        # 修复：允许处理纯域名格式（无DOMAIN-SUFFIX前缀）
        if stripped_line.startswith(('DOMAIN-SUFFIX,', 'DOMAIN,')):
            clean_line = stripped_line.split(',', 1)[-1].strip()
        else:  # 新增纯域名处理分支
            clean_line = stripped_line.strip()
        
        main_domain = extract_main_domain(clean_line)
        
        # 新增验证顺序调整
        if not main_domain or not is_valid_domain(main_domain):
            continue
            
        # 先执行文件内去重
        if main_domain in processed:
            continue
            
        # 再执行国内域名过滤
        if main_domain in china_domains:
            china_duplicates += 1
            continue
            
        processed.add(main_domain)
        output_lines.append(main_domain)

    # 保存结果
    # 修复：当未指定输出路径时自动创建新文件名
    # 修改保存路径生成逻辑
    if output_path:
        save_path = output_path
    else:
        save_path = file_path.replace('.txt', '_cleaned.txt')
    
    # 修复字符串拼接语法错误
    with open(save_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sorted(output_lines)))  # 修正转义符号错误
        
    return len(output_lines), china_duplicates

def download_url(url):  # 新增下载函数
    """下载URL内容"""
    try:
        response = requests.get(url, timeout=10, verify=True)
        response.raise_for_status()
        return response.text
    except Exception as e:
        print(f"下载失败：{str(e)}")
        return None

def main_loop():
    """新增交互式主循环"""
    print("=== 域名清理工具 ===")
    output_dir = os.path.join(os.path.dirname(__file__), 'domain_cleaner')
    os.makedirs(output_dir, exist_ok=True)
    
    while True:
        # 修改输入提示和退出机制
        default_file = os.path.join(os.path.dirname(__file__), 'domain_cleaner.txt')
        user_input = input("\n请输入文件路径/URL（输入 exit 退出，回车使用默认文件）：").strip('"\'').strip()
        if user_input.lower() == 'exit':
            print("程序退出")
            break
        file_path = user_input if user_input else default_file

        # 移除调试信息输出
        if not file_path.startswith(('http://', 'https://')):
            try:
                file_path = os.path.abspath(os.path.expanduser(file_path))
            except Exception as e:
                print(f"路径解析失败：{str(e)}")
                continue

            if not os.path.isfile(file_path):
                print(f"文件 {file_path} 不存在！")
                continue

        # 将URL处理和本地文件处理整合到同一个代码块中
        if file_path.startswith(('http://', 'https://')):
            print(f"开始下载：{file_path}")
            content = download_url(file_path)
            if content:
                url_path = urlparse(file_path).path
                base_name = os.path.basename(url_path) or 'downloaded'
                output_name = os.path.splitext(base_name)[0] + '.txt'
                output_path = os.path.join(output_dir, output_name)
                
                valid_count, china_duplicates = process_domain_file(content=content, output_path=output_path)
                
                print(f"\n处理完成！输出文件：{output_path}")
                if clipboard_available:
                    pyperclip.copy(output_path)
                    print("路径已复制剪贴板")
                print(f"过滤国内重复域名：{china_duplicates} 个")
                print(f"有效域名数量：{valid_count} 个")
            else:
                print("下载失败")
        
        # 本地文件处理移到此处
        else:  
            if os.path.isfile(file_path):
                base_name = os.path.basename(file_path)
                output_name = os.path.join(output_dir, os.path.splitext(base_name)[0] + '_cleaned.txt')
                
                valid_count, china_duplicates = process_domain_file(file_path=file_path, output_path=output_name)
                
                print(f"\n处理完成！输出文件：{output_name}")
                if clipboard_available:
                    pyperclip.copy(output_name)
                    print("路径已复制剪贴板")
                print(f"过滤国内重复域名：{china_duplicates} 个")
                print(f"有效域名数量：{valid_count} 个")
            else:
                print(f"文件 {file_path} 不存在！")

        # 删除循环外部的错误代码块
        # choice = input("\n是否继续处理其他文件？(y/n) ").lower()
        # if choice != 'y':
        #    print("程序退出")
        #    break

if __name__ == "__main__":
    try:
        main_loop()
    except Exception as e:
        print(f"发生未捕获异常：{str(e)}")
        input("按任意键退出...")