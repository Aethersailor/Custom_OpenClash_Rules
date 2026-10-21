# 已归档的远程覆写配置文件

本目录存放已归档的 OpenClash 远程覆写配置文件。

## 归档原因

`Custom_Overwrite.conf` 和 `Custom_Overwrite_NoIPv6.conf` 已于 2025 年 12 月 24 日归档。

这两个配置文件已过时，不再维护。新配置应选择以下方式之一：

1. 按照项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 完成 OpenClash 设置，并使用 [`cfg/`](../../cfg/) 中的订阅转换模板。
2. 使用 [`cfg/yaml/`](../../cfg/yaml/) 中当前维护的 YAML，或通过 [`../yaml/`](../yaml/) 中的覆写模块远程调用这些 YAML。

`Use_LuCI_DNS_Only.conf` 因依赖远程模块读取 UCI、临时 DNS 片段和本地自定义文件而归档。其本地钩子替代方案也已停止维护，历史脚本移至 [`script/archived/Use_LuCI_DNS_Only.sh`](../../script/archived/Use_LuCI_DNS_Only.sh)。本项目的覆写功能仅通过 OpenClash 插件的覆写模块机制实现，不再提供需要另行安装并手动接入本地脚本的实现。

`Replace_China_MRS_With_GeoSite.conf` 已移入归档，不再维护或推荐用于新配置。该模块曾用于将大陆绕过自动添加的 `rule-set:oc-cn-domain` 替换为本地 `geosite:cn`，并删除对应的 `oc-cn-domain` Rule Provider。文件保留原有内容，仅供历史参考。

该模块仅适用于 Fake-IP 模式下的 `blacklist` 或未设置 `fake-ip-filter-mode` 的配置，且依赖本地 GeoSite 数据库包含 `cn` 分类。`geosite:cn` 与自动下载的 `cn.mrs` 内容可能不同；其他规则仍引用 `oc-cn-domain` 时，删除 Provider 会导致配置校验失败。完整限制见归档文件中的注释。

## 归档文件列表

- `Custom_Overwrite.conf`：原远程覆写配置文件。
- `Custom_Overwrite_NoIPv6.conf`：原无 IPv6 版本远程覆写配置文件。
- `Use_LuCI_DNS_Only.conf`：原 LuCI DNS 唯一来源远程模块的归档说明；本地脚本替代方案也已归档。
- [`Replace_China_MRS_With_GeoSite.conf`](./Replace_China_MRS_With_GeoSite.conf)：原大陆绕过 MRS 替换模块。

> [!WARNING]
> 归档文件不会随当前配置和 OpenClash 行为更新，不应直接用于新部署。
