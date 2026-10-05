# dnsmasq 广告拦截与 hosts 覆写模块

本目录为 OpenClash 提供 dnsmasq 广告拦截模块、自定义 hosts 模块和 GitHub520 域名映射模块。各模块通过一个共享的本地组件下载、校验和合并规则，再交给 dnsmasq 加载。

**首次使用时，先按照 [`local/` 的安装说明](local/README.md) 安装共享组件，再订阅需要的模块。** 单独订阅 `.conf` 文件不会下载或加载规则。模块中只有规则源声明和 DNS 转发设置，不会下载并执行远程脚本。

## 选择模块

| 模块 | 规则格式与作用 | 参数 | 规则来源 |
| --- | --- | --- | --- |
| [`Custom_Hosts.conf`](Custom_Hosts.conf) | 加载自选 hosts 文件；支持屏蔽地址与真实 IP 映射 | `EN_KEY1=hosts 文件的 HTTPS 地址` | 自行提供 |
| [`GitHub520_Hosts.conf`](GitHub520_Hosts.conf) | 附加 GitHub520 的 GitHub 域名映射 | 无 | [GitHub520](https://github.com/521xueweihan/GitHub520)，[hosts 地址](https://raw.hellogithub.com/hosts) |
| [`Anti_AD_Dnsmasq.conf`](Anti_AD_Dnsmasq.conf) | 加载 anti-AD 的 dnsmasq 域名屏蔽规则 | 无 | [anti-AD 规则地址](https://anti-ad.net/anti-ad-for-dnsmasq.conf) |
| [`Adblockfilters_Hosts.conf`](Adblockfilters_Hosts.conf) | 加载 adblockfilters 的 hosts 屏蔽规则 | 无 | [hosts 规则地址](https://gcore.jsdelivr.net/gh/217heidai/adblockfilters@main/rules/adblockhosts.txt) |
| [`Adblockfilters_Dnsmasq.conf`](Adblockfilters_Dnsmasq.conf) | 加载 adblockfilters 的 dnsmasq 域名屏蔽规则 | 无 | [dnsmasq 规则地址](https://gcore.jsdelivr.net/gh/217heidai/adblockfilters@main/rules/adblockdnsmasq.txt) |

只需广告拦截时，先选择 anti-AD 或 adblockfilters 的一个版本。dnsmasq 格式会覆盖规则域名及其子域名，hosts 格式只匹配列出的域名。多个广告列表的重复部分不会增加拦截效果，但会增加下载、处理和内存开销。

GitHub520 提供真实 IP 映射，**不是广告拦截规则，也不是代理节点或连通性保证**。只在需要时启用。

## 订阅地址

每个模块选择 CDN 或 GitHub Raw 地址之一即可。以下地址用于 OpenClash 的「Subscribe」模块订阅，不是节点订阅地址。

| 模块 | jsDelivr CDN | GitHub Raw |
| --- | --- | --- |
| 自定义 hosts | [CDN](https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/adblock/Custom_Hosts.conf) | [Raw](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/adblock/Custom_Hosts.conf) |
| GitHub520 | [CDN](https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/adblock/GitHub520_Hosts.conf) | [Raw](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/adblock/GitHub520_Hosts.conf) |
| anti-AD | [CDN](https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/adblock/Anti_AD_Dnsmasq.conf) | [Raw](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/adblock/Anti_AD_Dnsmasq.conf) |
| adblockfilters hosts | [CDN](https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/adblock/Adblockfilters_Hosts.conf) | [Raw](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/adblock/Adblockfilters_Hosts.conf) |
| adblockfilters dnsmasq | [CDN](https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/adblock/Adblockfilters_Dnsmasq.conf) | [Raw](https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/adblock/Adblockfilters_Dnsmasq.conf) |

## 使用步骤

1. [安装共享组件](local/README.md#安装共享组件)。OpenClash 和 dnsmasq 必须已经安装并运行。
2. 打开 OpenClash 的「覆写模块」编辑器，选择「+」→「Subscribe」，填写上表中的一个订阅地址。
3. 将匹配配置设置为 `all` 或需要使用的配置文件。空匹配不会启用规则。
4. 使用自定义 hosts 模块时，在参数栏填写 `EN_KEY1=https://example.com/hosts.txt`。地址必须直接返回 hosts 文本；含有分号或空白的地址需要先进行 URL 编码。
5. 启用模块并保存，然后重启 OpenClash 一次，使 `Dnsmasq Redirect` 生效。
6. 在路由器 SSH 中执行下列命令，立即下载并应用规则。未手动执行时，共享组件会在下一次定时检查时处理，通常不超过 5 分钟。

```sh
ruby /etc/openclash/custom/dnsmasq_rules.rb update
ruby /etc/openclash/custom/dnsmasq_rules.rb status
```

状态中的 `active` 是最近一次应用时启用且匹配配置的规则源，`loaded` 是实际参与已应用规则的来源；`sources` 中的 `checked` 是成功校验时间，`counts` 是已经应用的规则统计。首次下载失败的规则源不会进入 `loaded`；有相同 URL 的有效缓存时，下载失败会继续使用缓存。

所有模块都使用同一个 DNS 模式：`ENABLE_REDIRECT_DNS=1`，即 `Dnsmasq Redirect`。正常路径为「终端 → dnsmasq → Mihomo DNS」。其他覆写模块如果将 DNS 模式改为 `Firewall Redirect`，组件会拒绝应用并写入日志；需要先解决 DNS 模式冲突。通过 DoH、DoT、其他 DNS 服务器或纯 IP 连接绕过 dnsmasq 的流量，不受这些规则控制。

## 同时启用时的处理规则

五个模块可以组合使用，共享组件统一处理数据，不依赖 OpenClash 模块的排列顺序。

| 情况 | 处理结果 |
| --- | --- |
| 多个 dnsmasq 广告源出现同一个域名 | 合并为一条规则；上级域名已覆盖的子域名规则不再重复写入 |
| adblockfilters 两种格式同时启用 | 合并重复项；dnsmasq 的子域名屏蔽范围保留 |
| hosts 映射的域名命中 dnsmasq 广告规则或其子域名范围 | 不写入该 hosts 映射，保留域名屏蔽 |
| 同一个 hosts 域名同时出现屏蔽地址和真实 IP | 屏蔽优先，不混合返回屏蔽地址与真实 IP |
| 自定义 hosts 与 GitHub520 为同一个域名提供不同真实 IP | 使用自定义 hosts，忽略 GitHub520 的映射 |
| 同一个域名在同一优先级来源中有多个真实 IP | 每个地址族只保留一个，按地址文本排序选择；不是负载均衡配置 |
| 重复订阅同一模块且规则地址相同 | 只下载、加载一次 |
| 同一类模块的多个副本填写不同规则地址 | 拒绝本次应用，先停用多余副本或统一地址 |

自定义 hosts 中的 `0.0.0.0`、`127.0.0.1` 和 IPv6 屏蔽地址作为精确域名屏蔽处理，最终为该域名写入 IPv4、IPv6 空地址。localhost 等系统条目以及 `.localhost`、`.local` 域名不会导入，避免替换本地名称解析。

只保证本目录模块之间按上表合并。路由器原有 `/etc/hosts`、DHCP 主机名、其他插件的广告规则和自定义 dnsmasq 设置仍由原来的来源控制；本组件不会删除或改写它们。已有本地 hosts 或 DHCP 记录也可能影响实际回答，不能把模块组合测试理解为所有固件、插件和网络环境都无冲突。

## 更新、停用与卸载

- 共享组件每 5 分钟检查启用状态，每 8 小时检查远程规则。失败后至少间隔 10 分钟再尝试；`update` 命令可以立即重试。
- 只有 hosts 内容变化时，组件对目标 dnsmasq 发送 `SIGHUP`，不重启 OpenClash 或 dnsmasq。
- dnsmasq 格式规则变化、首次加入加载配置或移除加载配置时，需要重启目标 dnsmasq 实例，会短暂影响该实例提供的 DNS/DHCP 服务。内容未变化时不重载。
- 停用模块、切换到不匹配的配置或禁用 OpenClash 后，定时检查会移除相应规则。需要立即生效时，保存设置后执行 `ruby /etc/openclash/custom/dnsmasq_rules.rb apply`。
- 修改规则 URL 后，只有新 URL 下载且校验成功的数据才会加载；新 URL 不会借用旧 URL 的缓存。
- 完全卸载共享组件的方法见 [`local/` 的卸载说明](local/README.md#卸载共享组件)。仅删除 `.conf` 订阅或本地脚本，不能代替卸载步骤。

有效缓存保存在路由器闪存中，重启后可直接加载，避免离线启动时丢失规则。全部启用时，缓存和处理阶段会占用更多空间与内存；完整规则合并的内存峰值可能超过 100 MiB，设备还需为系统、OpenClash 和 dnsmasq 本身保留内存。资源较少的设备建议只选择一个广告源。单个远程文件最大为 32 MiB。

## 故障排查

先查看状态和日志：

```sh
ruby /etc/openclash/custom/dnsmasq_rules.rb status
logread -e openclash-dnsmasq-rules
```

| 现象 | 检查与处理 |
| --- | --- |
| 订阅成功但没有规则 | 确认已安装本地组件、模块已启用且匹配当前配置；执行 `update` 并查看日志 |
| 自定义 hosts 下载失败 | 确认地址为 HTTPS 且直接返回文本，没有登录页、HTML 页面或下载跳转到 HTTP |
| 规则格式校验失败 | 使用表格中对应的格式地址。组件会拒绝未知 dnsmasq 指令、通配符 hosts、非法 IP 和非法域名 |
| DNS 模式冲突 | 保留 `Dnsmasq Redirect`，停用修改该模式的冲突模块，然后重启 OpenClash |
| GitHub520 映射没有出现 | 检查同名自定义 hosts 和广告屏蔽规则；屏蔽优先于 GitHub520 |
| 停用后仍然拦截 | 执行 `apply`；清除终端 DNS 缓存，并检查是否还有其他广告源、插件或本地记录 |
| dnsmasq 应用失败 | 组件会尝试恢复此前配置；查看 dnsmasq 日志。其他 dnsmasq 配置本身有错误时，仍需先修复该错误 |

组件目前只处理 OpenClash 使用的第一个 dnsmasq 实例。使用多 dnsmasq 实例、旁路网关、AdGuard Home 或特殊 DNS 接管方案时，应先确认需要过滤的查询确实经过这个实例。

DNS 层拦截无法按网页路径区分同域名广告与正常内容，也不能替代浏览器内容过滤。规则来源、误杀与解除误杀方式应以各上游项目的说明为准。

返回 [覆写模块目录](../README.md)。
