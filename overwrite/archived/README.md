# 已归档的远程覆写配置文件

本目录存放已归档的 OpenClash 远程覆写配置文件。

## 归档原因

`Custom_Overwrite.conf` 和 `Custom_Overwrite_NoIPv6.conf` 已于 2025 年 12 月 24 日归档。

这两个配置文件已过时，不再维护。新配置应选择以下方式之一：

1. 按照项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 完成 OpenClash 设置，并使用 [`cfg/`](../../cfg/) 中的订阅转换模板。
2. 使用 [`cfg/yaml/`](../../cfg/yaml/) 中当前维护的 YAML，或通过 [`../yaml/`](../yaml/) 中的覆写模块远程调用这些 YAML。

`Use_LuCI_DNS_Only.conf` 已归档。OpenClash 当前会拒绝远程模块读取 UCI、临时 DNS 片段和本地自定义文件。本项目不通过动态 Ruby 或下载可执行脚本绕过该安全限制。需要继续使用该功能时，按 [`../README.md`](../README.md#-use-luci-dns-only-本地钩子) 的说明配置本地钩子。

## 归档文件列表

- `Custom_Overwrite.conf`：原远程覆写配置文件。
- `Custom_Overwrite_NoIPv6.conf`：原无 IPv6 版本远程覆写配置文件。
- `Use_LuCI_DNS_Only.conf`：原 LuCI DNS 唯一来源远程模块；已由 [`../local/Use_LuCI_DNS_Only.sh`](../local/Use_LuCI_DNS_Only.sh) 替代。

> [!WARNING]
> 归档文件不会随当前配置和 OpenClash 行为更新，不应直接用于新部署。
