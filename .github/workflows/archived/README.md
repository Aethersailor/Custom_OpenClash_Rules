# 🗄️ Archived Workflows

这里存放已废弃或不再使用的工作流。虽然不再运行，但保留以供参考。

## 📂 文件说明

| 文件名 | 描述 | 弃用原因 |
| :--- | :--- | :--- |
| **[generate_smart.yml](generate_smart.yml)** | 从标准 INI 模板生成 Smart 内核专用模板（替换 `url-test` 为 `smart`） | OpenClash 已更新 Smart 覆写功能，此工作流已无必要 |
| **[generate_smart_gfw.yml](generate_smart_gfw.yml)** | 从 GFW 模板生成 Smart GFW 专用模板 | OpenClash 已更新 Smart 覆写功能，此工作流已无必要 |
| **[reject_cfg_prs.yml](reject_cfg_prs.yml)** | 自动拒绝非授权用户对 `/cfg` 目录的 PR（保护配置文件完整性） | 目前处于停用状态，按需恢复 |

> [!NOTE]
> 这些工作流已停用，不会被 GitHub Actions 自动执行。如需使用，请将文件移回上级目录。
