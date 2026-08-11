# 独立游戏规则

本目录按“一个游戏一个文件夹”存放人工整理的游戏 IP 规则。游戏目录中的 `.list` 文件是维护入口；规则生成工作流会在同一目录生成 IP-CIDR YAML、Classical YAML 和非空 IP-CIDR MRS，但不会更新规则内容或将其加载到主配置。

| 来源文件 | 游戏与范围 | 来源 |
| --- | --- | --- |
| [`Battlefield-1/`](Battlefield-1/) | 《战地风云 1》Windows PC 客户端，UU 可选区服 | 从 UU 加速器路由模式逐客户端、逐区服提取并分别对应 |
| [`Battlefield-6/`](Battlefield-6/) | 《战地风云 6》，UU 可选区服 | 从 UU 加速器路由模式逐区提取 |
| [`Microsoft-Flight-Simulator-2020/`](Microsoft-Flight-Simulator-2020/) | 《微软模拟飞行 2020》，全区服 | 从 UU 加速器规则整理 |
| [`Overwatch2/`](Overwatch2/) | 《守望先锋 2》，亚服（新加坡） | 使用 [`SSTAP_ip_crawl_tool`](https://github.com/oooldtoy/SSTAP_ip_crawl_tool) 抓取并整理 |

每个来源会生成下列 Rule Provider 文件：

- `*_IP.yaml`：`behavior: ipcidr`、`format: yaml`；
- `*_IP.mrs`：`behavior: ipcidr`、`format: mrs`；
- `*_Classical.yaml` 和 `*_Classical_IP.yaml`：`behavior: classical`、`format: yaml`；
- `*_Domain.yaml`：当前游戏规则不含域名，因此内容为空，不生成空的 Domain MRS。

> [!WARNING]
> 游戏服务器地址和 CDN 调度可能变化。规则文件头部记录了整理时间，但本目录没有自动更新流程。使用前应核对实际命中情况，避免过期或过宽的 IP 段影响其他流量。

每个游戏必须使用独立文件夹；文件名必须以游戏文件夹名称加下划线开头，例如 `Battlefield-6/Battlefield-6_Europe.list`。同一游戏的不同大区分别使用独立 `.list`。修改规则时，只编辑对应的 `.list` 来源文件，不要直接编辑 YAML 或 MRS 派生文件。引用时，根据所选文件配置匹配的 `behavior` 和 `format`，再在 `rules` 中添加目标 `RULE-SET`。具体策略名称和规则顺序应根据现有配置确定。
