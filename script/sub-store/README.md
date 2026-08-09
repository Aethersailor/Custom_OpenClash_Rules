# Sub-Store IPv6 出站节点过滤器

[`sub-store-ipv6-egress-filter.js`](sub-store-ipv6-egress-filter.js) 是供 [Sub-Store](https://github.com/sub-store-org/Sub-Store) HTTP-META 操作使用的脚本。脚本会让每个节点实际访问仅支持 IPv6 的测试地址。IPv6 探测失败时，再访问仅支持 IPv4 的地址进行对照，从而区分「确认不支持 IPv6 出站」和「当前无法确认」。

脚本检查的是**代理节点的 IPv6 出站能力**，与订阅节点服务器的入口地址是 IPv4、IPv6 还是域名无关。

## 前置条件

- Sub-Store 运行环境支持脚本操作、`$substore`、`ProxyUtils` 和 `scriptResourceCache`。
- 已启用并可访问 HTTP-META 服务；默认地址为 `http://127.0.0.1:9876`。
- HTTP-META 能为待测节点启动临时 Mihomo 实例。含 `dialer-proxy` 的节点无法安全转换，会被标记为不兼容并跳过测试。
- 运行环境必须可访问所配置的 IPv6 测试地址和 IPv4 对照地址。

## 导入与基本用法

在 Sub-Store 中新建脚本操作，将脚本内容粘贴到操作中，或从下列 GitHub Raw 地址导入，然后将该操作应用到目标订阅：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/script/sub-store/sub-store-ipv6-egress-filter.js
```

默认行为是仅保留已确认具备 IPv6 出站能力的节点。首次使用时，建议先以 `filter=false&mark=true` 观察分类结果，再决定是否启用过滤。

```text
filter=false&mark=true
```

## 探测与缓存逻辑

1. 将兼容的节点交给 HTTP-META 启动临时 Mihomo。
2. 每个节点访问 `test_url`。返回状态码等于 `expected_status`（默认值为 `204`）时，将节点标记为 `supported`。
3. IPv6 探测失败后，访问仅支持 IPv4 的 `control_url`。IPv4 对照成功时，将节点标记为 `unsupported`；对照也失败或时间预算耗尽时，将节点标记为 `unknown`。
4. `supported` 默认缓存 12 小时，`unsupported` 默认缓存 1 小时，`unknown` 不缓存。
5. 脚本停止前会请求 HTTP-META 回收临时 Mihomo；HTTP-META 还会根据自身的超时设置执行最终回收。

## 参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `http_meta_protocol` | `http` | HTTP-META 协议。 |
| `http_meta_host` / `http_meta_port` | `127.0.0.1` / `9876` | HTTP-META 地址与端口。 |
| `http_meta_authorization` | 空 | HTTP-META 的 `Authorization` 请求头值。 |
| `http_meta_start_delay` | `1500` | HTTP-META 启动后等待 Mihomo 就绪的毫秒数。 |
| `timeout` | `3000` | 单次 IPv4 或 IPv6 探测的超时（毫秒）。 |
| `concurrency` | `10` | 并发探测节点数。 |
| `max_duration` | `45000` | 脚本总执行时间预算（毫秒）；取值限制为 10000–48000。 |
| `stop_reserve` | `2500` | 为回收 HTTP-META 预留的时间（毫秒）。 |
| `cache` | `true` | 是否读取和写入分类缓存。 |
| `positive_cache_ttl` | `43200000` | `supported` 缓存时长（毫秒）。 |
| `negative_cache_ttl` | `3600000` | `unsupported` 缓存时长（毫秒）。 |
| `filter` | `true` | 为 `true` 时仅输出 `supported` 节点。 |
| `mark` | `false` | 是否为输出节点添加分类前缀。仅在 `filter=false` 时可同时看到三类结果。 |
| `mark_ipv6` | `[IPv6]` 后接一个空格 | `supported` 节点名前缀；兼容旧参数 `mark_text`。 |
| `mark_ipv4` | `[IPv4]` 后接一个空格 | `unsupported` 节点名前缀。 |
| `mark_unknown` | `[Unknown]` 后接一个空格 | `unknown` 节点名前缀。 |
| `include_unsupported_proxy` | `false` | 传给 `ProxyUtils.produce` 的 `include-unsupported-proxy` 选项。 |
| `test_url` / `expected_status` | `https://ipv6.google.com/generate_204` / `204` | 仅支持 IPv6 的出站测试地址与预期状态码。 |
| `control_url` / `control_expected_status` | `https://api4.ipify.org?format=json` / `200` | 仅支持 IPv4 的对照地址与预期状态码；响应还必须包含合法的 IPv4 `ip` 字段。 |

参数值会由 Sub-Store 作为脚本参数传入。自定义 URL 或标记含有保留字符时，请进行 URL 编码。

## 输出与限制

- `filter=true` 时，`unsupported`、`unknown` 和无法转换的节点都不会输出；这不等同于断言它们一定没有 IPv6 出站。
- `filter=false&mark=true` 时，节点会加上 `[IPv6]`、`[IPv4]` 或 `[Unknown]` 前缀；每个前缀末尾均包含一个空格。重复运行会先去除已知前缀，因此不会持续叠加。
- 测试结果依赖测试站点、网络路径和当时的时间预算。网络异常、HTTP-META 启动失败或总预算耗尽会使节点保留为 `unknown`。
- 不要将此脚本用作通用连通性、延迟或节点质量测试工具。此脚本仅用于判断 IPv6 出站能力。
