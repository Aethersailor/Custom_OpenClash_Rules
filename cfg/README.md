<div align="center">

# 🧩 OpenClash 订阅转换模板与 YAML 配置

**两种使用路径，对应的规则与策略组体验保持一致**

[目录说明](#-目录说明) · [版本对比](#-版本对比) · [使用订阅转换模板](#-使用-ini-订阅转换模板) · [使用 YAML 配置](#-使用-yaml-配置文件) · [注意事项](#%EF%B8%8F-注意事项)

</div>

---

> [!IMPORTANT]
> 本目录提供两类用途不同的配置文件：
>
> - 根目录中的 `.ini` 文件是 **订阅转换模板**，由 Subconverter 等转换后端读取，用于生成最终的 Mihomo 配置。
> - [`yaml/`](./yaml) 目录中的 `.yaml` 文件是 **可供 Mihomo / OpenClash 使用的完整配置文件**，通过 `proxy-providers` 加载订阅节点。
>
> 两类文件的使用方式不同，不能相互替代；同名版本的规则、策略组和使用体验则尽量保持一致。

> [!TIP]
> 目前 8 个 `.ini` 模板中，4 个**非 Fallback 版本的远程链接**已经被 OpenClash 收录，可直接在 OpenClash 内置的订阅转换模板列表中选择。  
> 4 个 Fallback 版本尚未被收录，使用时需要手工填写对应的远程模板地址。

## 📁 目录说明

### `.ini` 订阅转换模板

`cfg` 根目录包含 8 个 `.ini` 文件，由 4 个常规版本及其 Fallback 版本组成：

| 常规版本 | Fallback 版本 |
| --- | --- |
| [`Custom_Clash.ini`](./Custom_Clash.ini) | [`Custom_Clash_Fallback.ini`](./Custom_Clash_Fallback.ini) |
| [`Custom_Clash_Lite.ini`](./Custom_Clash_Lite.ini) | [`Custom_Clash_Lite_Fallback.ini`](./Custom_Clash_Lite_Fallback.ini) |
| [`Custom_Clash_GFW.ini`](./Custom_Clash_GFW.ini) | [`Custom_Clash_GFW_Fallback.ini`](./Custom_Clash_GFW_Fallback.ini) |
| [`Custom_Clash_Full.ini`](./Custom_Clash_Full.ini) | [`Custom_Clash_Full_Fallback.ini`](./Custom_Clash_Full_Fallback.ini) |

这些文件只定义订阅转换所需的规则、策略组及相关参数，本身不是可以直接启动 Mihomo / OpenClash 的完整 YAML 配置。

### `yaml/` 配置文件

[`yaml/`](./yaml) 目录提供与上述 8 个 `.ini` 模板对应的完整 YAML 配置：

| 对应 `.ini` 模板 | YAML 配置文件 |
| --- | --- |
| `Custom_Clash.ini` | [`Custom_Clash.yaml`](./yaml/Custom_Clash.yaml) |
| `Custom_Clash_Fallback.ini` | [`Custom_Clash_Fallback.yaml`](./yaml/Custom_Clash_Fallback.yaml) |
| `Custom_Clash_Lite.ini` | [`Custom_Clash_Lite.yaml`](./yaml/Custom_Clash_Lite.yaml) |
| `Custom_Clash_Lite_Fallback.ini` | [`Custom_Clash_Lite_Fallback.yaml`](./yaml/Custom_Clash_Lite_Fallback.yaml) |
| `Custom_Clash_GFW.ini` | [`Custom_Clash_GFW.yaml`](./yaml/Custom_Clash_GFW.yaml) |
| `Custom_Clash_GFW_Fallback.ini` | [`Custom_Clash_GFW_Fallback.yaml`](./yaml/Custom_Clash_GFW_Fallback.yaml) |
| `Custom_Clash_Full.ini` | [`Custom_Clash_Full.yaml`](./yaml/Custom_Clash_Full.yaml) |
| `Custom_Clash_Full_Fallback.ini` | [`Custom_Clash_Full_Fallback.yaml`](./yaml/Custom_Clash_Full_Fallback.yaml) |

相互对应的 `.ini` 与 `.yaml` 文件会尽量保持以下内容一致：

- 规则内容与排列顺序
- 策略组名称与用途
- 节点地区分组
- 常规版或 Fallback 版的策略行为
- 各版本的功能定位和实际使用体验

由于 `.ini` 需要经过订阅转换后端生成最终配置，而 YAML 文件本身已经是完整配置，因此两者不会逐字相同。

此外，`yaml/` 目录中还包含独立的 [`Custom_Clash_DIY&Airport.yaml`](./yaml/Custom_Clash_DIY&Airport.yaml)。该文件用于“自建节点优先、机场节点故障转移”的特定场景，不属于上述 8 个相互对应的常规版本。

## 📊 版本对比

| 版本 | 定位 | 分流复杂度 | 适合用户 |
| --- | --- | :---: | --- |
| `Custom_Clash` | 在功能完整度、策略组数量和维护成本之间保持平衡 | 中等 | 绝大多数用户，建议优先选择 |
| `Custom_Clash_Lite` | 保留基础直连、代理及常用服务分流，减少策略组数量 | 较低 | 不需要大量流媒体解锁或细粒度分流的用户 |
| `Custom_Clash_GFW` | 主要代理 GFW 列表及相关 IP，其余流量默认直连 | 极低 | 只需要基础代理能力、追求极简结构的用户 |
| `Custom_Clash_Full` | 提供更多服务、地区和节点用途分组 | 较高 | 节点较多并需要精细控制的进阶用户 |

### ⭐ 标准版：`Custom_Clash`

覆盖常见即时通讯、社交媒体、AI 服务、GitHub、游戏平台、流媒体和海外服务，同时将策略组数量控制在相对合理的范围内。

**适合：** 希望获得较完整的日常分流体验，但不想维护过多策略组的用户。

### ⚡ 轻量版：`Custom_Clash_Lite`

保留基础代理、直连、GitHub、Google、Apple、Microsoft、Steam 和游戏平台等常用分流，减少独立业务策略组。

**适合：** 更重视简洁、性能和易维护性，不需要复杂流媒体分区的用户。

### 🪶 极简版：`Custom_Clash_GFW`

主要将 GFW 列表以及 Telegram、Facebook、Twitter 等相关 IP 流量交给代理，其余未命中流量默认直连。

**适合：** 只需要“受阻流量走代理，其余流量直连”的用户。

### 🧰 重度分流版：`Custom_Clash_Full`

在标准版基础上增加更多独立服务策略组、地区节点组和节点用途分类，可进行更细致的策略控制，但配置规模和维护复杂度也更高。

**适合：** 节点地区丰富，存在家宽、低倍率或特殊用途节点，并且需要针对不同服务精确选路的进阶用户。

## 🔁 常规版与 Fallback 版

每个版本均提供常规版和 Fallback 版，两者的主要区别是业务策略组类型。

### 常规版

常规版的主要业务策略组使用 `select`：

- 可以在 OpenClash 面板中手工选择策略组、地区组或具体节点
- 可以将自动选择组作为候选项
- 用户对各业务出口拥有更直接的控制权

### Fallback 版

Fallback 版的主要业务策略组使用 `fallback`：

- 按配置中的候选顺序进行健康检查
- 自动使用首个可用的策略或节点
- 当前候选不可用时自动切换到后续候选
- 更侧重自动故障转移，减少人工切换

> [!NOTE]
> 此处的 Fallback 是指 Mihomo 的 `fallback` 策略组类型，与 DNS `fallback`、OpenClash 的备用 DNS 服务器或订阅转换后端无关。

## 🔄 使用 `.ini` 订阅转换模板

`.ini` 文件由订阅转换后端读取。转换后端会根据模板中的规则和策略组定义，将原始节点订阅生成完整的 Mihomo YAML 配置。

> [!CAUTION]
> `.ini` 文件不能直接上传到 OpenClash 作为运行配置。

### 非 Fallback 模板：直接在 OpenClash 中选择

以下 4 个非 Fallback 模板的**远程链接**已经被 OpenClash 收录：

| 模板文件 | OpenClash 内置名称 |
| --- | --- |
| [`Custom_Clash.ini`](./Custom_Clash.ini) | `Aethersailor 规则 标准版 Custom_Clash` |
| [`Custom_Clash_Lite.ini`](./Custom_Clash_Lite.ini) | `Aethersailor 规则 轻量版 Custom_Clash_Lite` |
| [`Custom_Clash_GFW.ini`](./Custom_Clash_GFW.ini) | `Aethersailor 规则 极简版(GFW) Custom_Clash_GFW` |
| [`Custom_Clash_Full.ini`](./Custom_Clash_Full.ini) | `Aethersailor 规则 重度分流版 Custom_Clash_Full` |

使用方法：

1. 进入 OpenClash 的订阅管理页面。
2. 新增订阅，或编辑已有订阅。
3. 启用 **在线订阅转换**。
4. 在 OpenClash 内置的 **订阅转换模板** 列表中，选择对应的 `Aethersailor 规则` 模板。
5. 保存设置并更新订阅配置。

使用这些非 Fallback 模板时，无需下载 `.ini` 文件，也无需手工填写模板地址。

> [!NOTE]
> OpenClash 收录的是这些模板的远程链接，模板文件本身仍然托管并维护在本仓库中。

### Fallback 模板：手工填写远程地址

以下 4 个 Fallback 模板目前未被 OpenClash 内置列表收录。使用时需要在订阅设置中选择自定义模板，并填写对应地址。

#### 标准 Fallback 版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Fallback.ini
```

#### 轻量 Fallback 版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite_Fallback.ini
```

#### 极简 GFW Fallback 版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW_Fallback.ini
```

#### 重度分流 Fallback 版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full_Fallback.ini
```

<details>
<summary><strong>🔗 非 Fallback 模板的手工地址</strong></summary>

<br>

通常情况下，OpenClash 用户可以直接从内置列表中选择这些模板。以下地址主要用于自建 Subconverter、其他订阅转换工具、特殊调试场景，或 OpenClash 内置列表未正常显示时。

### 标准版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash.ini
```

### 轻量版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite.ini
```

### 极简版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW.ini
```

### 重度分流版

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full.ini
```

</details>

## 📄 使用 YAML 配置文件

YAML 配置文件不需要经过订阅转换。文件中已经包含策略组、规则、DNS、嗅探、GeoData 和常用运行参数，并通过 `proxy-providers` 加载节点订阅。

使用方法：

1. 从 [`yaml/`](./yaml) 目录下载所需版本。
2. 打开 YAML 文件，找到以下位置：

   ```yaml
   proxy-providers:
     provider1:
       url: "url"
   ```

3. 将 `"url"` 替换为自己的节点订阅地址。
4. 将修改后的 YAML 文件上传到 OpenClash 配置管理页面。
5. 执行配置检查，选择该配置文件并启动 OpenClash。

多订阅用户可以复制 `provider1`，依次命名为 `provider2`、`provider3`，并将新增 Provider 加入各策略组的 `use` 列表。

> [!WARNING]
> 订阅地址通常包含访问凭证。不要将填写真实订阅地址后的 YAML 文件上传到公开仓库、公开网盘或公开 Issue。

### YAML 配置的特点

- 不依赖在线订阅转换后端
- 节点由 `proxy-providers` 独立更新
- 可以直接检查和维护完整配置结构
- 包含较完整的 Mihomo 运行参数
- 部分端口、DNS、TUN 和运行参数可能被 OpenClash 设置覆写

## 🧩 `Custom_Clash_DIY&Airport.yaml`

[`Custom_Clash_DIY&Airport.yaml`](./yaml/Custom_Clash_DIY&Airport.yaml) 面向以下特定使用场景：

- 自建节点作为优先出口
- 机场订阅作为故障转移备用
- 自建线路承担主要解锁和分流任务
- 不同业务按照预设地区顺序自动回落

该文件需要分别填写机场订阅和自建节点订阅，并未完整配置所有 DNS、IPv6 等运行参数。它属于独立的进阶配置，不对应根目录中的某个 `.ini` 模板。

## ⚠️ 注意事项

- 所有常规模板和 YAML 配置均面向 **Mihomo（Clash Meta）/ OpenClash**。
- `.ini` 模板会重新生成策略组与规则，不应依赖机场订阅中原有的规则结构。
- YAML 文件中的订阅地址、端口、DNS、IPv6、TUN 和控制器设置应根据实际环境检查。
- Fallback 版本依赖健康检查结果；检测地址不可达或网络异常时，可能影响故障转移判断。
- 节点地区分组依赖节点名称匹配，命名异常的节点可能无法进入预期地区组。
- 最终生成和运行效果还会受到订阅内容、转换后端、OpenClash 版本、Mihomo 内核、GeoSite / GeoIP 数据以及覆写设置影响。
- 已自行编写规则、覆写或脚本的用户，应确认其中引用的策略组名称与所选版本一致。
- 更新配置前建议保留当前可用配置，以便出现兼容性问题时回退。
- 本项目不提供代理节点、机场订阅或订阅转换服务。

## 📚 配套设置与文档

本目录只提供订阅转换模板和 YAML 配置文件。OpenClash 的 DNS、IPv6、运行模式及其他配套设置，请参阅项目 Wiki：

- [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)
- [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

---

<div align="center">

模板、配置文件与规则会持续维护，请以仓库 `main` 分支中的最新版本为准。

</div>
