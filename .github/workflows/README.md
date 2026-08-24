<a id="-github-workflows"></a>

# 🤖 GitHub Actions 工作流

这里存放了项目的自动化工作流配置。

## 📂 工作流列表

| 文件名 | 描述 | 触发条件 |
| :--- | :--- | :--- |
| [`auto-backup-wiki.yml`](auto-backup-wiki.yml) | 校验 Wiki 目录页和页面完整性后，事务式备份到仓库的 `wiki/` 目录并处理链接替换 | 每 2 小时或手动触发 |
| [`auto-generate-rules.yml`](auto-generate-rules.yml) | 从 `.list` 规则源统一生成 `.yaml` 和 `.mrs` 派生规则，并由受维护的 Clash 模板同步生成 Mainland 与 Stash 兼容文件；完成精确 SHA 校验后调用统一 CDN 发布器 | 对应规则源、模板或生成器变更，源更新工作流同步调用，或手动触发 |
| [`auto-update-encrypted-dns.yml`](auto-update-encrypted-dns.yml) | 从 HaGeZi、DNSCrypt 和编译后的 `geosite:category-doh` 自动更新 `Encrypted_DNS.list`；内容变化后同步等待派生规则生成，派生失败会使本工作流失败 | 每日或手动触发 |
| [`auto-update-game-cdn.yml`](auto-update-game-cdn.yml) | 合并 v2fly 上游与本项目 `Steam_CDN.list`，智能去重后更新 `Game_Download_CDN.list`；内容变化后同步等待派生规则生成 | `Steam_CDN.list` 或生成器变更、每日或手动触发 |
| [`codeql.yml`](codeql.yml) | 使用扩展安全与质量查询分析 GitHub Actions 和 Python | 相关代码推送、Pull Request、每日或手动触发 |
| [`dependabot-auto-merge.yml`](dependabot-auto-merge.yml) | 等待 Validate（含 Dependency Review）和 CodeQL 全部成功后，自动压缩合并（squash merge）带有 `automerge` 标签的 Dependabot PR | 上述检查完成 |
| [`pages.yml`](pages.yml) | 构建并部署 MkDocs 文档站点到 GitHub Pages | `wiki/**`、`mkdocs.yml` 变更或手动触发 |
| [`purge-jsdelivr.yml`](purge-jsdelivr.yml) | 按 [公开发布契约](../jsdelivr-publish.json) 精确刷新 jsDelivr 缓存；生成内容完整、精确 SHA 校验成功且仍为最新 `main` 时，同步部署 Cloudflare Static Assets 热备快照 | `main` 分支推送、规则生成且校验成功，或手动修复范围 |
| [`sync-openclash-overwrite-submodule.yml`](sync-openclash-overwrite-submodule.yml) | 将 `overwrite/OpenClash_Overwrite` 子模块同步到上游 `main` 分支 | 每 2 小时或手动触发 |
| [`validate.yml`](validate.yml) | 校验 Shell、Python、Sub-Store、Wiki 备份、规则派生文件、MRS、完整 Mihomo 模板和 Cloudflare 镜像部署包；Pull Request 还会执行 Dependency Review，也可由发布器校验指定提交 | 代码推送、Pull Request、发布器同步调用或手动触发 |

## Cloudflare 热备发布

`purge-jsdelivr.yml` 是 jsDelivr 与 Cloudflare 热备的统一发布边界。发布器只从指定 Git 提交读取公开文件，不复制工作区内容。涉及规则来源或生成器的提交必须先完成 YAML、MRS 和 Stash 模板生成；未完成时，发布器跳过整份 Static Assets 快照，等待生成工作流携带最终提交再次调用。

Cloudflare 部署使用加密的 GitHub Secret。直接发布使用 Environment `cloudflare-production`；自动更新器经过多层可复用工作流时，通过同名 Repository Secret 和显式 `secrets: inherit` 逐层传递。仓库文件不保存 Cloudflare 账号 ID、区域 ID、部署令牌或运行时重定向令牌。发布任务通过 `--secrets-file` 将区域 ID 和运行时令牌写入 Cloudflare Worker Secret；运行时令牌限制为 `asailor.org` 的 Single Redirects 权限，并与部署令牌分离。
