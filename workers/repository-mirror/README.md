# Custom_OpenClash_Rules 仓库镜像

此 Worker 为 `Aethersailor/Custom_OpenClash_Rules` 的 `main` 分支提供静态备用文件。正常状态下，Cloudflare Single Redirect Rules 将项目首页转到 GitHub，并将文件请求转到 jsDelivr。自动监控确认异常达到阈值后，系统停用两条跳转规则，Workers Static Assets 随后直接返回部署时生成的仓库快照。

实现不使用 R2 或 Workers KV。SQLite Durable Object 只保存监控状态和连续计数。

## 固定范围

- 仓库：`Aethersailor/Custom_OpenClash_Rules`
- 分支：`main`
- 文件前缀：`/Custom_OpenClash_Rules/main/`
- 校验文件：`rule/Custom_Direct.list`
- 状态接口：`GET /__mirror/status`
- 定时任务：每小时执行一次

备用快照包含根目录的 `README.md`、`LICENCE`，以及 `cfg/`（含 `cfg/yaml/`）、`icon/`、`overwrite/`、`rule/`、`script/`、`shell/`、`wiki/` 中的全部普通文件。各目录的 README 和 archived 内容也会保留。维护脚本目录 `.github/`、`py/` 以及只保存指针的第三方 Git 子模块不属于访客发布面。

Wrangler 只注册以下路由，不接管 `git.asailor.org` 根路径或其他现有内容：

```text
git.asailor.org/Custom_OpenClash_Rules
git.asailor.org/Custom_OpenClash_Rules/*
git.asailor.org/_mirror/*
git.asailor.org/__mirror/*
```

Static Assets 采用 assets-first。存在的备用文件不执行 Worker 脚本；未找到静态文件时，除 `GET /__mirror/status` 和 `HEAD /__mirror/status` 外均返回 `404`。

## 跳转规则前置条件

Dynamic Redirect 入口规则集中必须且只能各有一条以下稳定 `ref`：

- `cor_main_page`：项目首页跳转到 jsDelivr 的 `Aethersailor/Custom_OpenClash_Rules@main` 仓库目录
- `cor_main_files`：文件路径跳转到 jsDelivr 的 `Aethersailor/Custom_OpenClash_Rules@main` 对应仓库内路径

两条规则使用 `302`。文件规则不得匹配 `/Custom_OpenClash_Rules/main/` 首页本身。

Worker 只修改这两条规则的 `enabled` 字段。Cloudflare 没有事务型的多规则 `PATCH` 接口，因此实现不会用 `PUT` 覆盖整个入口规则集。系统按稳定 `ref` 逐条提交完整可写定义，随后重新读取规则集。部分提交失败时，系统尝试恢复两条规则的原始定义，并且不会将本次切换记为成功。两次 API 请求之间仍可能短暂出现规则状态不一致。

`CF_REDIRECT_API_TOKEN` 只需授予 `asailor.org` 区域的 Dynamic URL Redirects Write 权限。不要使用全局 API Key。

## 健康判断

每轮同时检查以下内容：

1. GitHub `main` 提交 API 可以访问，并记录当前提交 SHA。
2. GitHub 仓库分支页面可以访问，且没有跳转到其他仓库路径。
3. GitHub Raw 校验文件可以访问，并计算 SHA-256。
4. jsDelivr `@main` 校验文件可以访问，并计算 SHA-256。
5. Static Assets binding 中的快照清单、部署变量和备用校验文件身份一致。

GitHub 仓库页面和 Raw 文件均可访问时，本轮记为成功，并保持项目首页和文件路径到 jsDelivr 的跳转。GitHub API `200` 可补充提交 SHA；Cloudflare 共享出口遇到 API `403` 或 `429` 时，只要公开页面和 Raw 仍可访问，就不阻断恢复。jsDelivr 的响应状态和内容哈希只用于观测，不参与切换；备用模式只处理 GitHub 仓库访问不可用。

满足以下任一条件时，本轮记为失败：

- 至少两项 GitHub 检查明确返回 `404`、`410` 或 `451`，并且备用快照完整可用。
- GitHub 的仓库 API、仓库页面和 Raw 文件中至少两项明确不可用，而且备用快照完整可用。

其他情况记为未知。`403`、`429`、请求超时、`5xx`、备用快照落后以及证据不足均不会触发切换。未知状态会清空连续计数。连续 2 次失败后停用跳转规则，连续 2 次成功后重新启用，因此正常情况下最多约 2 小时完成切换或恢复。

## 构建与部署

仓库统一发布器从指定 Git 提交的 blob 生成 `dist/`，并执行公开文件契约、生成顺序、文件数量和单文件大小检查。Node.js 脚本只验证已有 `dist/` 与清单完全一致，不建立第二套资产选择规则。

正式发布由 `.github/workflows/purge-jsdelivr.yml` 执行。直接发布从 GitHub Environment `cloudflare-production` 读取 Secret；自动更新器的嵌套可复用工作流使用同名 Repository Secret，并显式逐层继承：

- `CLOUDFLARE_API_TOKEN`：只授予 Worker 脚本写入和 `asailor.org` Worker Route 写入权限；
- `CLOUDFLARE_ACCOUNT_ID`：Cloudflare 账号 ID；
- `CLOUDFLARE_ZONE_ID`：`asailor.org` 区域 ID；
- `CF_REDIRECT_API_TOKEN`：只授予 `asailor.org` Dynamic URL Redirects Write 权限。

发布任务通过 Wrangler `--secrets-file` 将后两项保存为 Worker Secret。密钥值不会写入仓库文件或构建日志。

本地只读验证不需要 Cloudflare 凭据：

```powershell
$revision = git rev-parse HEAD
py -3 ..\..\.github\scripts\jsdelivr_purge.py build-worker-assets `
  --revision $revision `
  --output dist
npm ci
npm run check
npx wrangler deploy --dry-run
```

从 `workers/repository-mirror` 目录运行以上命令。`dist/` 不提交到 Git；每次部署前必须重新生成。正式流程只部署已经通过精确 SHA 校验、仍为最新 `main` 的完整快照。

部署后检查：

```powershell
curl.exe -fsS https://git.asailor.org/__mirror/status
curl.exe -I https://git.asailor.org/Custom_OpenClash_Rules/main/
curl.exe -I https://git.asailor.org/Custom_OpenClash_Rules/main/rule/Custom_Direct.list
```

状态接口只返回公开的仓库修订、探测结果、连续计数和跳转模式，不返回 Cloudflare Zone ID、API Token 或规则 ID。

定时检查从 Cloudflare 网络执行。检查结果只能表示 Cloudflare 到 GitHub 和 jsDelivr 的访问状态，不能代表每个地区或运营商中的终端访问状态。
