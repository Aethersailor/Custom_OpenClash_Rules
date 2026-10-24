<a id="-github-workflows"></a>

# 🤖 GitHub Actions 工作流

这里存放了项目的自动化工作流配置。

## 📂 工作流列表

| 文件名 | 描述 | 触发条件 |
| :--- | :--- | :--- |
| [`auto-backup-wiki.yml`](auto-backup-wiki.yml) | 校验 Wiki 目录页和页面完整性后，事务式备份到仓库的 `wiki/` 目录并处理链接替换 | 每 2 小时或手动触发 |
| [`auto-generate-rules.yml`](auto-generate-rules.yml) | 从 `.list` 规则源统一生成 `.yaml` 和 `.mrs` 派生规则，复制标准模板以同步 Mainland 兼容文件，并调用统一 CDN 发布器 | 对应规则源、标准模板或生成器变更，源更新工作流同步调用，或手动触发 |
| [`auto-update-encrypted-dns.yml`](auto-update-encrypted-dns.yml) | 从 HaGeZi、DNSCrypt 和编译后的 `geosite:category-doh` 自动更新 `Encrypted_DNS.list`；内容变化后同步等待派生规则生成，派生失败会使本工作流失败 | 每日或手动触发 |
| [`auto-update-game-cdn.yml`](auto-update-game-cdn.yml) | 合并 v2fly 上游与本项目 `Steam_CDN.list`，智能去重后更新 `Game_Download_CDN.list`；内容变化后同步等待派生规则生成 | `Steam_CDN.list` 或生成器变更、每日或手动触发 |
| [`dependabot-auto-merge.yml`](dependabot-auto-merge.yml) | 核对机器人身份、签名提交、依赖文件范围和当前 SHA 后，直接以 squash 合并本仓库的 Dependabot PR | PR 创建或更新、每小时补处理，或手动触发 |
| [`pages.yml`](pages.yml) | 构建并部署 MkDocs 文档站点到 GitHub Pages | `wiki/**`、`mkdocs.yml` 变更或手动触发 |
| [`purge-jsdelivr.yml`](purge-jsdelivr.yml) | 按 [公开发布契约](../jsdelivr-publish.json) 精确刷新 jsDelivr 缓存；生成内容完整且仍为最新 `main` 时，同步部署 Cloudflare Static Assets 热备快照 | `main` 分支推送、规则生成完成，或手动修复范围 |
| [`sync-openclash-overwrite-submodule.yml`](sync-openclash-overwrite-submodule.yml) | 将 `overwrite/OpenClash_Overwrite` 子模块同步到上游 `main` 分支 | 每 2 小时或手动触发 |

工作流负责内容更新、生成、备份、发布和 Dependabot 自动合并。功能由维护者人工测试；Dependabot 依赖更新自动合并，不限制更新级别，也不等待测试、CodeQL、依赖审查或人工批准。

自动合并流程只读取 GitHub 元数据，不检出或执行 PR 中的代码。合并使用现有 Repository Secret `GH_PAT`，使合并后的 `main` 推送继续触发正常发布工作流；存在冲突或提交变化时，每小时自动补处理。

## jsDelivr 链接与缓存刷新

本项目的 jsDelivr 链接统一使用短分支名，例如 `https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/cfg/Custom_Clash.ini`。发布契约只刷新 `main` 缓存键。Git 完整引用路径仍用于 Git 命令和 GitHub Raw 地址，不用于 jsDelivr 的版本字段。

jsDelivr 的[分支缓存时间为 12 小时](https://github.com/jsdelivr/jsdelivr#caching)，清缓存接口不保证分支文件立即更新。工作流成功表示刷新请求已完成；确认新版是否生效时，仍需将公开文件内容与发布提交比较。需要立即取得指定版本时，使用包含完整提交 SHA 的 GitHub Raw 或 jsDelivr 地址。

## Cloudflare 热备发布

`purge-jsdelivr.yml` 是 jsDelivr 与 Cloudflare 热备的统一发布边界。发布器只从指定 Git 提交读取公开文件，不复制工作区内容。涉及规则来源或生成器的提交必须先完成 YAML、MRS 和 Mainland 兼容文件生成；未完成时，发布器跳过整份 Static Assets 快照，等待生成工作流携带最终提交再次调用。

Cloudflare 部署使用加密的 GitHub Secret。直接发布使用 Environment `cloudflare-production`；自动更新器经过多层可复用工作流时，通过同名 Repository Secret 和显式 `secrets: inherit` 逐层传递。仓库文件不保存 Cloudflare 账号 ID、区域 ID、部署令牌或运行时重定向令牌。发布任务通过 `--secrets-file` 将区域 ID 和运行时令牌写入 Cloudflare Worker Secret；运行时令牌限制为 `asailor.org` 的 Single Redirects 权限，并与部署令牌分离。
