<div align="center">

# 📄 OpenClash 最小 YAML 配置

**8 个常规配置、2 个自建节点优先配置，以及 1 个完整参考模板**

[推荐流程](#recommended-workflow) · [文件列表](#file-list) · [普通版与故障转移版](#standard-vs-fallback) · [自建节点配置](#selfhosted-fallback) · [手动导入](#manual-import)

</div>

---

> [!IMPORTANT]
> 本目录中的正式 YAML 是 **OpenClash 专用最小配置：** 主要定义节点来源、静态节点、策略组、Rule Provider 和分流规则。端口、运行模式、DNS、IPv6、TUN、嗅探、GeoData、日志及控制器等参数由 OpenClash LuCI 管理。
>
> 请先按 Wiki 配置插件，再选择「远程覆写模块」或「下载 YAML 手动导入」。如需订阅转换模板，请返回 [`../`](../)。

<a id="recommended-workflow"></a>

## 🧭 本项目推荐的使用流程

本项目的 OpenClash 配置流程不是「导入一个文件就结束」，而是：

1. **先配置插件：** 按照项目 Wiki 的 [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)，结合实际网络环境和需求，逐项检查并完成 OpenClash LuCI 页面中的 DNS、IPv6、运行模式、流量接管等设置。
2. **选择配置路径：** 从下列三种配置路径中选择一种作为主要使用方式。
3. **填写必要信息：** 配置订阅地址、自建节点或模块变量。
4. **最后验收：** 确认配置校验、内核启动、Provider 更新、策略组、DNS、IPv6 和实际分流均正常后，再投入日常使用。

> [!IMPORTANT]
> 三种路径解决的是「如何获得并维护策略组、规则和节点来源」，不能替代 OpenClash LuCI 中的插件设置。建议选择一种主路径，不要在不了解执行顺序和覆盖关系时叠加使用。

### 三种路径怎么选

| 使用路径 | 优点 | 代价与限制 | 推荐人群 |
| --- | --- | --- | --- |
| **① 订阅转换与 `.ini` 模板** | 操作最简单；在 OpenClash 中更新和切换订阅方便；无需手动维护 YAML | 依赖所选订阅转换后端的可用性、兼容性和隐私保障；也可以自建转换后端 | 希望省事、经常切换配置的大多数用户 |
| **② 远程 YAML 覆写模块** | 无需订阅转换；填写模块变量即可下载对应 YAML 并写入订阅；远程文件可随仓库维护更新 | 需要了解 OpenClash 覆写模块的添加、变量填写和故障排查；远程更新可能改变下一次加载结果 | 希望使用 YAML 和自动更新，但不需要长期手动编辑文件的用户 |
| **③ 下载 YAML 后手动修改并导入** | 自由度最高；配置文件完全自行控制；不依赖订阅转换后端 | 操作步骤和维护要求最多；需要理解 YAML、Provider、策略组和规则引用；仓库更新需自行对比迁移 | 熟悉 Mihomo YAML 的高阶用户 |

> [!NOTE]
> 本项目提供的订阅转换模板和 YAML 基于典型场景与维护经验设计，其中包含对节点、地区和网络环境的必要假设，不能覆盖所有个性化需求。需要精确控制分流行为时，应自行编写或修改 YAML。

<a id="file-list"></a>

## 📁 文件列表

### 8 个常规 YAML

| 版本 | YAML 文件 | 对应 `.ini` | 定位 |
| --- | --- | --- | --- |
| 标准版 | [`Custom_Clash.yaml`](./Custom_Clash.yaml) | `Custom_Clash.ini` | 均衡，适合多数用户 |
| 标准故障转移版 | [`Custom_Clash_Fallback.yaml`](./Custom_Clash_Fallback.yaml) | `Custom_Clash_Fallback.ini` | 自动按候选顺序故障转移 |
| 轻量版 | [`Custom_Clash_Lite.yaml`](./Custom_Clash_Lite.yaml) | `Custom_Clash_Lite.ini` | 策略组更少，维护更简单 |
| 轻量故障转移版 | [`Custom_Clash_Lite_Fallback.yaml`](./Custom_Clash_Lite_Fallback.yaml) | `Custom_Clash_Lite_Fallback.ini` | 轻量结构与故障转移结合 |
| 极简 GFW 版 | [`Custom_Clash_GFW.yaml`](./Custom_Clash_GFW.yaml) | `Custom_Clash_GFW.ini` | 只保留基础代理与直连逻辑 |
| 极简 GFW 故障转移版 | [`Custom_Clash_GFW_Fallback.yaml`](./Custom_Clash_GFW_Fallback.yaml) | `Custom_Clash_GFW_Fallback.ini` | 极简结构与故障转移结合 |
| 重度分流版 | [`Custom_Clash_Full.yaml`](./Custom_Clash_Full.yaml) | `Custom_Clash_Full.ini` | 业务和地区分组最丰富 |
| 重度分流故障转移版 | [`Custom_Clash_Full_Fallback.yaml`](./Custom_Clash_Full_Fallback.yaml) | `Custom_Clash_Full_Fallback.ini` | 重度分流结构与故障转移结合 |

这 8 个文件与对应 `.ini` 在策略组、规则顺序、节点分组，以及普通版与故障转移版的使用方式上尽量保持一致，但实现方式不同。

<a id="2-个自建节点--机场后备-yaml"></a>

### 2 个自建节点优先、订阅节点后备的 YAML 配置

| 文件 | 自建节点来源 | 适用情况 |
| --- | --- | --- |
| [`Custom_Clash_Selfhosted_Manual_Fallback.yaml`](./Custom_Clash_Selfhosted_Manual_Fallback.yaml) | 顶层 `proxies` 中手动填写静态节点 | 熟悉节点协议参数，希望直接维护节点配置 |
| [`Custom_Clash_Selfhosted_Provider_Fallback.yaml`](./Custom_Clash_Selfhosted_Provider_Fallback.yaml) | 独立 `selfhost` HTTP Proxy Provider | 已有可通过 HTTP 获取的自建节点订阅或 Provider 文件 |

两者均以自建节点作为优先出口、订阅节点 `provider1` 作为后备，并基于标准故障转移版的策略组与规则扩展。

### 完整参考模板

[`Complete_YAML_Configuration_Template.yaml`](./Complete_YAML_Configuration_Template.yaml) 用于展示包含端口、DNS、TUN、嗅探、GeoData 等参数的完整 Mihomo YAML 配置结构，并附带解释性注释。

> [!CAUTION]
> 该文件用于学习、对照和自行编写 YAML，**不建议直接作为本项目推荐配置使用**。本项目正式 YAML 将运行参数交由 OpenClash LuCI 管理。

## 📊 常规版本怎么选

| 版本 | 特点 | 建议 |
| --- | --- | --- |
| 标准版 | 日常业务覆盖与复杂度均衡 | 不确定时优先选择 |
| 轻量版 | 策略组较少，结构简洁 | 不需要复杂流媒体和业务分流 |
| 极简 GFW 版 | 主要代理受阻流量，其余直连 | 只需要基础代理 |
| 重度分流版 | 业务、地区和节点用途分类最多 | 节点丰富、需要精确选路 |

<a id="standard-vs-fallback"></a>

<a id="-普通版与-fallback-版"></a>

## 🔁 普通版与故障转移版

- **普通版：** 主要业务策略组使用 `select`，便于手动决定出口。
- **故障转移版：** 主要业务策略组使用 `fallback`，按候选顺序自动检测和切换。

> [!WARNING]
> `fallback` 只验证健康检查地址的连通性，不能判断流媒体、AI 或其他服务的地区解锁能力。

<a id="selfhosted-fallback"></a>

<a id="‍️-自建节点--机场后备"></a>

## 🏴‍☠️ 自建节点优先、订阅节点后备

<a id="手工节点版"></a>

### 手动节点版

`Custom_Clash_Selfhosted_Manual_Fallback.yaml` 预留 VLESS + REALITY + Vision 节点示例。使用前必须替换 `server`、`port`、`uuid`、`servername`、`public-key` 和 `short-id`，或用其他 Mihomo 支持的协议节点定义替换整个示例。

该版本没有对应的通用远程覆写模块，因为不同节点协议和字段差异较大，且敏感参数不适合通过一组通用变量统一映射。

### Provider 版

`Custom_Clash_Selfhosted_Provider_Fallback.yaml` 包含：

- `provider1`：节点订阅；
- `selfhost`：自建节点订阅；
- `🏴‍☠️ 自建节点`：从 `selfhost` 中选择可用节点；
- `fallback` 类型的代理策略组：自建节点优先，订阅节点地区组后备。

`selfhost.url` 必须是 Mihomo 可识别且可通过 HTTP 获取的节点来源，例如：

- 以 `proxies:` 开头的 Mihomo Provider YAML；
- 逐行节点 URI 订阅；
- 上述 URI 订阅的 Base64 编码内容。

单条 `vless://`、`hysteria2://` 或 `tuic://` 链接不是 HTTP Provider 地址，应先转为可访问的订阅 URL。使用公共转换服务会暴露完整节点凭据，建议优先使用自建转换服务，或自行托管 Provider 文件。

<a id="manual-import"></a>

<a id="️-手工修改并导入"></a>

## ✏️ 手动修改并导入

以 8 个常规 YAML 为例：

1. 下载所需文件。
2. 找到：

   ```yaml
   proxy-providers:
     provider1:
       url: "url"
   ```

3. 将 `"url"` 替换为自己的订阅地址，并保留引号。
4. 多订阅用户可复制 `provider1`，设置唯一名称和 `path`，再把新增 Provider 加入相关策略组的 `use` 列表。
5. 上传到 OpenClash 配置管理，执行配置校验并启用。
6. 完成最终验收。

> [!WARNING]
> 订阅 URL、自建节点 UUID、密钥及其他认证信息属于敏感数据。不要把填写后的 YAML 发布至公开仓库、公开 Issue、网盘或聊天记录。

<a id="手工导入的维护特点"></a>

### 手动导入的维护特点

手动导入 YAML 的自由度最高，但仓库后续更新不会自动合并到本地副本。升级时应备份旧配置，对比并迁移 Provider、策略组和规则变化。

## 🌐 使用远程覆写模块

不想手动下载和修改 YAML 时，可使用 [`../../overwrite/yaml/`](../../overwrite/yaml/) 中的远程模块：

- 8 个单独模块：固定调用对应常规 YAML；
- 1 个 8 合 1 模块：通过 `EN_KEY2` 选择 8 个常规 YAML；
- 1 个自建节点 Provider 模块：同时填写节点订阅和自建节点订阅。

远程模块会下载对应 YAML，并将模块变量写入 Provider URL。它不会替代 LuCI 设置，也不会为手动自建节点版自动生成协议参数。

## ✅ 最终验收

导入或调用 YAML 后，确认：

- 配置校验通过，内核正常启动；
- 所有需要的 Provider 更新成功；
- 策略组中存在预期节点，地区分组匹配合理；
- Rule Provider 和规则加载成功；
- DNS、IPv6、TUN 及流量接管符合 LuCI 设置；
- 常用直连与代理服务工作正常，日志无明显错误；
- 保存一份已验证的配置，以便回退。

## 📚 相关文档

- [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)
- [`cfg/` 订阅转换模板](../)
- [`overwrite/yaml/` 远程 YAML 覆写模块](../../overwrite/yaml/)
- [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

---

<div align="center">

配置基于典型场景设计；需要完全贴合实际需求时，请自行编写 YAML。

</div>
