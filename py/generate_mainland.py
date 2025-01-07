# 文件路径
file1_path = "cfg/Custom_Clash.ini"
file2_path = "cfg/Custom_Clash_Mainland.ini"

def generate_mainland():
    with open(file1_path, "r", encoding="utf-8") as f1:
        content = f1.read()

    # 替换域名
    content = content.replace(
        "https://raw.githubusercontent.com",
        "https://gh-proxy.com/https://raw.githubusercontent.com"
    )

    # 写入文件2
    with open(file2_path, "w", encoding="utf-8") as f2:
        f2.write(content)

if __name__ == "__main__":
    generate_mainland()
    print(f"File '{file2_path}' has been updated based on '{file1_path}'.")
