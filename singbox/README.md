# Sing-box ALL 规则集 + 策略组模板

整合 5 个规则仓库的 **sing-box 完整模板**（策略组 + 分流规则），每日自动更新。

## 文件说明

| 文件 | 说明 |
|---|---|
| `Custom_All.json` | sing-box 完整模板：20 策略组 + 30 规则集 + 16 分流规则 |
| `ruleset/` | 规则集缓存目录（模板引用 remote URL，运行时自动下载） |
| `../py/generate_singbox_all.py` | 模板生成脚本 |

## 规则来源（5 仓库）

| 仓库 | 内容 | 格式 |
|---|---|---|
| [Aethersailor/Custom_OpenClash_Rules](https://github.com/Aethersailor/Custom_OpenClash_Rules) | 自定义直连/代理/Steam | 本仓库 |
| [senshinya/singbox_ruleset](https://github.com/senshinya/singbox_ruleset) | blackmatrix7 全集精选（流媒体/游戏/AI/大厂 25 分类） | .srs |
| [REIJI007/AdBlock_Rule_For_Sing-box](https://github.com/REIJI007/AdBlock_Rule_For_Sing-box) | 广告拦截（每 20 分钟更新） | .srs |
| [cmontage/proxyrules-cm](https://github.com/cmontage/proxyrules-cm) | GFW 规则 | .yaml |
| [Dreista/sing-box-rule-set-cn](https://github.com/Dreista/sing-box-rule-set-cn) | 中国大陆域名/IP（每日更新） | .srs |

## 策略组（20 个）

- 节点选择 / 自动选择（urltest）/ 本地直连 / 漏网之鱼
- 分流组：AI 平台、奈飞视频、油管视频、国际媒体、外服游戏、Steam平台、国内流量、广告拦截
- 地区节点：香港/美国/日本/新加坡/台湾/韩国（按节点名自动分流）

## 分流规则（16 条，自上而下）

1. 基础：sniff → DNS 劫持 → 内网直连 → 拒 QUIC/BT
2. 国内直连（Dreista cn/cnip）
3. 广告拦截（REIJI007）
4. 流媒体：Netflix/PrimeVideo/HBO/Hulu/AppleTV → 奈飞视频
5. YouTube → 油管视频
6. Disney/TikTok/Twitch/Spotify → 国际媒体
7. AI：OpenAI/Anthropic/Gemini/Copilot → AI 平台
8. Steam → Steam平台
9. Epic/PlayStation/Xbox/Nintendo/Riot → 外服游戏
10. 大厂：Google/Microsoft/Amazon/Adobe → 代理
11. GFW（cmontage + Dreista filter.txt）→ 代理
12. 兜底 → 漏网之鱼

## 使用（ShellCrash sing-box）

1. 把 `Custom_All.json` 放到 `$CRASHDIR/templates/`
2. TUI: `mm` → 6 配置文件管理 → b 本地生成配置文件 → 2 选择规则模版 → 选 Custom_All
3. 或手动：`sed -i 's|provider_temp_singbox=.*|provider_temp_singbox=/path/to/Custom_All.json|' $CRASHDIR/configs/ShellCrash.cfg`

## 使用（sing-box 原生）

把 `route.rule_set` 的 `path` 改成本地路径，或直接用 remote URL（自动下载更新）。

## 自动更新

GitHub Actions `.github/workflows/auto-update-singbox-all.yml` 每天 UTC 4:00 重新生成模板并提交。

> ⚠️ 注意：规则集总数建议控制在 30 个以内（路由器内存有限）。如需更多分类，编辑 `py/generate_singbox_all.py` 的 `RULE_SETS` 列表自行添加。
