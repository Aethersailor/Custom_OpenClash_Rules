# 🤖 GitHub Workflows

这里存放了项目的自动化工作流配置。

## 📂 工作流列表

| 文件名 | 描述 | 触发条件 |
| :--- | :--- | :--- |
| **[auto-backup-wiki.yml](auto-backup-wiki.yml)** | 自动备份 Wiki 内容到指定仓库 | 每日定时 / 手动触发 |
| **[auto-generate-rules.yml](auto-generate-rules.yml)** | 自动生成 OpenClash 规则文件（核心） | 每日定时 / 规则文件变更 / 手动触发 |
| **[auto-update-game-cdn.yml](auto-update-game-cdn.yml)** | 自动更新游戏下载 CDN 列表 | 每日定时 / 手动触发 |
| **[auto-update-mainland.yml](auto-update-mainland.yml)** | 自动更新中国大陆白名单规则 | 每日定时 / 手动触发 |
| **[clean_failed_cancelled_runs.yml](clean_failed_cancelled_runs.yml)** | 清理失败或取消的 Workflow 运行记录 | 每日定时 / 手动触发 |
| **[codeql.yml](codeql.yml)** | CodeQL 代码安全性分析 | Push / Pull Request / 定时 |
| **[dependabot-auto-merge.yml](dependabot-auto-merge.yml)** | 自动合并 Dependabot 的 PR | Dependabot PR |
| **[purge-jsdelivr.yml](purge-jsdelivr.yml)** | 自动刷新 jsDelivr CDN 缓存 | 规则文件 Push / 定时 / 手动触发 |
| **[push-doc-to-wiki.yml](push-doc-to-wiki.yml)** | 将文档自动同步到 GitHub Wiki | 文档文件变更 |
| **[sync_custom_clash.yml](sync_custom_clash.yml)** | 同步自定义 Clash配置 | 每日定时 / 手动触发 |

## 📂 子目录

- **[archived](archived/README.md)**: 存放已废弃或不再使用的工作流。
