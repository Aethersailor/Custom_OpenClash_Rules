<div align="center">

# 🌐 远程 YAML 覆写模块

**填写模块变量，自动下载对应 YAML、写入订阅并切换配置**

[模块列表](#-模块列表) · [如何选择](#-如何选择) · [使用方法](#%EF%B8%8F-使用方法) · [参数说明](#-参数说明) · [订阅链接](#-全部模块订阅链接)

</div>

---

> [!IMPORTANT]
> 使用本目录模块前，先按照项目 Wiki 的 [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)完成 LuCI 设置。模块负责调用远程 YAML 和写入订阅地址，不负责替你配置 DNS、IPv6、TUN、嗅探及其他插件运行参数。
>
> 如需了解被调用 YAML 的策略组、规则和版本区别，请先阅读 [`../../cfg/yaml/`](../../cfg/yaml/)。

## 🧭 它属于三种路径中的哪一种

本项目建议先配置 LuCI，再从以下三种路径中三选一：

1. 订阅转换 + `.ini` 模板；
2. **本目录的远程 YAML 覆写模块**；
3. 下载 YAML 手工修改并导入。

覆写模块适合希望避开订阅转换后端、又不想手工维护 YAML 的用户。它比手工导入简单，但需要理解模块地址、`EN_KEY` 变量和 OpenClash 覆写执行结果。

> [!NOTE]
> 模块最终调用的仍是本项目 YAML，因此同样基于维护者推定的典型使用场景。需要完全个性化时，请手工修改或自行编写 YAML。

## 📦 模块列表

| 功能 | 模块文件 | 调用目标 | 模块变量 |
| --- | --- | --- | --- |
| 标准版 | [`Custom_Clash.conf`](./Custom_Clash.conf) | `Custom_Clash.yaml` | `EN_KEY1`：节点订阅链接 |
| 标准 Fallback 版 | [`Custom_Clash_Fallback.conf`](./Custom_Clash_Fallback.conf) | `Custom_Clash_Fallback.yaml` | `EN_KEY1`：节点订阅链接 |
| 轻量版 | [`Custom_Clash_Lite.conf`](./Custom_Clash_Lite.conf) | `Custom_Clash_Lite.yaml` | `EN_KEY1`：节点订阅链接 |
| 轻量 Fallback 版 | [`Custom_Clash_Lite_Fallback.conf`](./Custom_Clash_Lite_Fallback.conf) | `Custom_Clash_Lite_Fallback.yaml` | `EN_KEY1`：节点订阅链接 |
| 极简 GFW 版 | [`Custom_Clash_GFW.conf`](./Custom_Clash_GFW.conf) | `Custom_Clash_GFW.yaml` | `EN_KEY1`：节点订阅链接 |
| 极简 GFW Fallback 版 | [`Custom_Clash_GFW_Fallback.conf`](./Custom_Clash_GFW_Fallback.conf) | `Custom_Clash_GFW_Fallback.yaml` | `EN_KEY1`：节点订阅链接 |
| 重度分流版 | [`Custom_Clash_Full.conf`](./Custom_Clash_Full.conf) | `Custom_Clash_Full.yaml` | `EN_KEY1`：节点订阅链接 |
| 重度分流 Fallback 版 | [`Custom_Clash_Full_Fallback.conf`](./Custom_Clash_Full_Fallback.conf) | `Custom_Clash_Full_Fallback.yaml` | `EN_KEY1`：节点订阅链接 |
| 8 合 1 | [`Custom_Clash_8in1.conf`](./Custom_Clash_8in1.conf) | `8 个常规 YAML 可选` | `EN_KEY1`：节点订阅；`EN_KEY2`：配置名称 |
| 自建节点 Provider 优先版 | [`Custom_Clash_Selfhosted_Provider_Fallback.conf`](./Custom_Clash_Selfhosted_Provider_Fallback.conf) | `Custom_Clash_Selfhosted_Provider_Fallback.yaml` | `EN_KEY1`：机场订阅；`EN_KEY2`：自建节点订阅 |

### 模块实际执行的操作

启用后，模块会：

1. 从 testingcf 下载对应的远程 YAML 到 `/etc/openclash/config/`；
2. 将该 YAML 设为模块处理的配置文件；
3. 使用 `ruby_map_edit` 把 `EN_KEY` 写入相应 `proxy-providers.*.url`；
4. 设置订阅信息 URL；
5. 应用配置并触发 OpenClash 重启。

模块不会修改仓库中的远程 YAML，也不会把你的订阅地址上传回本项目。

## 🎯 如何选择

### 单独模块

文件名与 YAML 一一对应，只需填写 `EN_KEY1`。优点是配置固定、参数最少，不容易选错。

**建议：** 已经确定长期使用某个版本时选择。

### 8 合 1 模块

`Custom_Clash_8in1.conf` 可以调用 8 个常规 YAML。通过 `EN_KEY2` 选择版本，留空时默认使用 `Custom_Clash`。

**建议：** 经常在标准、Lite、GFW、Full 及其 Fallback 版本之间切换时选择。

### 自建节点 Provider 版

`Custom_Clash_Selfhosted_Provider_Fallback.conf` 同时写入机场订阅和自建节点订阅，并调用 `Custom_Clash_Selfhosted_Provider_Fallback.yaml`。

**建议：** 自建节点作为主线路、机场作为后备，且自建节点已经整理为 HTTP Provider 或订阅 URL 时选择。

> [!CAUTION]
> 手工自建节点版 `Custom_Clash_Selfhosted_Manual_Fallback.yaml` 没有对应通用模块。其协议字段和凭据需要自行编辑，详见 [`../../cfg/yaml/`](../../cfg/yaml/)。

## ⚙️ 使用方法

不同 OpenClash 版本的菜单名称可能略有差异，基本流程如下：

1. 先按 Wiki 完成 OpenClash LuCI 设置并备份当前可用配置。
2. 进入 OpenClash 的 **覆写设置 / 覆写模块** 页面。
3. 新增远程模块，类型选择 `HTTP`。
4. 从[全部模块订阅链接](#-全部模块订阅链接)复制模块地址。中国大陆网络通常优先使用 jsDelivr 加速链接，GitHub Raw 链接可作备用。
5. 在模块变量或参数栏填写对应的 `EN_KEY`。
6. 启用模块，保存并应用配置。
7. 等待模块下载 YAML、写入 Provider 地址并重启。
8. 检查配置文件、Provider、策略组和日志，完成最终验收。

> [!WARNING]
> 模块启用后会下载并覆盖 `/etc/openclash/config/` 下的同名 YAML。不要直接在该同名文件中长期保存手工修改，否则下一次执行模块时可能被覆盖。

## 🔑 参数说明

### 8 个单独模块

只需填写：

```text
EN_KEY1=https://example.com/subscription
```

`EN_KEY1` 会写入 `proxy-providers.provider1.url`。

### 8 合 1 模块

```text
EN_KEY1=https://example.com/subscription;EN_KEY2=Custom_Clash_Lite_Fallback
```

`EN_KEY2` 只允许以下值：

```text
Custom_Clash
Custom_Clash_Fallback
Custom_Clash_Lite
Custom_Clash_Lite_Fallback
Custom_Clash_GFW
Custom_Clash_GFW_Fallback
Custom_Clash_Full
Custom_Clash_Full_Fallback
```

`EN_KEY2` 留空时默认调用 `Custom_Clash.yaml`。

### 自建节点 Provider 模块

```text
EN_KEY1=https://example.com/airport-subscription;EN_KEY2=https://example.com/selfhost-provider
```

- `EN_KEY1` 写入机场 `provider1.url`；
- `EN_KEY2` 写入自建节点 `selfhost.url`。

`EN_KEY2` 必须是 Mihomo 可识别且可通过 HTTP 获取的节点订阅或 Provider 文件，不能直接填写单条节点 URI。

## 🔐 隐私与更新行为

- 订阅 URL 通常包含访问凭据，截图、导出配置和分享日志前应脱敏。
- 模块变量保存在你的 OpenClash 环境中；远程模块文件本身不包含你的订阅。
- 模块每次执行都会获取仓库当前 YAML，远程更新可能在下次应用或重启时生效。
- 需要固定版本时，应自行托管模块和 YAML，或改用手工下载导入。
- 同时启用多个会切换 `CONFIG_FILE` 的模块可能相互覆盖，不建议并行启用多个本目录模块。

## 🔗 全部模块订阅链接

### 标准版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash.conf
  ```

### 标准 Fallback 版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_Fallback.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_Fallback.conf
  ```

### 轻量版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_Lite.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_Lite.conf
  ```

### 轻量 Fallback 版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_Lite_Fallback.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_Lite_Fallback.conf
  ```

### 极简 GFW 版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_GFW.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_GFW.conf
  ```

### 极简 GFW Fallback 版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_GFW_Fallback.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_GFW_Fallback.conf
  ```

### 重度分流版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_Full.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_Full.conf
  ```

### 重度分流 Fallback 版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_Full_Fallback.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_Full_Fallback.conf
  ```

### 8 合 1

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_8in1.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_8in1.conf
  ```

### 自建节点 Provider 优先版

- GitHub Raw 链接：

  ```text
  https://raw.githubusercontent.com/Aethersailor/Custom_OpenClash_Rules/refs/heads/main/overwrite/yaml/Custom_Clash_Selfhosted_Provider_Fallback.conf
  ```

- jsDelivr 加速链接：

  ```text
  https://testingcf.jsdelivr.net/gh/Aethersailor/Custom_OpenClash_Rules@refs/heads/main/overwrite/yaml/Custom_Clash_Selfhosted_Provider_Fallback.conf
  ```


## ✅ 最终验收

应用模块后确认：

- 模块下载和 Ruby 覆写过程无报错；
- `/etc/openclash/config/` 中生成了预期 YAML；
- Provider URL 已正确写入且更新成功；
- 策略组、地区分组和规则集正常加载；
- OpenClash 内核重启成功，DNS、IPv6 和流量接管符合 LuCI 设置；
- 直连、代理及 Fallback 行为符合预期；
- 保留一份已验证配置和模块参数用于回退。

## 📚 相关文档

- [OpenClash 设置方案](https://github.com/Aethersailor/Custom_OpenClash_Rules/wiki/OpenClash-%E8%AE%BE%E7%BD%AE%E6%96%B9%E6%A1%88)
- [`cfg/` 订阅转换模板与三种路径](../../cfg/)
- [`cfg/yaml/` YAML 文件详解](../../cfg/yaml/)
- [`overwrite/` 其他覆写模块](../)

---

<div align="center">

建议一次只启用一个本目录模块，并在每次切换后重新验收。

</div>
