import re

# 文件路径
file1_path = "cfg/Custom_Clash.ini"
file2_path = "cfg/Custom_Clash_Mainland.ini"

# 正则匹配 raw.githubusercontent.com 形式的链接
RAW_GITHUB_PATTERN = re.compile(
    r"https://raw\.githubusercontent\.com/([^/]+)/([^/]+)/([^/]+)/(.*)"
)

def convert_to_jsdelivr(url: str) -> str:
    """
    将 raw.githubusercontent.com 的地址转换为 testingcf.jsdelivr.net 地址
    例如：
    https://raw.githubusercontent.com/user/repo/branch/path/to/file
    ->
    https://testingcf.jsdelivr.net/gh/user/repo@branch/path/to/file
    """
    return RAW_GITHUB_PATTERN.sub(
        r"https://testingcf.jsdelivr.net/gh/\1/\2@\3/\4",
        url
    )

def generate_mainland():
    with open(file1_path, "r", encoding="utf-8") as f1:
        content = f1.read()

    # 替换所有 raw.githubusercontent.com 为 jsDelivr 格式
    content = convert_to_jsdelivr(content)

    # 写入新文件
    with open(file2_path, "w", encoding="utf-8") as f2:
        f2.write(content)

if __name__ == "__main__":
    generate_mainland()
    print(f"File '{file2_path}' has been updated based on '{file1_path}'.")
