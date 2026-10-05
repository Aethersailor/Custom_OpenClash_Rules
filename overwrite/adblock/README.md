# 广告拦截与 hosts 格式支持

本目录说明 OpenClash 原生覆写模块可以使用的广告规则和 hosts 格式。此前依赖共享本地脚本的五个模块已撤回，当前不提供这些模块的订阅地址，也不要求安装额外脚本、钩子或定时任务。

## 原生覆写的能力范围

已核对 OpenClash 开发版 `v0.47.169` 的覆写实现和 OpenWrt 测试设备上的实际 helper。测试设备使用 Ruby `4.0.2`，剩余 19 个现有模块的原生 helper 兼容检查通过。覆写模块支持：

- `[General]`：设置允许的 OpenClash 选项，通过 `DOWNLOAD_FILE` 下载数据文件。
- `[YAML]`：合并 Mihomo 配置，例如 `hosts`、`rule-providers`、`rules` 和 DNS 设置。
- `[Overwrite]`：调用允许的 Ruby helper 修改配置。表达式受白名单限制，不能直接读取任意文本、执行 shell 或重载其他服务。

`DOWNLOAD_FILE` 负责下载，不能替代规则解析、dnsmasq 加载和停用清理。现有文件 helper 使用 YAML 解析器读取文件，不能当作通用 hosts 文本读取器。实际读取 adblockfilters hosts 文件时，只得到开头的系统条目，后续广告规则未被读取，不能据此宣称规则已加载。

原生覆写修改的是 Mihomo 配置。将 dnsmasq 格式规则下载到配置目录，也不能保证格式校验、多个来源冲突处理和停用清理。因此，本项目不把这种做法作为可直接订阅使用的广告拦截模块发布。

实现依据：[OpenClash 模块示例](https://github.com/vernesong/OpenClash/blob/dev/luci-app-openclash/root/etc/openclash/overwrite/default)、[模块加载与下载实现](https://github.com/vernesong/OpenClash/blob/dev/luci-app-openclash/root/etc/init.d/openclash)、[Ruby helper 与安全校验](https://github.com/vernesong/OpenClash/blob/dev/luci-app-openclash/root/usr/share/openclash/YAML.rb)。

## 规则格式与可用方向

| 来源或需求 | 原始格式 | 无需额外安装的原生使用方向 |
| --- | --- | --- |
| 自选远程 hosts 地址 | `IP 域名` 文本 | 不能直接读取任意 hosts 文本；地址需要提供 Mihomo YAML 映射才可通过文件 helper 合并 |
| [GitHub520](https://github.com/521xueweihan/GitHub520) | [hosts 文本](https://raw.hellogithub.com/hosts) | 上游另有 [JSON 地址](https://raw.hellogithub.com/hosts.json)，可作为数据下载并转换为 Mihomo `hosts`；无需安装转换脚本 |
| [anti-AD](https://github.com/privacy-protection-tools/anti-AD) | [dnsmasq 规则](https://anti-ad.net/anti-ad-for-dnsmasq.conf) | 使用上游专供 Mihomo 的 [MRS 规则](https://anti-ad.net/mihomo.mrs)注册 Rule Provider，不能把 dnsmasq 文件当作 MRS |
| [adblockfilters](https://github.com/217heidai/adblockfilters) | [hosts 规则](https://gcore.jsdelivr.net/gh/217heidai/adblockfilters@main/rules/adblockhosts.txt)或 [dnsmasq 规则](https://gcore.jsdelivr.net/gh/217heidai/adblockfilters@main/rules/adblockdnsmasq.txt) | 使用上游专供 Mihomo 的 [MRS 规则](https://gcore.jsdelivr.net/gh/217heidai/adblockfilters@main/rules/adblockmihomo.mrs)；这不是分别读取上述两种原始格式 |

Mihomo 的 `hosts` 是 YAML 映射，例如：

```yaml
hosts:
  example.com: 192.0.2.10
  ads.example.com: [0.0.0.0, '::']
```

这与系统 hosts 的 `192.0.2.10 example.com` 文本格式不同。格式说明见 [Mihomo hosts 文档](https://wiki.metacubex.one/config/dns/hosts/)。GitHub520 提供真实 IP 映射，不是广告列表；使用该来源也不能保证 GitHub 连通性。

## 曾安装旧版本组件的用户

未安装过旧组件的用户无需执行任何命令。已安装旧组件时，先停用旧版五个模块并保存，再使用设备上已有的脚本卸载：

```sh
ruby /etc/openclash/custom/dnsmasq_rules.rb uninstall
```

此操作会清理旧组件的钩子、定时任务和生成的规则，可能重启目标 dnsmasq 实例。只有命令成功且 DNS 服务正常后，才删除旧脚本：

```sh
rm -f /etc/openclash/custom/dnsmasq_rules.rb
```

不需要重新下载或安装组件。若设备上的旧脚本已经丢失，应先检查原有钩子、定时任务和 dnsmasq 配置中的残留引用，避免直接删除仍被服务使用的规则文件。

返回 [覆写模块目录](../README.md)。
