# 广告拦截共享组件

[`dnsmasq_rules.rb`](dnsmasq_rules.rb) 是[上级目录 5 个模块](../README.md)共用的本地组件。首次安装一次即可，后续可以在 OpenClash 中选择、组合或停用模块。

组件负责下载与格式校验、保留有效缓存、合并冲突、加载 dnsmasq 和移除停用规则。它不常驻后台，不修改 `/etc/hosts` 或 DHCP 配置，不重启 OpenClash；定时检查通过路由器已有的 cron 执行。

## 安装前确认

1. 在路由器上安装并运行 OpenClash、dnsmasq。当前实现按 OpenClash 开发版 `v0.47.169` 的覆写模块和配置匹配方式编写。
2. 确认路由器可访问所选规则源。首次下载需要联网；后续离线启动可以读取相同 URL 的有效缓存。
3. 使用路由器 root SSH 终端操作。组件依赖 OpenClash 已使用的 Ruby、`ruby-yaml`、curl，以及 OpenWrt 的 UCI、sort、cron 和 logger。
4. 为规则缓存与处理保留空间和内存。每个来源最大 32 MiB；完整规则合并的内存峰值可能超过 100 MiB。建议先启用一个广告源，再根据需要添加其他模块。

已在 ImmortalWrt SNAPSHOT 的 x86/64 测试设备上验证，环境为 OpenClash `v0.47.169`、Ruby `4.0.2`、dnsmasq `2.93`，dnsmasq 通过 `ujail` 运行。验证包括完整远程规则加载，以及使用受控规则测试五个模块的 32 种组合、映射冲突、hosts 热重载、下载失败回退和停用、卸载清理。

首次加载 dnsmasq 配置、改变 dnsmasq 格式规则或移除加载配置时，需要重启目标 dnsmasq 实例，会短暂影响 DNS/DHCP。只有 hosts 变化时使用 `SIGHUP` 热重载。组件不接管其他插件的规则；已有本地记录和其他 DNS 服务仍需按实际查询路径核对。

## 安装共享组件

以下命令在路由器 SSH 终端中执行。下载地址属于本项目；远程规则只作为数据处理，不会作为脚本执行。

```sh
task_file="$(mktemp /tmp/openclash-dnsmasq-rules.XXXXXX)" &&
curl --fail --show-error --location \
  https://cdn.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@main/overwrite/adblock/local/dnsmasq_rules.rb \
  -o "$task_file" &&
ruby -c "$task_file" &&
cp "$task_file" /etc/openclash/custom/dnsmasq_rules.rb &&
chmod 700 /etc/openclash/custom/dnsmasq_rules.rb &&
ruby /etc/openclash/custom/dnsmasq_rules.rb install &&
rm -f "$task_file"
```

CDN 不可用时，将下载地址替换为：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/main/overwrite/adblock/local/dnsmasq_rules.rb
```

安装成功后，组件会：

- 在 OpenClash 已有的 `openclash_custom_overwrite.sh` 中加入带标记的调用，保留原有内容；调用位于原有脚本语句之前，避免被提前 `exit` 跳过。
- 在 root crontab 中加入一个每 5 分钟执行的检查任务，保留其他任务。OpenClash 的快速启动没有执行本地钩子时，定时检查仍会处理变化。
- 创建专用缓存和临时目录。重复执行 `install` 不会重复加入钩子或定时任务。

安装输出错误时不要继续启用模块。检查日志及输出，并清理本次命令留下的临时下载文件。安装后返回[上级目录](../README.md#使用步骤)，订阅模块、重启 OpenClash 一次并执行 `update`。

## 日常使用

```sh
# 查看已启用来源、已应用数量和校验时间；不会显示规则 URL 中的令牌。
ruby /etc/openclash/custom/dnsmasq_rules.rb status

# 立即检查全部启用来源并应用有效规则。
ruby /etc/openclash/custom/dnsmasq_rules.rb update

# 只应用已有有效缓存，或清理已停用模块的规则，不发起下载。
ruby /etc/openclash/custom/dnsmasq_rules.rb apply

# 查看下载、校验和应用日志。
logread -e openclash-dnsmasq-rules
```

`sync` 由定时任务调用，每 8 小时检查一次远程规则，失败后至少等待 10 分钟再尝试。校验通过后才替换来源缓存；下载错误、HTML 页面和不支持的规则指令不会替换有效缓存。生成的配置也会先执行 `dnsmasq --test`，服务应用失败时尝试恢复此前文件。

组件只接受标准 hosts 和域名屏蔽用途的 dnsmasq 规则。hosts 的域名必须使用 ASCII 或 Punycode，不支持通配符；dnsmasq 来源不允许插入其他配置文件、设置上游或执行脚本。缓存按来源分开，最终只写入一份合并后的配置和 hosts 文件。

## 保存位置

| 位置 | 内容 |
| --- | --- |
| `/etc/openclash/custom/dnsmasq_rules.rb` | 本地组件脚本 |
| `/etc/openclash/dnsmasq-rules/` | 校验后的来源缓存和状态，目录仅 root 可读写 |
| `/tmp/openclash-dnsmasq-rules/` | 运行锁和临时处理文件；每次操作结束清理暂存文件 |
| dnsmasq 当前配置目录中的 `90-openclash-dnsmasq-rules.conf` | 唯一的合并配置 |
| 同目录中的 `.openclash-dnsmasq-rules.hosts` | 合并 hosts；以点开头，避免被当作 dnsmasq 配置指令读取 |

不要手工修改最后两项生成文件。组件不会覆盖同名的其他文件或符号链接。固件升级、恢复备份或升级 OpenClash 后，应重新确认脚本、本地钩子和定时任务是否保留；缺失时重新安装。

## 卸载共享组件

1. 在 OpenClash 中停用本目录的全部模块并保存设置。
2. 执行下面的命令，移除组件钩子、专用定时任务及已生成规则。此步骤可能重启目标 dnsmasq 实例。

```sh
ruby /etc/openclash/custom/dnsmasq_rules.rb uninstall
```

3. 确认命令成功、原有 DNS 服务正常后，再删除脚本、缓存与临时目录：

```sh
rm -f /etc/openclash/custom/dnsmasq_rules.rb
rm -rf /etc/openclash/dnsmasq-rules /tmp/openclash-dnsmasq-rules
```

卸载不会删除 OpenClash 的模块订阅，也不会还原由 OpenClash 自身设置的 DNS 转发模式。需要改变 DNS 接管方式时，在 OpenClash LuCI 中重新设置并应用。

返回[广告拦截模块目录](../README.md)。
