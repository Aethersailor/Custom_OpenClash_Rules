# 已归档的远程覆写配置文件

本目录存放已归档的 OpenClash 远程覆写配置文件。

## 归档原因

2025-12-24：`Custom_Overwrite.conf` 和 `Custom_Overwrite_NoIPv6.conf` 已归档。

这两个配置文件已过时，不再维护。新配置应选择以下方式之一：

1. 按照项目 [Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki) 完成 OpenClash 设置，并使用 [`cfg/`](../../cfg/) 中的订阅转换模板。
2. 使用 [`cfg/yaml/`](../../cfg/yaml/) 中的当前 YAML，或通过 [`../yaml/`](../yaml/) 远程调用。

## 归档文件列表

- `Custom_Overwrite.conf`：原远程覆写配置文件。
- `Custom_Overwrite_NoIPv6.conf`：原无 IPv6 版本远程覆写配置文件。

> [!WARNING]
> 归档文件不会随当前配置和 OpenClash 行为更新，不应直接用于新部署。
