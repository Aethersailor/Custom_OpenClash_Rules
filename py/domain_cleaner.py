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

def process_domain_file(file_path, output_path=None):
    """核心处理函数"""
    processed = set()
    output_lines = []
    china_domains = load_china_domains()
    china_duplicates = 0

    with open(file_path, 'r', encoding='utf-8') as f:
        # 第一阶段：文件内部去重
        raw_lines = [line.strip() for line in f if line.strip() and not line.startswith('#')]
        
        # 第二阶段：双重过滤
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
    save_path = output_path or file_path.replace('.txt', '_cleaned.txt')  # 修改处
    with open(save_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sorted(output_lines)))
        
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

# 在文件顶部添加版本和元信息
__version__ = "1.0.0"
__author__ = "Aethersailor"
__license__ = "MIT"
__repo__ = "https://github.com/Aethersailor/Custom_OpenClash_Rules"

def main_loop():
    """新增交互式主循环"""
    # 美化后的欢迎信息
    print(f"""
    \033[1;36m{'*' * 40}
    域名清理工具 · 版本 {__version__}
    {'*' * 40}
    \033[0m作者：{__author__}
    仓库：{__repo__}
    协议：{__license__} License
    
    \033[1;34m【功能描述】\033[0m
    将本地/在线规则文件转换纯域名列表格式
    自动执行以下处理流程：
    ✓ 解析DOMAIN/DOMAIN-SUFFIX格式输入
    ✓ 提取有效主域名（排除.cn结尾域名）
    ✓ 文件内去重 + 过滤geosite@cn域名
    ✓ 生成标准化域名列表文件
    \033[33m提示：支持拖放文件到窗口操作\033[0m
    """)
    while True:
        print("=== 域名清理工具 ===")
        while True:
            # 重构后的主程序逻辑
            if len(sys.argv) < 2:
                user_input = input("\n请输入文件路径/URL（直接回车使用domain_cleaner.txt）：").strip()
                if not user_input:
                    file_path = os.path.join(os.path.dirname(__file__), 'domain_cleaner.txt')
                else:
                    file_path = user_input
            else:
                file_path = sys.argv[1]

        # 修复1：添加文件存在性验证（原代码缩进错误导致逻辑错误）
        if file_path.startswith(('http://', 'https://')):
            print(f"开始下载：{file_path}")
            content = download_url(file_path)
            if content:
                # 修复1：添加临时文件路径定义
                temp_file = os.path.join(os.path.dirname(__file__), 'temp_download.txt')
                # 修复2：处理下载内容前创建输出文件名
                url_path = urlparse(file_path).path
                base_name = os.path.basename(url_path) or 'downloaded'
                output_name = os.path.splitext(base_name)[0] + '.txt'
                
                with open(temp_file, 'w', encoding='utf-8') as f:
                    f.write(content)
                
                # 修复3：确保使用绝对路径保存结果
                output_path = os.path.join(os.path.dirname(__file__), output_name)
                valid_count, china_duplicates = process_domain_file(temp_file, output_path)
                os.remove(temp_file)
                # 美化处理结果输出
                print(f"\n\033[32m✓ 处理完成！\033[0m")
                print(f"════════════════════════════")
                print(f"有效域名数量\t{valid_count} 个")
                print(f"国内域名过滤\t{china_duplicates} 个")
                print(f"输出文件路径\t{output_path}")
                if clipboard_available:
                    print(f"\033[33m提示：文件路径已复制到剪贴板\033[0m")
                
                print(f"输出文件路径：{output_path}")
                if clipboard_available:
                    pyperclip.copy(output_path)
                    print("文件路径已复制剪贴板")
                else:
                    print("注意：剪贴板功能不可用，请先安装pyperclip库")
                print(f"过滤国内重复域名：{china_duplicates} 个")

        else:
            if os.path.isfile(file_path):
                output_name = os.path.abspath(  # 获取绝对路径
                    os.path.splitext(file_path)[0] + '_cleaned.txt'
                )
                valid_count, china_duplicates = process_domain_file(file_path, output_name)
                
                print(f"\n处理完成！输出文件：{output_name}")
                print(f"文件路径：{output_name}") 
                if clipboard_available:
                    pyperclip.copy(output_name)
                    print("路径已复制剪贴板")
                else:
                    print("注意：剪贴板功能不可用，请先安装pyperclip库")
                print(f"过滤国内重复域名：{china_duplicates} 个")
                print(f"有效域名数量：{valid_count} 个")
                
            else:
                print(f"文件 {file_path} 不存在！")

        # 修复4：移除重复的process_domain_file调用
        sys.argv = [sys.argv[0]]
        
        # 新增继续处理提示
        choice = input("\n是否继续处理其他文件？(y/n) ").lower()
        if choice != 'y':
            print("程序退出")
            break

if __name__ == "__main__":
    try:
        main_loop()
    except Exception as e:
        print(f"发生未捕获异常：{str(e)}")
        input("按任意键退出...")