# Sub-Store 扩展脚本

本目录提供可独立导入 Sub-Store 的订阅处理脚本。脚本不会被本项目的 OpenClash 配置自动加载。

| 脚本 | 用途 | 是否联网 |
| --- | --- | --- |
| [`sub-store-node-name-normalizer.js`](sub-store-node-name-normalizer.js) | 识别节点名称中的地区信息，并统一为中文地区名和序号 | 否 |
| [`sub-store-ipv6-egress-filter.js`](sub-store-ipv6-egress-filter.js) | 通过 HTTP-META 检查代理节点是否支持 IPv6 出站 | 是 |

## 节点名称规范化器

[`sub-store-node-name-normalizer.js`](sub-store-node-name-normalizer.js) 根据节点名称中的可靠地区证据生成统一名称。脚本不会查询节点 IP 或 GeoIP，也不会删除任何节点。名称中没有足够证据或证据相互冲突时，节点保持原名。

### 导入与基本用法

在 Sub-Store 中新建脚本操作，粘贴脚本内容，或从下列 GitHub Raw 地址导入：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/script/sub-store/sub-store-node-name-normalizer.js#noCache
```

识别成功的节点默认只输出简体中文地区名和序号。脚本保持全部节点及其原始顺序；未命中或存在同级文字冲突的节点均保留原名。

如果脚本操作中已经保存过旧版本，先在前端刷新脚本资源，或使用上方带 `#noCache` 的地址重新导入并保存。分享订阅地址上的 `noCache=true` 只影响订阅来源缓存，不能替换已经保存在脚本操作中的内容。

### 匹配规则

脚本按以下证据识别地区：

1. 完整中文或英文地区名。
2. 本项目维护的常见城市和地区别名。
3. 具有完整边界的 ISO alpha-2、alpha-3 或机场代码。
4. 国旗 Emoji。

两字母或三字母代码区分大小写。代码前不能是英文字母或数字，代码后不能是英文字母。因此：

- `HK01`、`HK-01` 和 `HKG-01` 可以识别为香港。
- `VLESS` 中的 `ES`、`REALITY` 中的 `AL` 和 `RFCHost` 中的 `CH` 不会命中。
- `100GB` 中的 `GB` 不会识别为英国。

脚本会收集全部地区证据，不按词表顺序选择第一个结果。完整中文或英文地区名和明确城市别名优先级最高，独立 alpha-2/alpha-3 代码其次，国旗 Emoji 最低。因此，`CN台湾`、`🇨🇳台湾`、`CN Taiwan` 和 `🇨🇳 TW` 都按台湾处理。两个同级文字地区名指向不同地区时，结果为 `ambiguous`。

较长的完整名称优先覆盖名称内部的短名称。例如，`Hong Kong SAR China` 识别为香港，不会同时识别为中国；`American Samoa` 识别为美属萨摩亚，不会同时识别为萨摩亚。

### 地区数据

