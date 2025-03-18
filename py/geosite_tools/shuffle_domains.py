import sys
import random
from datetime import datetime
import os  # 新增导入

# 在文件开头添加元信息
__version__ = "1.1.0"
__author__ = "Aethersailor"
__license__ = "CC BY-NC-SA 4.0"
__repo__ = "https://github.com/Aethersailor/Custom_OpenClash_Rule"

# 新增颜色常量
COLOR_TITLE = "\033[1;36m"    # 青色
COLOR_SUCCESS = "\033[1;32m"  # 绿色
COLOR_PROMPT = "\033[1;34m"   # 蓝色
COLOR_WARN = "\033[1;33m"     # 黄色
COLOR_END = "\033[0m"

def main_menu():
    """美化后的主菜单界面"""
    print(f"""
{COLOR_TITLE}{'★' * 40}
  域名处理工具 · 版本 {__version__}
{'★' * 40}{COLOR_END}
{COLOR_PROMPT}作者：{__author__}
仓库：{__repo__}
协议：{__license__} License

【功能特性】
✓ 域名列表随机乱序排列
✓ 按指定行数分割列表文件
✓ 自动生成时间戳文件名
✓ 支持批量文件处理{COLOR_WARN}
提示：可直接拖放文件到本窗口{COLOR_END}
{'-' * 55}""")

def shuffle_domains(file_path):
    # 读取并过滤空行
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    # 原地随机打乱顺序
    random.shuffle(lines)
    
    # 生成带时间戳的新文件名
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    # 修改路径生成方式（使用 os.path 模块）
    dir_name = os.path.dirname(file_path)
    file_name = os.path.basename(file_path)
    base_name, ext = os.path.splitext(file_name)
    new_name = f"{base_name}_shuffled_{timestamp}{ext}"
    new_path = os.path.join(dir_name, new_name)  # 确保同目录
    
    # 写入处理结果
    with open(new_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(lines))
    
    print(f'生成成功！新文件：{new_path}')

def split_domains(file_path, chunk_size=300):
    """新功能：分割域名文件（支持任意文本扩展名）"""
    # 在函数开头添加说明注释
    with open(file_path, 'r', encoding='utf-8') as f:
        lines = [line.strip() for line in f if line.strip()]
    
    total = len(lines)
    if total == 0:
        raise ValueError("文件内容为空")
    
    # 创建输出目录
    src_dir = os.path.dirname(file_path)
    base_name = os.path.splitext(os.path.basename(file_path))[0]
    output_dir = os.path.join(src_dir, f"{base_name}_split")
    os.makedirs(output_dir, exist_ok=True)
    
    # 分割文件
    chunk_num = 0
    for i in range(0, total, chunk_size):
        chunk_num += 1
        chunk = lines[i:i+chunk_size]
        output_path = os.path.join(output_dir, f"{base_name}_part_{chunk_num:03d}.txt")
        
        with open(output_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(chunk))
    
    print(f"分割完成：共 {chunk_num} 个文件")
    return output_dir

def merge_files():
    """新功能：合并shuffle_domains目录下的所有文件"""
    script_dir = os.path.dirname(os.path.abspath(__file__))
    merge_dir = os.path.join(script_dir, "shuffle_domains")
    
    if not os.path.exists(merge_dir):
        raise FileNotFoundError("合并目录不存在")
    
    # 创建输出目录
    output_dir = os.path.join(script_dir, "shuffle_domains_output")
    os.makedirs(output_dir, exist_ok=True)
    
    # 收集所有文件内容并去重
    merged = set()
    valid_files = 0
    for filename in os.listdir(merge_dir):
        file_path = os.path.join(merge_dir, filename)
        if os.path.isfile(file_path):
            try:
                # 自动检测文件编码
                with open(file_path, 'r', encoding='utf-8', errors='replace') as f:
                    content = [line.strip() for line in f if line.strip()]
                    
                if content:
                    merged.update(content)
                    valid_files += 1
            except UnicodeDecodeError:
                print(f"跳过非文本文件：{filename}")
                continue
    
    # 新增有效性检查
    if valid_files == 0:
        raise ValueError("没有找到可合并的有效文件（空文件或非文本文件）")
    if not merged:
        raise ValueError("所有文件内容均为空")
    
    # 生成带时间戳的新文件名
    timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
    output_path = os.path.join(output_dir, f"merged_{timestamp}.txt")
    
    # 写入合并结果
    with open(output_path, 'w', encoding='utf-8') as f:
        f.write('\n'.join(sorted(merged)))
    
    return output_path

