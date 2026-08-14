<a id="-github-workflows"></a>

# 🤖 GitHub Actions 工作流

这里存放了项目的自动化工作流配置。

## 📂 工作流列表

| 文件名 | 描述 | 触发条件 |
| :--- | :--- | :--- |
| [`auto-backup-wiki.yml`](auto-backup-wiki.yml) | 校验 Wiki 目录页和页面完整性后，事务式备份到仓库的 `wiki/` 目录并处理链接替换 | 每 2 小时或手动触发 |
| [`auto-generate-rules.yml`](auto-generate-rules.yml) | 从 `rule/` 顶层和 `rule/game_rule/` 的 `.list` 规则源统一生成 `.yaml` 和 `.mrs` 派生规则，清理失去来源的派生文件，并在精确 SHA 校验成功后调用统一 CDN 发布器 | 对应规则源或生成器变更、源更新工作流同步调用，或手动触发 |
| [`auto-update-encrypted-dns.yml`](auto-update-encrypted-dns.yml) | 从 HaGeZi、DNSCrypt 和编译后的 `geosite:category-doh` 自动更新 `Encrypted_DNS.list`；内容变化后同步等待派生规则生成，派生失败会使本工作流失败 | 每日或手动触发 |
| [`auto-update-game-cdn.yml`](auto-update-game-cdn.yml) | 合并 v2fly 上游与本项目 `Steam_CDN.list`，智能去重后更新 `Game_Download_CDN.list`；内容变化后同步等待派生规则生成 | `Steam_CDN.list` 或生成器变更、每日或手动触发 |
| [`auto-update-mainland.yml`](auto-update-mainland.yml) | 将 `Custom_Clash.ini` 同步为兼容文件 `Custom_Clash_Mainland.ini`，并在内容变化时发布 | `Custom_Clash.ini` 变更或手动触发 |
| [`codeql.yml`](codeql.yml) | 使用扩展安全与质量查询分析 GitHub Actions 和 Python | 相关代码推送、Pull Request、每日或手动触发 |
| [`dependabot-auto-merge.yml`](dependabot-auto-merge.yml) | 等待 Validate、Dependency Review 和 CodeQL 全部成功后，自动压缩合并（squash merge）带有 `automerge` 标签的 Dependabot PR | 上述检查完成 |
| [`dependency-review.yml`](dependency-review.yml) | 阻止 PR 引入任何已知等级的漏洞依赖，并展示 OpenSSF Scorecard 信息 | Pull Request |
| [`pages.yml`](pages.yml) | 构建并部署 MkDocs 文档站点到 GitHub Pages | `wiki/**`、`mkdocs.yml` 变更或手动触发 |
| [`purge-jsdelivr.yml`](purge-jsdelivr.yml) | 按 [CDN 发布契约](../jsdelivr-publish.json) 精确刷新 `@main` 与 `@refs/heads/main` 缓存键；每个请求以 jsDelivr 返回 `finished` 为成功，不等待 CDN 节点传播；无公开文件变化时自动跳过刷新 | `main` 分支推送、规则生成且校验成功，或手动修复范围 |
| [`sync-openclash-overwrite-submodule.yml`](sync-openclash-overwrite-submodule.yml) | 将 `overwrite/OpenClash_Overwrite` 子模块同步到上游 `main` 分支 | 每 2 小时或手动触发 |
| [`validate.yml`](validate.yml) | 校验 Shell、Python、Sub-Store、Wiki 备份、规则派生文件、MRS 和完整 Mihomo 模板；Pull Request 只改 `.list` 来源时会临时生成派生文件再校验 | 代码推送、Pull Request 或手动触发 |
