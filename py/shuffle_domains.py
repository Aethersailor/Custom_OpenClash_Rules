import sys
import random
from datetime import datetime
import os  # 新增导入

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
def split_domains(file_path, chunk_size=300):  # 修改默认值为300
    """新功能：分割域名文件"""
    # 函数剩余部分保持不变
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

if __name__ == '__main__':
    print("=== 域名处理工具 ===")
    print("功能列表：")
    print("1. 随机排序文件")
    print("2. 分割文件（默认300行/文件）")  # 修改描述
    
    while True:
        try:
            # 功能选择
            choice = input("\n请选择功能 [1/2] (按回车退出): ").strip()
            if not choice:
                print("程序已退出")
                break
                
            if choice not in ('1', '2'):
                print("错误：请输入1或2选择功能")
                continue
                
            # 文件路径输入
            raw_path = input("请输入txt文件路径：").strip()
            if not raw_path:
                continue
                
            # 路径处理
            file_path = raw_path.strip(' "\'').replace('"', '')
            if not os.path.exists(file_path):
                print(f"错误：文件不存在 - {file_path}")
                continue
                
            if not file_path.lower().endswith('.txt'):
                print("错误：仅支持.txt文件")
                continue

            # 执行功能
            if choice == '1':
                shuffle_domains(file_path)
                print(f"\n处理成功！新文件保存在：{os.path.dirname(file_path)}")
            else:
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
                print(f"分割文件保存在：{output_dir}")
            
            print("-" * 50)
            
        except Exception as e:
            print(f"\n错误：{str(e)}")
        except KeyboardInterrupt:
            print("\n操作已取消")
            break