# 修改主菜单显示
def main_menu():
    print(f"""
{COLOR_TITLE}{'★' * 40}
  域名处理工具 · 版本 {__version__}
{'★' * 40}{COLOR_END}
{COLOR_PROMPT}作者：{__author__}
仓库：{__repo__}
协议：{__license__} License

【功能特性】
✓ 域名列表随机乱序排列
✓ 按指定行数分割列表文件
✓ 自动生成时间戳文件名
✓ 支持批量文件处理{COLOR_WARN}  # 将合并功能移到特性列表
提示：可直接拖放文件到本窗口{COLOR_END}
{'-' * 55}""")

# 修改主程序选择逻辑
if __name__ == '__main__':
    from colorama import init
    init(autoreset=True)  # 初始化颜色支持
    
    main_menu()
    print(f"{COLOR_PROMPT}功能列表：{COLOR_END}")
    print(" 1. 随机排序文件（洗牌模式）")
    print(" 2. 智能分割文件（可定制行数）")
    print(" 3. 合并目录文件")  # 这是正确的选项位置
    
    while True:
        try:
            choice = input("\n请选择功能 [1/2/3] (按回车退出): ").strip()
            if not choice:
                print("程序已退出")
                break
                
            if choice not in ('1', '2', '3'):
                print("错误：请输入1/2/3选择功能")
                continue
                
            # 修改开始：选项3不需要文件输入
            if choice == '3':
                try:
                    output_path = merge_files()
                    print(f"\n{COLOR_SUCCESS}✓ 合并完成！{COLOR_END}")
                    print(f"{COLOR_PROMPT}文件路径：{output_path}{COLOR_END}")
                except Exception as e:
                    print(f"合并失败：{str(e)}")
                continue  # 跳过后续文件输入逻辑
                
            # 文件路径输入（仅适用于选项1/2）
            raw_path = input("请输入txt文件路径：").strip()
            if not raw_path:
                continue
                
            # 路径处理
            file_path = raw_path.strip(' "\'').replace('"', '')
            if not os.path.exists(file_path):
                print(f"错误：文件不存在 - {file_path}")
                continue
                
            if not os.path.isfile(file_path):  # 新增文件类型验证
                print("错误：输入的不是文件路径")
                continue

            # 执行功能
            if choice == '1':
                shuffle_domains(file_path)
                print(f"\n{COLOR_SUCCESS}✓ 洗牌完成！{COLOR_END}")
                print(f"{COLOR_PROMPT}文件路径：{os.path.dirname(file_path)}{COLOR_END}")
            elif choice == '2':  # 明确选项2的分支
                # 新增行数输入逻辑
                while True:
                    size_input = input("请输入分割行数（默认300）：").strip()
                    if not size_input:
                        chunk_size = 300
                        break
                    try:
                        chunk_size = int(size_input)
                        if chunk_size <= 0:
                            raise ValueError
                        break
                    except ValueError:
                        print("错误：请输入正整数")
                
                output_dir = split_domains(file_path, chunk_size)  # 传递用户输入值
                print(f"\n{COLOR_SUCCESS}✓ 分割完成！{COLOR_END}")
                print(f"{COLOR_PROMPT}保存目录：{output_dir}{COLOR_END}")
            
            print(f"{COLOR_TITLE}{'-' * 55}{COLOR_END}")
            
        except Exception as e:
            print(f"\n错误：{str(e)}")
        except KeyboardInterrupt:
            print("\n操作已取消")
            break