# 独立游戏规则

本目录存放人工整理的游戏 IP 规则。每个文件均可作为 `behavior: classical`、`format: yaml` 的 Rule Provider 使用，不会被主配置、`rule/` 生成器或 GitHub Actions 自动加载和更新。

| 文件 | 游戏与范围 | 来源 |
| --- | --- | --- |
| [`Microsoft-Flight-Simulator-2020.yaml`](Microsoft-Flight-Simulator-2020.yaml) | 《微软模拟飞行 2020》，全区服 | 从 UU 加速器规则整理 |
| [`Overwatch2_Asia(Singapore).yaml`](Overwatch2_Asia%28Singapore%29.yaml) | 《守望先锋 2》，亚服（新加坡） | 使用 [`SSTAP_ip_crawl_tool`](https://github.com/oooldtoy/SSTAP_ip_crawl_tool) 抓取并整理 |

> [!WARNING]
> 游戏服务器地址和 CDN 调度可能变化。规则文件头部记录了整理时间，但本目录没有自动更新流程。使用前应核对实际命中情况，避免过期或过宽的 IP 段影响其他流量。

引用时，将对应文件配置为 `behavior: classical`、`format: yaml` 的 Rule Provider，再在 `rules` 中添加目标 `RULE-SET`。具体策略名称和规则顺序应根据现有配置确定。
