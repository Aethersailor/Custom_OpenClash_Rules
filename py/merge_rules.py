import os
import requests
import subprocess

# 定义规则 URL
RULE_URLS = [
    "https://raw.githubusercontent.com/ACL4SSR/ACL4SSR/master/Clash/LocalAreaNetwork.list",
    "https://raw.githubusercontent.com/GeQ1an/Rules/master/QuantumultX/Filter/LAN.list",
    "https://raw.githubusercontent.com/Loyalsoldier/clash-rules/release/lancidr.txt",
    "https://raw.githubusercontent.com/Loyalsoldier/clash-rules/release/private.txt",
    "https://raw.githubusercontent.com/dler-io/Rules/main/Clash/Provider/LAN.yaml"
]

# 输出文件路径
OUTPUT_FILE = "rule/Lan.list"

# 下载规则文件
def download_rules():
    rules = []
    for url in RULE_URLS:
        response = requests.get(url)
        if response.status_code == 200:
            rules.extend(response.text.splitlines())
        else:
            print(f"Failed to fetch rules from {url}")
    return rules

# 分类规则
def classify_rules(rules):
    domain_rules = set()
    domain_suffix_rules = set()
    domain_keyword_rules = set()
    ip_cidr_rules = set()

    for rule in rules:
        rule = rule.strip()
        if rule.startswith("DOMAIN-SUFFIX,"):
            domain_suffix_rules.add(rule.split(",")[1])
        elif rule.startswith("DOMAIN,"):
            domain_rules.add(rule.split(",")[1])
        elif rule.startswith("DOMAIN-KEYWORD,"):
            domain_keyword_rules.add(rule.split(",")[1])
        elif "IP-CIDR" in rule:
            ip_cidr_rules.add(rule.split(",")[1].split(',')[0])
    return domain_rules, domain_suffix_rules, domain_keyword_rules, ip_cidr_rules

# 优化 IP-CIDR 规则
def optimize_ip_cidr(ip_cidr_rules):
    # 将 IP-CIDR 规则写入临时文件
    temp_file = "temp_cidr.txt"
    with open(temp_file, "w") as f:
        f.writelines(f"{cidr}\n" for cidr in ip_cidr_rules)

    # 使用 ipcalc 处理规则并生成合并后的结果
    optimized_file = "optimized_cidr.txt"
    with open(optimized_file, "w") as f:
        subprocess.run(["ipcalc", "--merge", temp_file], stdout=f)

    # 读取优化后的规则
    with open(optimized_file, "r") as f:
        optimized_cidrs = set(line.strip() for line in f if line.strip())

    # 清理临时文件
    os.remove(temp_file)
    os.remove(optimized_file)

    return optimized_cidrs

# 输出规则
def write_output(domain_rules, domain_suffix_rules, domain_keyword_rules, ip_cidr_rules):
    os.makedirs(os.path.dirname(OUTPUT_FILE), exist_ok=True)
    with open(OUTPUT_FILE, "w") as f:
        f.write("# Merged LAN Rules\n")
        for rule in sorted(domain_suffix_rules):
            f.write(f"DOMAIN-SUFFIX,{rule}\n")
        for rule in sorted(domain_rules):
            f.write(f"DOMAIN,{rule}\n")
        for rule in sorted(domain_keyword_rules):
            f.write(f"DOMAIN-KEYWORD,{rule}\n")
        for cidr in sorted(ip_cidr_rules):
            f.write(f"IP-CIDR,{cidr}\n")

# 主函数
def main():
    # 下载和分类规则
    rules = download_rules()
    domain_rules, domain_suffix_rules, domain_keyword_rules, ip_cidr_rules = classify_rules(rules)
    
    # 优化 IP-CIDR 规则
    optimized_cidrs = optimize_ip_cidr(ip_cidr_rules)
    
    # 输出优化后的规则
    write_output(domain_rules, domain_suffix_rules, domain_keyword_rules, optimized_cidrs)

if __name__ == "__main__":
    main()
