import sys
import os
import tldextract

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

def process_domain_file(file_path):
    """核心处理函数"""
    processed = set()
    output_lines = []
    
    with open(file_path, 'r', encoding='utf-8') as f:
        for line in f:
            # 过滤关键字行
            if 'DOMAIN-KEYWORD' in line:
                continue
                
            # 清理前缀
            clean_line = line.replace('DOMAIN-SUFFIX,', '').replace('DOMAIN,', '').strip()
            
            # 提取并验证域名
            main_domain = extract_main_domain(clean_line)
            if not main_domain or not is_valid_domain(main_domain):
                continue
                
            # 去重处理
            if main_domain not in processed:
                processed.add(main_domain)
                output_lines.append(main_domain)

    # 保存结果
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sorted(output_lines)))
    print(f"处理完成！有效域名数量：{len(output_lines)}")

if __name__ == "__main__":
    if len(sys.argv) < 2:
        input("请拖放txt文件到本脚本 (按回车退出)...")
    else:
        target_file = sys.argv[1]
        if os.path.isfile(target_file) and target_file.lower().endswith('.txt'):
            process_domain_file(target_file)
        else:
            print("错误：仅支持txt文件")