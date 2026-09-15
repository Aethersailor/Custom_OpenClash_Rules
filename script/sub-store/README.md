# Sub-Store 扩展脚本

本目录提供可独立导入 Sub-Store 的订阅处理脚本。脚本不会被本项目的 OpenClash 配置自动加载。

| 脚本 | 用途 | 是否联网 |
| --- | --- | --- |
| [`sub-store-node-name-normalizer.js`](sub-store-node-name-normalizer.js) | 识别节点名称中的地区信息，统一名称、标签、倍率和序号 | 否 |
| [`sub-store-ipv6-egress-filter.js`](sub-store-ipv6-egress-filter.js) | 通过 HTTP-META 检查代理节点是否支持 IPv6 出站 | 是 |

## 节点名称规范化器

[`sub-store-node-name-normalizer.js`](sub-store-node-name-normalizer.js) 根据节点名称中的可靠地区证据生成统一名称。脚本不会查询节点 IP 或 GeoIP；名称中没有足够证据时，默认保留原名。

### 导入与基本用法

在 Sub-Store 中新建脚本操作，粘贴脚本内容，或从下列 GitHub Raw 地址导入：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/script/sub-store/sub-store-node-name-normalizer.js
```

默认输出简体中文地区名，保留已知线路标签和倍率。只有同名节点超过一个时才添加序号。未命中和存在冲突的节点保持原名。

以下参数输出「国旗 + 英文地区名」，并为全部已识别节点添加序号：

```text
format=en&with_flag=true&number=always
```

首次使用时，建议开启诊断并标记无法判断的节点：

```text
unmatched=mark&ambiguous=mark&debug=true
```

### 匹配规则

脚本按以下证据识别地区：

1. `overrides` 提供的精确名称映射。
2. 国旗。
3. 完整中文或英文地区名。
4. 本项目维护的常见城市、机场代码和地区别名。
5. 具有完整边界的 ISO alpha-2 或 alpha-3 代码。

两字母或三字母代码默认区分大小写。代码前不能是英文字母或数字，代码后不能是英文字母。因此：

- `HK01`、`HK-01` 和 `HKG-01` 可以识别为香港。
- `VLESS` 中的 `ES`、`REALITY` 中的 `AL` 和 `RFCHost` 中的 `CH` 不会命中。
- `100GB` 中的 `GB` 不会识别为英国。

脚本会收集全部地区证据，不按词表顺序选择第一个结果。多个证据指向同一地区时正常命中；不同证据指向多个地区时，结果为 `ambiguous`。

较长的完整名称优先覆盖名称内部的短名称。例如，`Hong Kong SAR China` 识别为香港，不会同时识别为中国；`American Samoa` 识别为美属萨摩亚，不会同时识别为萨摩亚。

### 地区数据

脚本内置 249 个 [ISO 3166-1](https://www.iso.org/iso-3166-country-codes.html) alpha-2/alpha-3 地区条目。简体中文和英文显示名根据 [Unicode CLDR 48.2.0](https://github.com/unicode-org/cldr-json/tree/1aaabe99aa652d6f22ea488cf25baea46aa69b42) 整理。常见繁体中文名称、城市、机场代码和线路别名由本项目单独维护。CLDR 派生数据的 Unicode License v3 声明已包含在脚本中。

国旗由 alpha-2 代码计算，不维护单独的平行映射表。脚本是单文件资源，运行时不会下载地区数据。

### 参数

| 参数 | 默认值 | 说明 |
| --- | --- | --- |
| `format` | `zh` | 地区输出格式：`zh`、`en`、`code` 或 `flag`。 |
| `with_flag` | `false` | 在非 `flag` 格式的地区名前添加国旗。 |
| `prefix` | 空 | 为已识别节点添加固定前缀。 |
| `prefix_position` | `before` | 前缀位置：`before` 或 `after`。 |
| `separator` | 一个空格 | 前缀、国旗、地区、标签和倍率之间的分隔符。 |
| `number_separator` | 一个空格 | 名称与序号之间的分隔符。 |
| `number` | `duplicates` | 编号方式：`duplicates` 仅为同名节点编号，`always` 为全部已识别节点编号，`off` 不编号。 |
| `number_width` | `2` | 序号最小位数，取值限制为 1–6。 |
| `unmatched` | `keep` | 未命中节点的处理方式：`keep`、`mark` 或 `drop`。 |
| `ambiguous` | `keep` | 地区证据冲突节点的处理方式：`keep`、`mark` 或 `drop`。 |
| `unmatched_mark` | `[Unmatched] ` | `unmatched=mark` 使用的前缀。 |
| `ambiguous_mark` | `[Ambiguous] ` | `ambiguous=mark` 使用的前缀。 |
| `retain_known` | `true` | 保留并规范化脚本内置的线路和服务标签。 |
| `retain_rate` | `true` | 保留倍率，并统一为 `数字×` 格式。 |
| `retain` | 空 | 额外保留的文字，多个值使用英文逗号分隔。 |
| `tag_map` | 空 JSON 对象 | 标签重命名 JSON，键为内置规范标签或 `retain` 项，值为输出标签。 |
| `rate` | `all` | 倍率过滤：`all`、`normal` 或 `high`；`high` 指倍率大于 1。 |
| `drop_info` | `false` | 删除套餐、流量、到期、官网、客服等通知节点。 |
| `sort` | `none` | 排序方式：`none`、`region` 或 `tag`。默认保留输入顺序。 |
| `block_quic` | `preserve` | `block-quic` 属性处理方式：`preserve`、`on` 或 `off`。 |
| `overrides` | 空 JSON 对象 | 原节点名到 ISO alpha-2 代码的精确映射。 |
| `code_case` | `strict` | 短代码匹配方式：`strict` 区分大小写，`ignore` 忽略大小写。 |
| `allow_ambiguous_codes` | `false` | 是否允许容易与协议、产品、平台或机场代码冲突的短代码参与匹配。 |
| `debug` | `false` | 输出未命中、冲突候选和处理数量摘要。 |

参数值由 Sub-Store 传入。JSON、空格、自定义标记或其他保留字符应当进行 URL 编码。

### 标签与倍率

`retain_known=true` 默认识别以下类别：

- `IPLC`、`IEPL`、`BGP`、`CN2` 和 `CMI`；
- `Core`、`Edge`、`Pro`、`Standard` 和 `Experimental`；
- `Business`、`Residential`、`Game`、`Shopping`、`Dedicated` 和 `LoadBalance`；
- `Cloudflare`、`UDP`、`UDPN`、`GPT`、`Netflix`、`Disney+`、`YouTube` 和 `TikTok`。

标签按照原节点名中的出现顺序输出并自动去重。例如：

```text
Hong Kong GPT IPLC 2.5x
```

默认输出：

```text
香港 GPT IPLC 2.5×
```

使用 `tag_map` 可以修改标签：

```text
tag_map=%7B%22GPT%22%3A%22AI%22%7D
```

### 精确覆盖与短代码冲突

`overrides` 只进行完整节点名匹配。映射目标必须是有效的 ISO alpha-2 代码。例如，将无法自行识别的节点明确指定为美国：

```text
overrides=%7B%22RFCHost-Mihomo-VLESS-REALITY%22%3A%22US%22%7D
```

部分短代码同时具有常见的非地区含义，默认不参与识别。例如：

- `NF` 可能表示 Netflix；
- `CF` 可能表示 Cloudflare；
- `LB` 可能表示负载均衡；
- `TR` 可能表示 Trojan；
- `WS` 可能表示 WebSocket；
- `TLS`、`MAC` 可能表示协议或平台；
- `HND`、`FRA`、`PER`、`CAN` 等可能同时表示机场或国家 alpha-3 代码。

优先使用完整地区名、国旗、无冲突代码或 `overrides`。只有明确接受这些歧义时，才启用 `allow_ambiguous_codes=true`。

### 输出与限制

- 脚本只根据节点名称判断地区。节点名称没有地区信息时，无法推断节点的真实位置。
- `unmatched=drop` 和 `ambiguous=drop` 会删除节点。首次使用时不要直接启用这两个参数。
- `drop_info=true` 使用固定通知关键词过滤节点，默认关闭。
- `rate=normal` 保留无倍率或倍率不大于 1 的节点；`rate=high` 只保留倍率大于 1 的节点。
- 默认不排序。启用排序后，已识别节点排在未命中或冲突节点之前。
- 规范化和编号不会改变输入数组顺序，除非显式设置 `sort=region` 或 `sort=tag`。
- 脚本默认只修改已识别节点的 `name`。只有显式设置 `block_quic=on` 或 `block_quic=off` 时才修改 `block-quic`。
- 相同参数重复执行时不会持续叠加状态标记、标签、倍率或序号。

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
