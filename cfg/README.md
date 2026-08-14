<div align="center">

# 🧩 OpenClash 订阅转换模板

**OpenClash `dev` 版内置的 8 个模板，以及 1 个兼容文件**

[使用方法](#-使用订阅转换模板) · [模板列表](#-模板列表) · [版本区别](#-版本区别) · [Stash 模板](#-在-stash-中使用模板) · [其他配置方式](#-其他配置方式) · [备用链接](#-备用远程链接)

</div>

---

> [!IMPORTANT]
> 本目录直接存放 `.ini` 订阅转换模板。OpenClash `dev` 版当前已内置全部 8 个模板，包括标准版、轻量版、极简 GFW 版、重度分流版，以及文件名以 `_Fallback` 结尾的对应故障转移版。旧版如未显示对应条目，可手动填写远程模板地址。
>
> YAML 配置文件请查看 [`yaml/`](./yaml/)；通过远程覆写模块调用 YAML，请查看 [`../overwrite/yaml/`](../overwrite/yaml/)。

内置状态可在 OpenClash 上游 `dev` 分支的 [`sub_ini.list`](https://github.com/vernesong/OpenClash/blob/dev/luci-app-openclash/root/usr/share/openclash/res/sub_ini.list) 中核对。不同 OpenClash 分支或版本的内置列表可能不同。

## 🔄 使用订阅转换模板

1. 先按照项目 Wiki 的 [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88) 完成插件设置。
2. 进入 OpenClash 订阅管理，新增或编辑订阅。
3. 启用在线订阅转换。
4. 在模板列表中搜索并选择对应的「Aethersailor 规则」模板。如果当前 OpenClash 版本未显示对应条目，则手动填写本文提供的远程模板地址。
5. 保存并更新订阅。
6. 确认配置校验通过，内核、Provider、策略组和实际分流均正常。

OpenClash `dev` 分支的内置列表已收录本仓库全部 8 个模板的远程地址，模板内容仍由本项目维护。仓库更新后，后续订阅转换会获取对应分支上的当前模板。

> [!NOTE]
> `.ini` 文件是订阅转换模板，不能直接作为 OpenClash 运行配置上传。

### 关于转换后端

订阅转换会将订阅地址和转换参数发送给所选后端。公共后端的稳定性、兼容性和隐私不由本项目控制；重视可靠性或隐私时，可以使用自建兼容后端。

## 📁 模板列表

本目录包含 4 个普通版及对应的 4 个故障转移版，共 8 个模板：

| 版本 | 文件 | 定位 |
| --- | --- | --- |
| 标准版 | [`Custom_Clash.ini`](./Custom_Clash.ini) | 日常分流与复杂度均衡，建议多数用户优先选择 |
| 标准故障转移版 | [`Custom_Clash_Fallback.ini`](./Custom_Clash_Fallback.ini) | 标准版分流结构，主要业务组自动故障转移 |
| 轻量版 | [`Custom_Clash_Lite.ini`](./Custom_Clash_Lite.ini) | 策略组较少，结构简洁，维护成本较低 |
| 轻量故障转移版 | [`Custom_Clash_Lite_Fallback.ini`](./Custom_Clash_Lite_Fallback.ini) | 轻量结构与自动故障转移结合 |
| 极简 GFW 版 | [`Custom_Clash_GFW.ini`](./Custom_Clash_GFW.ini) | 主要处理 GFW 相关流量，其余流量默认直连 |
| 极简 GFW 故障转移版 | [`Custom_Clash_GFW_Fallback.ini`](./Custom_Clash_GFW_Fallback.ini) | 极简分流与自动故障转移结合 |
| 重度分流版 | [`Custom_Clash_Full.ini`](./Custom_Clash_Full.ini) | 业务、地区和节点用途分组更丰富 |
| 重度分流故障转移版 | [`Custom_Clash_Full_Fallback.ini`](./Custom_Clash_Full_Fallback.ini) | 重度分流结构与自动故障转移结合 |

[`Custom_Clash_Mainland.ini`](./Custom_Clash_Mainland.ini) 是由工作流从 `Custom_Clash.ini` 自动同步的兼容文件，不是独立配置版本。不要直接修改该文件。

## 📊 版本区别

| 系列 | 特点 | 建议 |
| --- | --- | --- |
| **标准版** | 常用业务覆盖与复杂度均衡 | 不确定时优先选择 |
| **轻量版** | 策略组更少，结构更简洁 | 重视低维护成本 |
| **极简 GFW 版** | 主要代理 GFW 相关流量 | 只需要基础分流 |
| **重度分流版** | 业务、地区和节点用途分类最多 | 节点丰富并需要精细选路 |

<a id="普通版与-fallback-版"></a>

### 普通版与故障转移版

- **普通版：** 主要业务策略组使用 `select`，便于手动选择出口。
- **故障转移版：** 主要业务策略组使用 `fallback`，按候选顺序检测并自动切换。

> [!WARNING]
> `fallback` 只判断健康检查地址是否可达，不能判断节点是否具备流媒体、AI 服务或特定地区的解锁能力。

## 📲 在 Stash 中使用模板

本目录同时提供 9 份 Stash 专用订阅转换模板。脚本从现有 OpenClash 模板投影并生成这些文件，避免两套策略独立维护。Stash 模板只供支持 `target=stash` 的 [SubConverter-Extended](https://github.com/Aethersailor/SubConverter-Extended) 后端使用，不要直接修改生成文件。

| 版本 | Stash 模板 | 定位 |
| --- | --- | --- |
| 标准版 | [`Custom_Stash.ini`](./Custom_Stash.ini) | 日常分流与复杂度均衡 |
| 标准故障转移版 | [`Custom_Stash_Fallback.ini`](./Custom_Stash_Fallback.ini) | 标准版分流结构，主要业务组自动故障转移 |
| 轻量版 | [`Custom_Stash_Lite.ini`](./Custom_Stash_Lite.ini) | 策略组较少，结构简洁 |
| 轻量故障转移版 | [`Custom_Stash_Lite_Fallback.ini`](./Custom_Stash_Lite_Fallback.ini) | 轻量结构与自动故障转移结合 |
| 极简 GFW 版 | [`Custom_Stash_GFW.ini`](./Custom_Stash_GFW.ini) | 主要处理 GFW 相关流量，其余流量默认直连 |
| 极简 GFW 故障转移版 | [`Custom_Stash_GFW_Fallback.ini`](./Custom_Stash_GFW_Fallback.ini) | 极简分流与自动故障转移结合 |
| 重度分流版 | [`Custom_Stash_Full.ini`](./Custom_Stash_Full.ini) | 业务、地区和节点用途分组更丰富 |
| 重度分流故障转移版 | [`Custom_Stash_Full_Fallback.ini`](./Custom_Stash_Full_Fallback.ini) | 重度分流结构与自动故障转移结合 |
| Mainland 兼容文件 | [`Custom_Stash_Mainland.ini`](./Custom_Stash_Mainland.ini) | 内容与标准版相同，仅保留兼容文件名 |

这些 `.ini` 文件不是 Stash 运行配置，不能直接导入 Stash。转换请求必须同时提供订阅地址、`target=stash` 和一份 Stash 模板地址：

```text
https://<支持 target=stash 的后端>/sub?target=stash&url=<URL 编码后的订阅地址>&config=<URL 编码后的 Stash 模板地址>
```

当前已验收的开发实例可按下面的形式调用。将完整转换地址作为 Stash 的配置订阅地址；其中 `<订阅地址>` 必须先进行 URL 编码：

```text
https://test-api.asailor.org/sub?target=stash&url=<URL 编码后的订阅地址>&config=https%3A%2F%2Fraw.githubusercontent.com%2FAethersailor%2FCustom_OpenClash_Rules%2Fmain%2Fcfg%2FCustom_Stash.ini
```

使用前确认后端版本明确支持 `target=stash`。可以使用上述开发实例、其他明确声明支持该目标的 SubConverter-Extended 公共后端，也可以部署自建后端；其他 SubConverter 实现即使能够读取同一份 `.ini`，也不代表能够生成 Stash 配置。

> [!IMPORTANT]
> 当前公共开发实例用于 `dev` 版本和模板的端到端验证，不提供生产可用性承诺，接口与输出可能随开发版本调整。本节不承诺生产地址 `https://api.asailor.org` 已支持 `target=stash`；使用生产地址前，请以其公开版本信息和实际接口结果为准。

> [!NOTE]
> 服务端转换成功和 YAML 结构校验通过，不等于已完成 Stash 真机验收。完整验收仍需在当前版本的 Stash 中检查配置导入、Proxy Provider 与 Rule Provider 刷新、DNS 查询、规则命中和代理连通。

订阅地址可能包含令牌或其他凭据。使用公共后端时，订阅地址和转换参数会发送给该后端；重视隐私时，应使用可信的自建 SubConverter-Extended 后端。

## 🧭 其他配置方式

除订阅转换外，本项目还提供两种使用同一套配置的方式：

| 方式 | 入口 |
| --- | --- |
| 远程 YAML 覆写模块 | [`../overwrite/yaml/`](../overwrite/yaml/) |
| 下载并手动导入 YAML | [`yaml/`](./yaml/) |

> [!IMPORTANT]
> 本项目按同一套配置设计维护订阅转换、远程 YAML 覆写模块和手动导入 YAML。选择相同版本且未自行修改时，策略组定位、规则顺序和分流逻辑应保持一致；文件结构和加载方式不同，实际结果还会受到订阅转换后端及 OpenClash 版本影响。

通常应从三种方式中选择一种作为主路径，不建议同时反复替换同一份当前配置。

## 🔗 备用远程链接

OpenClash `dev` 版通常可直接从内置列表选择全部 8 个模板。以下地址供旧版 OpenClash、自建订阅转换后端和其他兼容工具使用，也可用于兼容性排查或内置模板列表异常时备用。

<details>
<summary><strong>展开查看全部 8 个模板的备用地址</strong></summary>

<br>

### 标准版

加速地址（`testingcf.jsdelivr.net`）：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash.ini
```

GitHub Raw 地址：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash.ini
```

<a id="标准-fallback-版"></a>

### 标准故障转移版

加速地址（`testingcf.jsdelivr.net`）：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Fallback.ini
```

GitHub Raw 地址：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Fallback.ini
```

### 轻量版

加速地址（`testingcf.jsdelivr.net`）：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Lite.ini
```

GitHub Raw 地址：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite.ini
```

<a id="轻量-fallback-版"></a>

### 轻量故障转移版

加速地址（`testingcf.jsdelivr.net`）：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Lite_Fallback.ini
```

GitHub Raw 地址：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite_Fallback.ini
```

### 极简 GFW 版

加速地址（`testingcf.jsdelivr.net`）：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_GFW.ini
```

GitHub Raw 地址：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW.ini
```

<a id="极简-gfw-fallback-版"></a>

### 极简 GFW 故障转移版

加速地址（`testingcf.jsdelivr.net`）：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_GFW_Fallback.ini
```

GitHub Raw 地址：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW_Fallback.ini
```

### 重度分流版

加速地址（`testingcf.jsdelivr.net`）：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Full.ini
```

GitHub Raw 地址：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full.ini
```

<a id="重度分流-fallback-版"></a>

### 重度分流故障转移版

加速地址（`testingcf.jsdelivr.net`）：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Full_Fallback.ini
```

GitHub Raw 地址：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full_Fallback.ini
```

</details>

## ✅ 最终验收

更新订阅后，至少确认：

- OpenClash 配置校验通过，Mihomo 内核正常启动；
- 节点订阅或 Proxy Provider 更新成功；
- 策略组、Rule Provider 和规则完整加载；
- DNS、IPv6、流量接管及实际分流符合预期；
- 日志中没有转换、下载、配置校验或内核错误。

## 📚 相关文档

- [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)
- [`yaml/` YAML 配置文件](./yaml/)
- [`overwrite/yaml/` 远程 YAML 覆写模块](../overwrite/yaml/)
- [项目 Wiki](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki)

---

<div align="center">

请以仓库 `main` 分支中的最新文件为准。

</div>
