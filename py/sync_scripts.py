import os
import shutil
import argparse
from colorama import Fore, Style

def main():
    # 配置颜色和样式
    COLORS = {
        "info": Fore.CYAN,
        "success": Fore.GREEN,
        "error": Fore.RED,
        "reset": Style.RESET_ALL
    }
    
    # 初始化参数解析
    # 删除原有的 --force 参数
    parser = argparse.ArgumentParser(description='同步脚本文件到目标目录（自动覆盖）')
    
    args = parser.parse_args()
    
    # 配置路径
    source_dir = os.path.dirname(os.path.abspath(__file__))
    target_dir = os.path.join(source_dir, "Custom_OpenClash_Rules", "py")
    scripts = [
        "domain_cleaner.py", 
        "insert_domain.py", 
        "shuffle_domains.py",
        os.path.basename(__file__)  # 包含脚本自身
    ]

    # 创建目标目录
    if not os.path.exists(target_dir):
        os.makedirs(target_dir)
        print(f"{COLORS['info']}[信息] 已创建目录: {target_dir}{COLORS['reset']}")

    # 文件同步（直接覆盖）
    counter = 0
    for script in scripts:
        src = os.path.join(source_dir, script)
        dst = os.path.join(target_dir, script)
        
        try:
            if not os.path.exists(src):
                raise FileNotFoundError(f"源文件不存在: {src}")
                
            # 删除存在性检查，直接执行覆盖操作
            shutil.copy2(src, dst)
            counter += 1
            print(f"{COLORS['success']}[成功] 已覆盖: {script} → {dst}{COLORS['reset']}")
            
        except Exception as e:
            print(f"{COLORS['error']}[错误] 同步失败: {str(e)}{COLORS['reset']}")

    # 统计结果
    separator = f"{COLORS['success']}" + "═" * 50 + f"{COLORS['reset']}"
    print(f"\n{separator}")
    if counter > 0:
        print(f"{COLORS['success']}✔ 同步完成！共复制 {counter} 个文件{COLORS['reset']}")
    else:
        print(f"{COLORS['error']}✘ 未复制任何文件{COLORS['reset']}")
    print(separator)
    
    input("\n按 Enter 键继续...")

if __name__ == "__main__":
    main()