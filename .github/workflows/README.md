# 🤖 GitHub Workflows

这里存放了项目的自动化工作流配置。

## ⚙️ 分支说明

- 可选仓库变量：`WORK_BRANCH`
- 用途：当默认分支被切换为占位空分支（如 `rm`）时，工作流会优先在 `WORK_BRANCH` 指定的真实工作分支上执行。
- 默认行为：若未设置 `WORK_BRANCH`，多数流程回退到 `main`。

## 📂 工作流列表

| 文件名 | 描述 | 触发条件 |
| :--- | :--- | :--- |
| **[auto-backup-wiki.yml](auto-backup-wiki.yml)** | 自动备份 GitHub Wiki 内容到仓库的 `wiki/` 目录，并处理链接替换 | 每 30 分钟 / 手动触发 |
| **[auto-generate-rules.yml](auto-generate-rules.yml)** | 从 `.list` 规则文件自动生成 `.yaml` 和 `.mrs` 格式的规则集 | `rule/*.list` 变更 / 手动触发 |
| **[auto-update-game-cdn.yml](auto-update-game-cdn.yml)** | 从 v2fly 上游自动更新 `Game_Download_CDN.list` 规则文件 | 每 8 小时 / 手动触发 |
| **[auto-update-mainland.yml](auto-update-mainland.yml)** | 根据 `Custom_Clash.ini` 自动生成 `Custom_Clash_Mainland.ini` | `cfg/Custom_Clash.ini` 变更 / 手动触发 |
| **[clean_failed_cancelled_runs.yml](clean_failed_cancelled_runs.yml)** | 清理所有失败或取消的 Workflow 运行记录，并删除自身运行记录 | 手动触发 |
| **[codeql.yml](codeql.yml)** | CodeQL 代码安全性分析（分析 Actions 和 Python） | Push / Pull Request / 每日定时 / 手动触发 |
| **[dependabot-auto-merge.yml](dependabot-auto-merge.yml)** | 自动合并带有 `automerge` 标签的 Dependabot PR | Dependabot PR 打开/更新 |
| **[purge-jsdelivr.yml](purge-jsdelivr.yml)** | 自动刷新 jsDelivr CDN 缓存，并实现防抖（60 秒等待批量合并提交） | `cfg/`, `rule/`, `game_rule/`, `shell/`, `overwrite/` 变更 / 手动触发 |
| **[push-doc-to-wiki.yml](push-doc-to-wiki.yml)** | 将 `doc/` 目录内容同步到 GitHub Wiki 的 `doc/` 目录 | `doc/**` 变更 / 手动触发 |
| **[sync-doc-assets-to-wiki-doc.yml](sync-doc-assets-to-wiki-doc.yml)** | 将 `doc/` 目录中的非 Markdown 资源同步到 `wiki/doc/` 供 Pages 使用 | `doc/**` 变更 / 手动触发 |
| **[sync_custom_clash.yml](sync_custom_clash.yml)** | 同步 `Custom_Clash.ini` 到衍生项目 `Custom_Clash_Rules`，并调整分流规则 | `cfg/Custom_Clash.ini` 变更 / 手动触发 |

## 📂 子目录

- **[archived](archived/README.md)**: 存放已废弃或不再使用的工作流。
