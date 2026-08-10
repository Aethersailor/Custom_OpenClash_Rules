# 规则文件

本目录存放本项目维护或保留的 OpenClash 与 Mihomo 规则文件。当前自动生成流程以本目录顶层的 5 个 `.list` 文件和 [`game_rule/`](game_rule/) 中的独立游戏规则为来源，生成 YAML 与 MRS Rule Provider；目录中另有少量人工维护或历史兼容文件。

> [!IMPORTANT]
> 文件位于本目录中，不代表 OpenClash 会自动加载。是否生效取决于配置中的 `rule-providers` 和 `rules` 引用，以及规则顺序和目标策略。

## 自动生成的规则族

| 来源文件 | 内容 | 更新方式 |
| --- | --- | --- |
| [`Custom_Direct.list`](Custom_Direct.list) | 本项目收录的补充直连规则 | 用户提交与维护者审核 |
| [`Custom_Proxy.list`](Custom_Proxy.list) | 本项目收录的补充代理规则 | 用户提交与维护者审核 |
| [`Steam_CDN.list`](Steam_CDN.list) | Steam 下载 CDN 补充规则 | 人工维护，并参与游戏下载规则合并 |
| [`Encrypted_DNS.list`](Encrypted_DNS.list) | HaGeZi、DNSCrypt 与 `geosite:category-doh` 汇总规则 | 工作流定期更新 |
| [`Game_Download_CDN.list`](Game_Download_CDN.list) | GeoSite 游戏下载规则与 `Steam_CDN.list` 的合并结果 | 工作流定期更新，保留为兼容入口 |

`py/generate_rules.py` 根据规则类型生成下列文件：

| 文件名形式 | `behavior` | 内容 |
| --- | --- | --- |
| `*_Domain.yaml` | `domain` | 纯域名规则 |
| `*_IP.yaml` | `ipcidr` | 纯 IPv4 和 IPv6 CIDR 规则 |
| `*_Classical.yaml` | `classical` | 域名、IP 和端口等 Classical 规则 |
| `*_Classical_IP.yaml` | `classical` | IP 与端口规则 |
| `*_Classical_Port.yaml` | `classical` | 纯端口规则；当前仅为 `Custom_Direct` 生成 |
| `*_Domain.mrs` | `domain` | Domain MRS 规则 |
| `*_IP.mrs` | `ipcidr` | IP-CIDR MRS 规则 |

MRS 当前只用于 `domain` 和 `ipcidr` Rule Provider。Classical 与端口规则继续使用 YAML。预留 Provider 暂时没有规则时，YAML 使用 `payload: []`；生成器保留已有的空 MRS 占位文件，待后续加入规则后再重建。

## 其他文件

| 文件 | 状态 | 说明 |
| --- | --- | --- |
| [`Custom_Port_Direct.yaml`](Custom_Port_Direct.yaml) | 使用中 | 定义 80、443 以外的目标端口范围；当前配置将其交给「非标端口」策略组，不由 `.list` 生成 |
| [`Lan.list`](Lan.list) | 独立保留 | LAN 规则集合；当前主配置未直接引用 |
| [`IPTVMainland_Domain.list`](IPTVMainland_Domain.list) | 独立保留 | IPTV 域名历史列表；当前没有自动更新流程，主配置未直接引用 |
| [`Talkatone.list`](Talkatone.list) | 历史兼容 | 已停止更新；当前 Full 配置改用 `geosite:talkatone` |
| [`archived/`](archived/) | 已归档 | 已停止维护的旧规则，只用于历史参考 |

独立游戏规则位于 [`game_rule/`](game_rule/)，并由同一个工作流生成对应的 YAML 与 MRS 派生文件。

## 修改与验证

修改自动生成规则族时，只编辑对应的 `.list` 来源文件，不要直接编辑同名 YAML 或 MRS 派生文件。生成与一致性检查由 `py/generate_rules.py` 和仓库工作流完成。

使用规则前应确认：

- Provider 的 `behavior`、`format` 与文件内容一致；
- Provider 已下载并解析成功；
- `rules` 中存在对应的 `RULE-SET` 引用；
- 规则顺序和目标策略符合预期；
- 实际连接能够命中目标规则。
