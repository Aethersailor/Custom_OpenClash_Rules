<div align="center">

# 🧩 OpenClash 订阅转换模板

**8 个已被 OpenClash 收录的 `.ini` 模板**

[使用方法](#-使用订阅转换模板) · [模板列表](#-模板列表) · [版本区别](#-版本区别) · [其他配置方式](#-其他配置方式) · [备用链接](#-备用远程链接)

</div>

---

> [!IMPORTANT]
> 本目录根层存放 `.ini` 订阅转换模板。全部 8 个模板均已被 OpenClash 收录，常规使用建议直接在 OpenClash 内置模板列表中选择，无需手工填写模板地址。
>
> YAML 配置文件请查看 [`yaml/`](./yaml/)；通过远程覆写模块调用 YAML，请查看 [`../overwrite/yaml/`](../overwrite/yaml/)。

## 🔄 使用订阅转换模板

1. 先按照项目 Wiki 的 [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)完成插件设置。
2. 进入 OpenClash 订阅管理，新增或编辑订阅。
3. 启用在线订阅转换。
4. 在模板列表中搜索并选择对应的 `Aethersailor 规则` 模板。
5. 保存并更新订阅。
6. 检查配置校验、内核启动、Provider、策略组和实际分流。

OpenClash 收录的是本仓库模板的远程地址，模板内容仍由本项目维护。仓库更新后，后续订阅转换会使用最新模板。

> [!NOTE]
> `.ini` 文件是订阅转换模板，不能直接作为 OpenClash 运行配置上传。

### 关于转换后端

订阅转换会将订阅地址和转换参数发送给所选后端。公共后端的稳定性、兼容性和隐私不由本项目控制；重视可靠性或隐私时，可以使用自建兼容后端。

## 📁 模板列表

本目录包含 4 个普通版及其 Fallback 版，共 8 个模板：

| 版本 | 文件 | 定位 |
| --- | --- | --- |
| 标准版 | [`Custom_Clash.ini`](./Custom_Clash.ini) | 日常分流与复杂度均衡，建议多数用户优先选择 |
| 标准 Fallback 版 | [`Custom_Clash_Fallback.ini`](./Custom_Clash_Fallback.ini) | 标准版分流结构，主要业务组自动故障转移 |
| 轻量版 | [`Custom_Clash_Lite.ini`](./Custom_Clash_Lite.ini) | 策略组较少，结构简洁，维护成本较低 |
| 轻量 Fallback 版 | [`Custom_Clash_Lite_Fallback.ini`](./Custom_Clash_Lite_Fallback.ini) | 轻量结构与自动故障转移结合 |
| 极简 GFW 版 | [`Custom_Clash_GFW.ini`](./Custom_Clash_GFW.ini) | 主要处理 GFW 相关流量，其余流量默认直连 |
| 极简 GFW Fallback 版 | [`Custom_Clash_GFW_Fallback.ini`](./Custom_Clash_GFW_Fallback.ini) | 极简分流与自动故障转移结合 |
| 重度分流版 | [`Custom_Clash_Full.ini`](./Custom_Clash_Full.ini) | 业务、地区和节点用途分组更丰富 |
| 重度分流 Fallback 版 | [`Custom_Clash_Full_Fallback.ini`](./Custom_Clash_Full_Fallback.ini) | 重度分流结构与自动故障转移结合 |

## 📊 版本区别

| 系列 | 特点 | 建议 |
| --- | --- | --- |
| **标准版** | 常用业务覆盖与复杂度均衡 | 不确定时优先选择 |
| **轻量版** | 策略组更少，结构更简洁 | 重视低维护成本 |
| **极简 GFW 版** | 主要代理 GFW 相关流量 | 只需要基础分流 |
| **重度分流版** | 业务、地区和节点用途分类最多 | 节点丰富并需要精细选路 |

### 普通版与 Fallback 版

- **普通版：** 主要业务策略组使用 `select`，便于手工选择出口。
- **Fallback 版：** 主要业务策略组使用 `fallback`，按候选顺序检测并自动切换。

> [!WARNING]
> Fallback 只判断健康检查地址是否可达，不能判断节点是否具备流媒体、AI 服务或特定地区的解锁能力。

## 🧭 其他配置方式

除订阅转换外，本项目还提供两种使用同一套配置的方式：

| 方式 | 入口 |
| --- | --- |
| 远程 YAML 覆写模块 | [`../overwrite/yaml/`](../overwrite/yaml/) |
| 下载并手工导入 YAML | [`yaml/`](./yaml/) |

> [!IMPORTANT]
> 选择相同配置版本且未自行修改内容时，订阅转换、远程 YAML 覆写模块和手工导入 YAML 的**策略组结构、规则引用、规则顺序和分流逻辑完全对齐**。三者的差别仅在配置的获取和维护方式。

三种方式通常选择一种作为主路径，不建议同时反复替换同一份当前配置。

## 🔗 备用远程链接

常规 OpenClash 用户无需手工填写以下地址。它们主要用于自建订阅转换后端、其他兼容工具、兼容性排查，或内置模板列表异常时备用。

<details>
<summary><strong>展开查看全部 8 个模板的备用地址</strong></summary>

<br>

### 标准版

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash.ini
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash.ini
```

### 标准 Fallback 版

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Fallback.ini
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Fallback.ini
```

### 轻量版

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Lite.ini
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite.ini
```

### 轻量 Fallback 版

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Lite_Fallback.ini
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Lite_Fallback.ini
```

### 极简 GFW 版

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_GFW.ini
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW.ini
```

### 极简 GFW Fallback 版

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_GFW_Fallback.ini
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_GFW_Fallback.ini
```

### 重度分流版

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Full.ini
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full.ini
```

### 重度分流 Fallback 版

testingcf：

```text
https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/cfg/Custom_Clash_Full_Fallback.ini
```

GitHub Raw：

```text
https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/cfg/Custom_Clash_Full_Fallback.ini
```

</details>

## ✅ 最终验收

更新订阅后，至少确认：

- OpenClash 配置检查通过，Mihomo 内核正常启动；
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
