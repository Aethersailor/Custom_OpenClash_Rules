# 已停止提供广告拦截与远程 hosts 模块

本项目已放弃通过纯 OpenClash 覆写模块加载普通 hosts 文本和 dnsmasq 广告规则的这组功能。此前的五个模块及共享脚本已撤回，本目录仅保留原因说明与旧版清理方法，不提供模块订阅地址。

## 当前原生功能的限制

截至 2026 年 10 月 11 日，已重新核对 OpenClash dev `v0.48.001`，对应提交 [`e5018342`](https://github.com/vernesong/OpenClash/commit/e5018342ef7fc1ca74643004a1913fb221c6f897)。在 OpenWrt 测试设备的 Ruby `4.0.2` 上，使用该提交的 helper 临时副本验证；设备未升级 OpenClash，未修改服务配置，也未重启服务。

- `DOWNLOAD_FILE` 可以下载文件，但没有为任意 dnsmasq 规则提供格式校验、来源合并和停用清理机制。
- 文件 helper 按 YAML 读取数据，不是普通 hosts 文本读取器。实测约 6.6 MB 的 adblockfilters hosts 只读到开头 294 字节，GitHub520 hosts 也在注释处被截断。
- `[Overwrite]` 表达式仍受白名单限制，不能直接读取文本文件、执行 shell 或调用服务重载、清理操作。

因此，单纯把文件下载到路由器上，无法完整满足这组模块的加载、冲突处理和停用清理要求；需要额外脚本的方案也不符合仅订阅覆写模块的使用方式。

原生 Rule Provider、YAML `hosts` 或 JSON 数据属于其他格式，不能视为已实现任意普通 hosts 地址及原始 dnsmasq 规则加载。本项目未将这些方向发布为这组模块的替代方案。

实现依据：[模块加载与下载](https://github.com/vernesong/OpenClash/blob/e5018342ef7fc1ca74643004a1913fb221c6f897/luci-app-openclash/root/etc/init.d/openclash#L3242)、[文件 helper 与表达式白名单](https://github.com/vernesong/OpenClash/blob/e5018342ef7fc1ca74643004a1913fb221c6f897/luci-app-openclash/root/usr/share/openclash/YAML.rb#L1059)。

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
