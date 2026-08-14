# Python 维护脚本

本目录存放规则生成、上游数据合并和安装器同步脚本，主要供项目维护与 GitHub Actions 使用。

> [!CAUTION]
> 部分脚本的默认模式会改写仓库文件。只需检查当前状态时，应使用脚本提供的 `--check` 参数。

## 脚本说明

| 脚本 | 作用 | 主要输出 |
| --- | --- | --- |
| [`generate_game_cdn.py`](generate_game_cdn.py) | 合并 [v2fly/domain-list-community](https://github.com/v2fly/domain-list-community) 上游与 `Steam_CDN.list`，按域名和 CIDR 覆盖关系去重 | `rule/Game_Download_CDN.list` |
| [`generate_rules.py`](generate_rules.py) | 从 `rule/` 顶层的 5 个 `.list` 来源和 `rule/game_rule/**/*.list` 递归生成 Domain、IP、Classical 和端口 YAML，清理失去 `.list` 来源的派生文件；传入 Mihomo 可执行文件时同时生成非空 MRS | `rule/*_Domain.*`、`rule/*_IP.*`、`rule/*_Classical*.yaml`、`rule/game_rule/**/*_Domain.*`、`rule/game_rule/**/*_IP.*`、`rule/game_rule/**/*_Classical*.yaml` |
| [`extract_uu_game_routes.py`](extract_uu_game_routes.py) | 从 UU 路由模式虚拟网卡提取目标 IPv4 路由，过滤本地、保留和被上级网段覆盖的地址 | 指定游戏目录中的区服 `.list` |
| [`sync_installer_common.py`](sync_installer_common.py) | 以完整安装器中的共享函数为维护来源，同步轻量安装器的对应实现 | `shell/install_openclash_dev.sh` |
| [`test_rule_generation.py`](test_rule_generation.py) | 使用 `unittest` 验证 GeoSite 转换、域名与网段去重、派生规则生成，以及游戏 CDN 规则的转换与合并 | 测试结果，不生成仓库文件 |
| [`update_encrypted_dns.py`](update_encrypted_dns.py) | 汇总 HaGeZi、DNSCrypt 与编译后的 `geosite:category-doh`，生成加密 DNS 域名和 IP 规则 | `rule/Encrypted_DNS.list` |

[`archived/`](archived/) 存放已停止维护或不再被工作流调用的历史脚本。

## 维护边界

- 修改 `.list` 来源后，通过 `generate_rules.py` 重建派生文件，不要直接维护派生 YAML 或 MRS。
- 修改完整安装器中的共享函数后，运行 `sync_installer_common.py` 同步轻量安装器。
- `generate_game_cdn.py` 和 `update_encrypted_dns.py` 的写入模式需要访问上游；`--check` 只验证已有输出。
- 本地结果仍需通过仓库工作流中的单元测试、Mihomo 转换或配置校验进行验证。
