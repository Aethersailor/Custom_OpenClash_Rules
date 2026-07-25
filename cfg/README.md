<div align="center">

# 🧩 OpenClash 订阅转换模板

**8 个 `.ini` 模板，以及三种推荐使用路径的总入口**

[推荐流程](#-本项目推荐的使用流程) · [模板列表](#-ini-模板列表) · [版本区别](#-版本区别) · [使用方法](#-使用订阅转换模板) · [远程链接](#-模板远程链接)

</div>

---

> [!IMPORTANT]
> 本目录根层主要存放 `.ini` **订阅转换模板**。关于最小 YAML 配置、手工导入和自建节点版本，请前往 [`yaml/README.md`](./yaml/README.md)；关于通过覆写模块调用远程 YAML，请前往 [`../overwrite/yaml/README.md`](../overwrite/yaml/README.md)。


## 🧭 本项目推荐的使用流程

本项目坚持的 OpenClash 使用方式不是“导入一个文件就结束”，而是：

1. **先配置插件：** 按照项目 Wiki 的 [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)，结合自己的网络环境和需求，逐项检查并完成 OpenClash LuCI 页面中的 DNS、IPv6、运行模式、流量接管等设置。
2. **再三选一：** 从下列三种配置路径中选择一种作为主要使用方式。
3. **填写必要信息：** 配置订阅地址、自建节点或模块变量。
4. **最后验收：** 确认配置校验、内核启动、Provider 更新、策略组、DNS、IPv6 和实际分流均正常，再进入日常使用。

> [!IMPORTANT]
> 三种路径解决的是“如何获得并维护策略组、规则和节点来源”，不能替代 OpenClash LuCI 中的插件设置。建议选择一种主路径，不要在不了解执行顺序和覆盖关系时叠加使用。

### 三种路径怎么选

| 使用路径 | 优点 | 代价与限制 | 推荐人群 |
| --- | --- | --- | --- |
| **① 订阅转换 + `.ini` 模板** | 操作最简单；在 OpenClash 中更新和切换订阅方便；无需手工维护 YAML | 依赖所选订阅转换后端的可用性、兼容性和隐私保障；也可以自建转换后端 | 希望省事、经常切换配置的大多数用户 |
| **② 远程 YAML 覆写模块** | 无需订阅转换；填写模块变量即可下载对应 YAML 并写入订阅；远程文件可随仓库维护更新 | 需要学会 OpenClash 覆写模块的添加、变量填写和排障；远程更新可能改变下一次加载结果 | 希望简单使用 YAML，又不想手工编辑文件的用户 |
| **③ 下载 YAML 后手工修改并导入** | 自由度最高；配置文件完全由自己控制；不依赖订阅转换后端 | 最复杂、最繁琐；需要理解 YAML、Provider、策略组和规则引用；仓库更新需自行对比迁移 | 熟悉 Mihomo YAML 的高阶用户 |

> [!NOTE]
> 本项目提供的订阅转换模板和 YAML，均由维护者依据典型场景与使用经验推定设计——通俗地说，包含一定程度的“合理脑补”。它们不可能 100% 贴合每个人的节点、地区、业务和网络环境。需要完全个性化的行为时，请自行编写或深度修改 YAML。


## 📁 `.ini` 模板列表

`cfg` 根目录共有 8 个模板，由 4 个普通版及其 Fallback 版组成：

| 版本 | 文件 | OpenClash 内置名称 | 定位 |
| --- | --- | --- | --- |
| 标准版 | [`Custom_Clash.ini`](./Custom_Clash.ini) | Aethersailor 规则 标准版 Custom_Clash | 均衡的日常分流，建议多数用户优先选择 |
| 标准 Fallback 版 | [`Custom_Clash_Fallback.ini`](./Custom_Clash_Fallback.ini) | — | 标准版策略组改为故障转移，减少人工切换 |
| 轻量版 | [`Custom_Clash_Lite.ini`](./Custom_Clash_Lite.ini) | Aethersailor 规则 轻量版 Custom_Clash_Lite | 减少业务策略组，结构更简洁 |
| 轻量 Fallback 版 | [`Custom_Clash_Lite_Fallback.ini`](./Custom_Clash_Lite_Fallback.ini) | — | 轻量结构与自动故障转移结合 |
| 极简 GFW 版 | [`Custom_Clash_GFW.ini`](./Custom_Clash_GFW.ini) | Aethersailor 规则 极简版(GFW) Custom_Clash_GFW | 主要代理 GFW 相关流量，其余默认直连 |
| 极简 GFW Fallback 版 | [`Custom_Clash_GFW_Fallback.ini`](./Custom_Clash_GFW_Fallback.ini) | — | 极简分流与自动故障转移结合 |
| 重度分流版 | [`Custom_Clash_Full.ini`](./Custom_Clash_Full.ini) | Aethersailor 规则 重度分流版 Custom_Clash_Full | 更多业务、地区与节点用途分组 |
| 重度分流 Fallback 版 | [`Custom_Clash_Full_Fallback.ini`](./Custom_Clash_Full_Fallback.ini) | — | 重度分流结构与自动故障转移结合 |

目前只有 4 个**非 Fallback** 模板的远程链接已被 OpenClash 收录，可在内置模板列表中直接选择。4 个 Fallback 模板需要使用自定义模板地址。

## 📊 版本区别

### 标准版 `Custom_Clash`

在常用业务分流、策略组数量和维护成本之间保持平衡，覆盖即时通讯、社交媒体、AI、GitHub、游戏平台、流媒体及常见海外服务。

**建议：** 不确定如何选择时优先使用。

### 轻量版 `Custom_Clash_Lite`

减少独立业务策略组，保留基础代理、直连和常用服务分流。

**建议：** 适合重视简洁、性能和低维护成本的用户。

### 极简 GFW 版 `Custom_Clash_GFW`

主要代理 GFW 列表及相关 IP，其他未命中流量默认直连。

**建议：** 适合只需要基础代理，不需要细粒度业务分流的用户。

### 重度分流版 `Custom_Clash_Full`

提供更多业务策略组、国家和地区节点组，以及家宽、低倍率等节点用途分类。

**建议：** 适合节点丰富并希望精确控制出口的进阶用户。

## 🔁 普通版与 Fallback 版

普通版的主要业务组使用 `select`，便于在面板中手工选择地区组、自动组或具体节点。

Fallback 版的主要业务组使用 `fallback`，按候选顺序检测可用性并自动切换，减少人工干预。

> [!WARNING]
> `fallback` 只能根据健康检查判断连通性，不能判断节点是否具备特定流媒体、ChatGPT 或其他地区解锁能力。这里的 Fallback 也与 DNS Fallback 无关。

## 🔄 使用订阅转换模板

### 方法 A：直接选择 OpenClash 内置模板（推荐）

适用于 4 个普通版模板，也是本项目对普通模板的推荐使用方式：

1. 先按 Wiki 完成 OpenClash LuCI 设置。
2. 进入 OpenClash 订阅管理，新增或编辑订阅。
3. 启用在线订阅转换。
4. 在模板列表中选择对应的 `Aethersailor 规则` 模板。
5. 保存并更新订阅。
6. 按本文末尾的验收清单检查运行状态。

这种方式无需下载 `.ini`，也无需手工填写模板 URL。OpenClash 收录的是模板远程链接，模板本身仍由本仓库维护。

### 方法 B：为 Fallback 模板填写自定义地址

适用于尚未被 OpenClash 内置模板列表收录的 4 个 Fallback 版本：

1. 在订阅设置中启用在线订阅转换。
2. 选择自定义模板。
3. 从[模板远程链接](#-模板远程链接)复制对应 Fallback 模板的 GitHub Raw 或 testingcf 地址。
4. 保存并更新订阅。
5. 检查转换结果、策略组和故障转移行为。

> [!IMPORTANT]
> 4 个普通模板已经可以直接从 OpenClash 内置列表选择，常规使用不建议再手工填写模板地址。其远程地址仅作为自建转换后端、兼容性排查或内置列表异常时的备用。

> [!TIP]
> 中国大陆网络环境通常可优先尝试 testingcf 地址；GitHub Raw 可作为备用。

### 关于转换后端

订阅转换会将订阅地址和转换参数发送给所选后端。公共后端的稳定性、兼容性和隐私不由本项目控制。重视可靠性或隐私时，可以自建兼容的订阅转换服务。

`.ini` 文件不能直接上传到 OpenClash 作为运行配置。

## 🔗 模板远程链接

### Fallback 模板

以下 4 个 Fallback 模板尚未被 OpenClash 内置模板列表收录，使用时需要手工填写自定义模板地址。

#### 标准 Fallback 版

- testingcf 加速：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Fallback.ini
  ```

- GitHub Raw：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Fallback.ini
  ```

#### 轻量 Fallback 版

- testingcf 加速：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Lite_Fallback.ini
  ```

- GitHub Raw：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite_Fallback.ini
  ```

#### 极简 GFW Fallback 版

- testingcf 加速：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_GFW_Fallback.ini
  ```

- GitHub Raw：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW_Fallback.ini
  ```

#### 重度分流 Fallback 版

- testingcf 加速：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Full_Fallback.ini
  ```

- GitHub Raw：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full_Fallback.ini
  ```

<details>
<summary><strong>🔗 普通模板备用手工地址</strong></summary>

<br>

> [!NOTE]
> 以下 4 个普通模板已经被 OpenClash 收录。OpenClash 用户应优先从内置模板列表直接选择，无需手工填写地址。
>
> 这些链接主要用于自建 Subconverter、其他订阅转换工具、兼容性排查，或 OpenClash 内置模板列表未正常显示的情况。

### 标准版

- testingcf 加速：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash.ini
  ```

- GitHub Raw：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash.ini
  ```

### 轻量版

- testingcf 加速：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Lite.ini
  ```

- GitHub Raw：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite.ini
  ```

### 极简 GFW 版

- testingcf 加速：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_GFW.ini
  ```

- GitHub Raw：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW.ini
  ```

### 重度分流版

- testingcf 加速：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Full.ini
  ```

- GitHub Raw：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full.ini
  ```

</details>

## 📄 YAML 与远程覆写模块

本目录不重复展开 YAML 文件细节：

- 查看 8 个常规 YAML、两个自建节点版本和完整参考模板：[`yaml/README.md`](./yaml/README.md)
- 使用模块变量填写订阅并自动调用远程 YAML：[`../overwrite/yaml/README.md`](../overwrite/yaml/README.md)

## ✅ 最终验收

选择任一使用路径后，至少确认：

- OpenClash 配置检查通过，Mihomo 内核正常启动；
- 订阅或 Proxy Provider 更新成功，策略组中存在预期节点；
- 规则集和策略组完整加载，日志无明显转换、下载、覆写或 YAML 错误；
- 国内直连、海外代理、DNS、IPv6 和流量接管行为符合 Wiki 设置及个人预期；
- 使用 Fallback 版本时，必要时测试主候选失效后的切换；
- 保存一份已验证可用的配置作为回退。

## 📚 相关文档

- [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)
- [`yaml/` 配置文件说明](./yaml/README.md)
- [`overwrite/yaml/` 远程 YAML 覆写模块](../overwrite/yaml/README.md)
- [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

---

<div align="center">

请以仓库 `main` 分支中的最新文件为准。

</div>
