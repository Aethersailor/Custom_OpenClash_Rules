# 保存为: IP对比工具_防闪退版.py
import ipaddress
import tkinter as tk
from tkinter import filedialog, messagebox
import traceback
import logging
import sys
import os

# 配置日志系统
logging.basicConfig(
    filename='ip_compare.log',
    level=logging.DEBUG,
    format='%(asctime)s - %(levelname)s: %(message)s'
)

class IPComparator:
    def __init__(self):
        self.root = tk.Tk()
        self.root.withdraw()
        self.setup_exception_handler()

    def setup_exception_handler(self):
        """捕获所有未处理异常"""
        def exception_hook(exc_type, exc_value, exc_traceback):
            error_msg = "".join(traceback.format_exception(exc_type, exc_value, exc_traceback))
            logging.critical(f"未捕获的异常:\n{error_msg}")
            
            messagebox.showerror(
                "严重错误",
                f"程序崩溃，详细信息已记录到日志文件：\n{os.path.abspath('ip_compare.log')}\n\n"
                f"错误摘要：\n{str(exc_value)}"
            )
            
            self.root.deiconify()
            self.root.mainloop()
            sys.exit(1)

        sys.excepthook = exception_hook

    def run(self):
        try:
            file1 = self.select_file("选择第一个IP文件")
            file2 = self.select_file("选择第二个IP文件")
            
            result = self.compare_files(file1, file2)
            self.generate_report(result, file1, file2)
            
            messagebox.showinfo("完成", "对比结果已保存到：IP对比报告.txt")
            
        except Exception as e:
            logging.error(f"操作取消: {str(e)}")
            messagebox.showwarning("取消", "操作已取消")
        finally:
            self.root.deiconify()
            self.root.mainloop()

    def select_file(self, title):
        file = filedialog.askopenfilename(
            title=title,
            filetypes=[("Text Files", "*.txt")]
        )
        if not file:
            raise Exception("用户取消文件选择")
        return file

    def read_cidr_ranges(self, filename):
        try:
            with open(filename, 'r') as f:
                networks = []
                for line in f:
                    line = line.strip()
                    if line:
                        try:
                            net = ipaddress.ip_network(line, strict=False)
                            networks.append(net)
                        except ValueError as e:
                            logging.warning(f"无效CIDR格式: {line} ({str(e)})")
                return networks
        except Exception as e:
            logging.error(f"文件读取失败: {filename}")
            raise

    def compare_files(self, file1, file2):
        """核心对比逻辑"""
        def merge_ranges(networks):
            if not networks:
                return []
            sorted_nets = sorted(networks, key=lambda x: x.network_address)
            merged = [sorted_nets[0]]
            for net in sorted_nets[1:]:
                last = merged[-1]
                if net.subnet_of(last):
                    continue
                try:
                    merged.append(net)
                except:
                    merged.extend(list(last.address_exclude(net)))
            return merged

        file1_nets = merge_ranges(self.read_cidr_ranges(file1))
        file2_nets = merge_ranges(self.read_cidr_ranges(file2))

        set1 = set(file1_nets)
        set2 = set(file2_nets)

        return {
            'file1_only': sorted(set1 - set2, key=lambda x: x.network_address),
            'file2_only': sorted(set2 - set1, key=lambda x: x.network_address),
            'common': sorted(set1 & set2, key=lambda x: x.network_address),
            'file1_total': len(file1_nets),
            'file2_total': len(file2_nets)
        }

    def generate_report(self, result, file1, file2):
        report = [
            "IP地址范围深度对比报告",
            "="*40,
            f"文件1: {os.path.basename(file1)} ({result['file1_total']} CIDR)",
            f"文件2: {os.path.basename(file2)} ({result['file2_total']} CIDR)",
            "-"*40,
            f"文件1独有 ({len(result['file1_only'])} CIDR):",
            *[str(c) for c in result['file1_only']],
            "\n" + "-"*40,
            f"文件2独有 ({len(result['file2_only'])} CIDR):",
            *[str(c) for c in result['file2_only']],
            "\n" + "="*40,
            f"共同存在 ({len(result['common'])} CIDR)"
        ]
        
        report_path = os.path.join(os.getcwd(), "IP对比报告.txt")
        with open(report_path, 'w', encoding='utf-8') as f:
            f.write('\n'.join(report))
        
        # 自动打开结果文件
        if os.name == 'nt':
            os.startfile(report_path)
        else:
            opener = 'open' if sys.platform == 'darwin' else 'xdg-open'
            os.system(f'{opener} "{report_path}"')

if __name__ == "__main__":
    app = IPComparator()
    app.run()
    # 添加以下代码防止Windows下窗口立即关闭
    if os.name == 'nt':
        input("按Enter键退出...")