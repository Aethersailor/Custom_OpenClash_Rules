# 🤖 GitHub Workflows

这里存放了项目的自动化工作流配置。

## 📂 工作流列表

| 文件名 | 描述 | 触发条件 |
| :--- | :--- | :--- |
| **[auto-backup-wiki.yml](auto-backup-wiki.yml)** | 自动备份 GitHub Wiki 内容到仓库的 `wiki/` 目录，并处理链接替换 | 每 2 小时 / 手动触发 |
| **[auto-generate-rules.yml](auto-generate-rules.yml)** | 从 `.list` 规则文件自动生成 `.yaml` 和 `.mrs` 格式的规则集 | `rule/*.list` 变更 / 手动触发 |
| **[auto-update-encrypted-dns.yml](auto-update-encrypted-dns.yml)** | 从 HaGeZi、DNSCrypt 和编译后的 `geosite:category-doh` 自动更新 `Encrypted_DNS.list` | 每日 / 手动触发 |
| **[auto-update-game-cdn.yml](auto-update-game-cdn.yml)** | 从 v2fly 上游自动更新 `Game_Download_CDN.list` 规则文件 | 每日 / 手动触发 |
| **[auto-update-mainland.yml](auto-update-mainland.yml)** | 根据 `Custom_Clash.ini` 自动生成 `Custom_Clash_Mainland.ini` | `cfg/Custom_Clash.ini` 变更 / 手动触发 |
| **[codeql.yml](codeql.yml)** | CodeQL 代码安全性分析（分析 Actions 和 Python） | 相关代码 Push / Pull Request / 每周 / 手动触发 |
| **[dependabot-auto-merge.yml](dependabot-auto-merge.yml)** | 自动合并带有 `automerge` 标签的 Dependabot PR | Dependabot PR 打开/更新 |
| **[pages.yml](pages.yml)** | 构建并部署 MkDocs 文档站点到 GitHub Pages | `wiki/**`、`mkdocs.yml` 变更 / 手动触发 |
| **[purge-jsdelivr.yml](purge-jsdelivr.yml)** | 在规则生成或公开文件变化后刷新 jsDelivr 缓存 | 相关生成工作流完成、公开文件变更 / 手动触发 |
| **[push-doc-to-wiki.yml](push-doc-to-wiki.yml)** | 将 `doc/` 同步到 GitHub Wiki，并触发 Wiki 备份与 Pages 部署 | `doc/**` 变更 / 手动触发 |
| **[sync-openclash-overwrite-submodule.yml](sync-openclash-overwrite-submodule.yml)** | 同步两个 `OpenClash_Overwrite` 子模块入口 | 每日 / 手动触发 |
| **[validate.yml](validate.yml)** | 校验 Shell、规则派生文件、MRS 和完整 Mihomo 模板 | Push / Pull Request / 手动触发 |