脚本内置 249 个 [ISO 3166-1](https://www.iso.org/iso-3166-country-codes.html) alpha-2/alpha-3 地区条目。简体中文和英文显示名根据 [Unicode CLDR 48.2.0](https://github.com/unicode-org/cldr-json/tree/1aaabe99aa652d6f22ea488cf25baea46aa69b42) 整理。常见繁体中文名称、城市和机场代码由本项目单独维护。CLDR 派生数据的 Unicode License v3 声明已包含在脚本中。

国旗由 alpha-2 代码计算，不维护单独的平行映射表。脚本是单文件资源，运行时不会下载地区数据。

### 短代码冲突

部分短代码同时具有常见的非地区含义，默认不参与识别。例如：

- `NF` 可能表示 Netflix；
- `CF` 可能表示 Cloudflare；
- `LB` 可能表示负载均衡；
- `TR` 可能表示 Trojan；
- `WS` 可能表示 WebSocket；
- `TLS`、`MAC` 可能表示协议或平台；
- `HND`、`FRA`、`PER`、`CAN` 等可能同时表示机场或国家 alpha-3 代码。

这类名称只有在同时出现可靠文字地区名时才会重命名，否则保持原名。

### 输出与限制

- 脚本只根据节点名称判断地区。节点名称没有地区信息时，无法推断节点的真实位置。
- 输入和输出节点数量始终相同。无法识别地区或存在同级地区冲突时，节点保持原名。
- 脚本保持输入顺序，只对已识别节点按地区分别连续编号。
- 脚本只修改节点的 `name`，不会修改其他节点属性。
- 已识别节点固定输出为 `中文地区名 + 空格 + 两位起始序号`。节点数量超过 99 时，序号自动扩展位数。
- 相同输入重复执行时不会持续叠加编号。

## IPv6 出站节点过滤器

[`sub-store-ipv6-egress-filter.js`](sub-store-ipv6-egress-filter.js) 是供 [Sub-Store](https://github.com/sub-store-org/Sub-Store) HTTP-META 操作使用的脚本。脚本会让每个节点实际访问仅支持 IPv6 的测试地址。IPv6 探测失败时，再访问仅支持 IPv4 的地址进行对照，从而区分「确认不支持 IPv6 出站」和「当前无法确认」。

脚本检查的是**代理节点的 IPv6 出站能力**，与订阅节点服务器的入口地址是 IPv4、IPv6 还是域名无关。

### 前置条件

- Sub-Store 运行环境支持脚本操作、`$substore`、`ProxyUtils` 和 `scriptResourceCache`。
- 已启用并可访问 HTTP-META 服务；默认地址为 `http://127.0.0.1:9876`。
- HTTP-META 能为待测节点启动临时 Mihomo 实例。含 `dialer-proxy` 的节点无法安全转换，会被标记为不兼容并跳过测试。
- 运行环境必须可访问所配置的 IPv6 测试地址和 IPv4 对照地址。

### 导入与基本用法

在 Sub-Store 中新建脚本操作，将脚本内容粘贴到操作中，或从下列 GitHub Raw 地址导入，然后将该操作应用到目标订阅：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/script/sub-store/sub-store-ipv6-egress-filter.js
```

默认行为是仅保留已确认具备 IPv6 出站能力的节点。首次使用时，建议先以 `filter=false&mark=true` 观察分类结果，再决定是否启用过滤。

```text
filter=false&mark=true
```

### 探测与缓存逻辑

1. 将兼容的节点交给 HTTP-META 启动临时 Mihomo。
2. 每个节点访问 `test_url`。返回状态码等于 `expected_status`（默认值为 `204`）时，将节点标记为 `supported`。
3. IPv6 探测失败后，访问仅支持 IPv4 的 `control_url`。IPv4 对照成功时，将节点标记为 `unsupported`；对照也失败或时间预算耗尽时，将节点标记为 `unknown`。
4. `supported` 默认缓存 12 小时，`unsupported` 默认缓存 1 小时，`unknown` 不缓存。
5. 脚本停止前会请求 HTTP-META 回收临时 Mihomo；HTTP-META 还会根据自身的超时设置执行最终回收。

### 参数

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

### 输出与限制

- `filter=true` 时，`unsupported`、`unknown` 和无法转换的节点都不会输出；这不等同于断言它们一定没有 IPv6 出站。
- `filter=false&mark=true` 时，节点会加上 `[IPv6]`、`[IPv4]` 或 `[Unknown]` 前缀；每个前缀末尾均包含一个空格。重复运行会先去除已知前缀，因此不会持续叠加。
- 测试结果依赖测试站点、网络路径和当时的时间预算。网络异常、HTTP-META 启动失败或总预算耗尽会使节点保留为 `unknown`。
- 不要将此脚本用作通用连通性、延迟或节点质量测试工具。此脚本仅用于判断 IPv6 出站能力。
