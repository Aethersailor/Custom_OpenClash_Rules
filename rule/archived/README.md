# 归档的规则文件

本目录包含已弃用但保留用于历史参考的规则文件。

## 文件说明

| 文件名 | 说明 | 弃用原因 |
| :--- | :--- | :--- |
| `Emby.list` | Emby 媒体服务器规则 | 已合并至 GeoSite 上游 |
| `Game_Download_CDN.list` | 主流游戏平台下载 CDN 历史规则 | 主规则已合并至 GeoSite；仓库根规则入口现自动合并 GeoSite 与 `Steam_CDN.list` |
| `HBO_fix.list` | HBO 补充修复规则 | 已合并至 GeoSite 上游 |
| `Ozon.list` | 俄罗斯电商 Ozon 规则 | 已合并至 GeoSite 上游 |

## 使用限制

这些规则文件不再主动维护，也不会被当前配置或规则生成流程自动引用。

> [!WARNING]
> 归档规则可能不再适用于当前服务地址或网络环境。确需迁移其中内容时，应先核对上游现状，并在独立 Provider 中测试命中范围。
