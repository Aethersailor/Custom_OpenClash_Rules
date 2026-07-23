<div align="center">

# 🧩 OpenClash 订阅转换模板

**面向 Mihomo（Clash Meta）的订阅转换模板集合**  
根据不同分流需求，提供从极简代理到重度分流的多种配置方案。

[使用方法](#-在-openclash-中使用) · [模板对比](#-模板对比) · [选择建议](#-如何选择) · [注意事项](#%EF%B8%8F-注意事项)

</div>

---

> [!TIP]
> 本目录中的模板远程链接已收录进 **OpenClash 内置的订阅转换模板列表**。  
> OpenClash 用户可在编辑订阅时直接选择对应的 **Aethersailor 规则模板**，无需复制、粘贴或手工维护模板地址。

> [!NOTE]
> OpenClash 内置的是模板的**远程链接**，模板文件本身仍托管并维护在本仓库中。模板更新后，远程地址保持不变。

## 🚀 在 OpenClash 中使用

1. 进入 OpenWrt LuCI。
2. 新增订阅，或编辑已有订阅配置。
3. 启用 **在线订阅转换**。
4. 在 **订阅转换模板** 中选择所需的 `Aethersailor 规则` 模板。
5. 保存并应用设置，然后更新订阅配置。

无需下载 `.ini` 文件，也无需在“自定义模板地址”中手工填写链接。

> [!IMPORTANT]
> 这些 `.ini` 文件是供 Subconverter 使用的**订阅转换外部配置模板**，不是可以直接启动 Mihomo/OpenClash 的 YAML 配置文件。

## 📊 模板对比

| 模板 | OpenClash 内置名称 | 定位 | 分流复杂度 | 适合用户 |
| --- | --- | --- | :---: | --- |
| [`Custom_Clash.ini`](./Custom_Clash.ini) | `Aethersailor 规则 标准版 Custom_Clash` | 功能与复杂度较均衡的标准方案 | 中等 | 绝大多数用户，**推荐优先选择** |
| [`Custom_Clash_Lite.ini`](./Custom_Clash_Lite.ini) | `Aethersailor 规则 轻量版 Custom_Clash_Lite` | 保留基础直连、代理和常用服务分流，减少策略组数量 | 较低 | 不需要大量流媒体解锁或细粒度分流的用户 |
| [`Custom_Clash_GFW.ini`](./Custom_Clash_GFW.ini) | `Aethersailor 规则 极简版(GFW) Custom_Clash_GFW` | 仅代理 GFW 列表及少量相关 IP，其他流量默认直连 | 极低 | 追求极简结构、只需基础代理能力的用户 |
| [`Custom_Clash_Full.ini`](./Custom_Clash_Full.ini) | `Aethersailor 规则 重度分流版 Custom_Clash_Full` | 提供更多服务、地区、用途和节点类型分组 | 较高 | 节点数量较多、需要精细控制和复杂分流的进阶用户 |

## 🧭 如何选择

### ⭐ 标准版：`Custom_Clash.ini`

默认推荐方案。覆盖常见即时通讯、社交媒体、AI 服务、GitHub、游戏平台、流媒体和海外服务，同时保持策略组规模相对适中。

**适合：** 希望获得完整日常体验，但不想维护过多策略组的用户。

### ⚡ 轻量版：`Custom_Clash_Lite.ini`

保留基础代理、直连、GitHub、Google、Apple、Microsoft、Steam 和游戏平台等常用分流，减少独立服务策略组。

**适合：** 更重视简洁、性能和易维护性，不需要复杂流媒体分区的用户。

### 🪶 极简版：`Custom_Clash_GFW.ini`

仅将 GFW 列表以及 Telegram、Facebook、Twitter 等相关 IP 流量交给代理，其余未命中流量默认直连。

**适合：** 只需要“被阻断流量走代理，其余流量直连”的极简用户。

### 🧰 重度分流版：`Custom_Clash_Full.ini`

在标准版基础上增加更多独立服务策略组、地区节点组和节点用途分类，可进行更细致的策略控制，但配置规模和管理复杂度也更高。

**适合：** 节点地区丰富、存在家宽或低倍率节点，并且需要针对不同服务精确选路的进阶用户。

## ⚠️ 注意事项

- 所有模板均面向 **Mihomo（Clash Meta）** 配置生成。
- 模板会重新生成策略组与规则，并覆盖订阅配置原有的规则结构；请勿依赖机场订阅中自带的规则和策略组。
- 模板只负责订阅转换与分流结构，不提供代理节点、订阅服务或转换后端。
- 最终生成效果还会受到订阅内容、转换后端、GeoSite/GeoIP 数据以及 OpenClash 覆写设置影响。
- 已自行编写规则、覆写或脚本的用户，应确认其中引用的策略组名称与所选模板一致。
- 如果 OpenClash 的模板列表中没有出现上述条目，请升级到已收录这些模板的新版 OpenClash。

## 📚 配套设置

为了获得更完整的分流、DNS 与运行模式配置，建议配合项目 Wiki 中的设置方案使用：

- [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)
- [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

<details>
<summary><strong>🔗 手动模板地址（仅供非 OpenClash 场景使用）</strong></summary>

<br>

OpenClash 用户无需使用以下地址。它们仅适用于自建 Subconverter、其他订阅转换工具或特殊调试场景。

### 标准版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash.ini
```

### 轻量版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite.ini
```

### 极简版（GFW）

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW.ini
```

### 重度分流版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full.ini
```

</details>

---

<div align="center">

模板与规则会持续维护，请以仓库 `main` 分支中的最新版本为准。

</div>
