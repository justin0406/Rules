# Rules

多平台分流规则集。由 GitHub Actions 每日两次（UTC 00:05 / 12:05）从上游源自动聚合 → 标准化 → 去重排序 → 转换为各客户端格式。

产物共 5 个平台 × 10 个集合 = 50 个文件，均带 `# 规则名称` / `# 规则统计` / `# 许可` / `# 来源` 头部。

## 订阅地址

```
https://raw.githubusercontent.com/justin0406/Rules/main/<平台>/<集合>.<后缀>
```

raw.githubusercontent.com 在部分网络下不可直连，可用 jsDelivr 镜像（同一内容，按分支缓存）：

```
https://cdn.jsdelivr.net/gh/justin0406/Rules@main/<平台>/<集合>.<后缀>
```

| 平台 | 目录 | 后缀 |
|---|---|---|
| Surge | `Surge/` | `.list` |
| Loon | `Loon/` | `.list` |
| QuantumultX | `QuantumultX/` | `.list` |
| mihomo | `mihomo/` | `.list` |
| Egern | `Egern/` | `.yaml` |

规则集合（10 个）：`AI` `AppleCN` `AppleProxy` `CDN` `CN` `ChinaIP` `Direct` `GFW` `Speedtest` `TG`

例：`https://raw.githubusercontent.com/justin0406/Rules/main/Surge/AI.list`

### 集合规模与构成（2026-11-14 实测值）

| 集合 | 条目数 | 说明 |
|---|---:|---|
| `ChinaIP` | 11,996 | 中国大陆 IPv4/IPv6 网段 |
| `Speedtest` | 19,296 | 各国 ISP 测速端点，**95.9% 来自 kelee 的 `SpeedtestInternational.lsr`**（其中 81.9% 为该源独有，其余与 skk 重合）。只为常规测速需求可跳过此集合 |
| `GFW` | 8,257 | 常见被墙域名 |
| `CDN` | 4,786 | 全球 CDN 域名；约 1/3 在国内直连不可达（见 `Direct-CDN`） |
| `Direct` | 1,992 | 直连集合，含 skk 上游 + 本仓库本地源 |
| `CN` | 878 | 国内常用域名 |
| `AI` | 330 | AI 服务域名（走代理） |
| `AppleCN` | 298 | Apple 中国区服务 |
| `AppleProxy` | 83 | Apple 需代理的服务（Private Relay / News 等） |
| `TG` | 34 | Telegram |

## 平台能力差异

各平台支持的规则类型不同，构建时按平台裁剪/改写。下表经产物审计确认（非照抄文档）：

| 规则类型 | Surge | Loon | QuantumultX | mihomo | Egern |
|---|:--:|:--:|:--:|:--:|:--:|
| `DOMAIN` / `DOMAIN-SUFFIX` / `DOMAIN-KEYWORD` | ✅ | ✅ | ✅¹ | ✅ | ✅ |
| `DOMAIN-WILDCARD` | ✅ | ✅ | ✅¹ | ✅² | ✅³ |
| `IP-CIDR` / `IP-CIDR6` / `no-resolve` | ✅ | ✅ | ✅⁴ | ✅ | ✅⁵ |
| `IP-ASN` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `GEOIP` | ✅ | ✅ | ✅ | ✅ | ✅⁶ |
| `PROCESS-NAME` | ✅ | ✅⁷ | ❌ | ✅ | ❌ |
| `USER-AGENT` | ✅ | ✅ | ✅⁸ | ❌ | ✅ |
| `URL-REGEX` | ✅ | ✅ | ❌ | ❌ | ✅ |
| `AND` / `OR` / `NOT` | ✅ | ✅ | ❌ | ✅ | ❌⁹ |
| `extended-matching`（Surge 专有） | ✅ | ❌ | ❌ | ❌ | ❌ |

¹ QuantumultX 用 `HOST` / `HOST-SUFFIX` / `HOST-KEYWORD` / `HOST-WILDCARD` 命名，构建时自动改写。
² mihomo 支持 `DOMAIN-WILDCARD`，但构建时仍把含 `?` 的转为 `DOMAIN-REGEX`（语义等价，且兼容只认 `*` 的旧版本）。
³ Egern 的 `domain_wildcard_set` 官方仅以 `*` 示例，含 `?` 的条目转为 `domain_regex_set`。
⁴ QuantumultX 不支持 `no-resolve`，构建时移除；`IP-CIDR6` 改写为 `IP6-CIDR`。
⁵ Egern 用顶层 `no_resolve: true`，仅对 IP 类规则生效。
⁶ Egern 的 `geoip_set` 已映射支持；本次产物中无 GEOIP 条目，故未实际产出，表格按构建逻辑标注。
⁷ Loon 的进程规则仅在 macOS 生效，iOS / tvOS 会忽略。
⁸ QuantumultX 的 `USER-AGENT` 需第三段策略名（构建时注入）。
⁹ Egern 的 `and_set` / `or_set` / `not_set` 字段存在，但官方未给出可验证的嵌套写法，暂不产出。

Loon 的 `DOMAIN-WILDCARD` 支持 `*`、`?`、`[...]`（build 1008+），原样透传。

## 集合排序依赖（重要）

多个集合之间存在匹配重叠，**配置里规则集的引用顺序决定最终行为**。实测确认的依赖关系：

| 顺序要求 | 原因 |
|---|---|
| **`Direct` 在 `AI` 之前** | 上游 `AI` 也有 `DOMAIN-SUFFIX,z.ai`（走代理），与本仓库 `Direct` 的同一条目冲突；`Direct` 的 `mchost.guru` / `longcat.chat` 后缀还会捕获 `AI` 里的 `trae-api-sg` / `api.longcat.chat` |
| **`Direct` 在 `CDN` 之前** | `Direct-CDN` 本地源（1,751 条实测可直连的 CDN 域名）与 CDN 集合天然重叠；Direct 在前时这部分走直连，其余 CDN 条目继续走 CDN 策略 |
| **`AppleCN` 在 `AppleProxy` 之前** | AppleProxy 有 33 条 iTunes/开发者 CDN 条目会被 AppleCN 覆盖（顺序对则直连，符合设计）；反向地 AppleCN 里 `apps` / `updates.cdn-apple` 等 20 条也会被 AppleProxy 后缀覆盖——顺序错了 Apple 国内服务会绕道代理（认证/激活对出口 IP 敏感，走代理实测 503） |

### `Direct` 集合里的「不可达域名」是设计要求

上游 `direct.conf` 含三类**故意直连**的条目，直连实测不可达属正常，**勿当作死条目清理**：

- **内网 / 保留域名**：`lan`、`*.in-addr.arpa`、`tplinkwifi.net`、`router.asus.com` 等——让路由器管理页与本地服务不走代理
- **PT / 私有种子站**：`m-team.cc`、`chdbits.co` 等——PT 规则明令禁止代理访问，直连防封号
- **校园 IPv6 站**：`bt.neu6.edu.cn` 等——IPv4 探测不可达但 IPv6 正常

## 中国 AI 服务的直连 / 代理分界

中国厂商普遍是「国内站 + 国际站」双轨，不能按厂商名一刀切：

| 厂商 | 国内站（直连，在 `Direct`） | 国际站（走代理，在 `AI`） |
|---|---|---|
| 智谱 | `z.ai`（国际站，实测直连可用） `bigmodel.cn` `chatglm.cn` | — |
| 月之暗面 | `moonshot.cn` `kimi.com` | `kimi.ai` `moonshot.ai` |
| DeepSeek | `deepseek.com` | — |
| MiniMax | `minimaxi.com` `hailuoai.com` | `minimax.io` |
| 阶跃星辰 | `stepfun.com` | `stepfun.ai` |
| 硅基流动 | `siliconflow.cn` | `siliconflow.com` |
| 美团 / 字节 | `longcat.chat` `trae.cn` `mchost.guru` | `trae.ai` |

判定依据：对每个域名分别用国内 DNS（阿里 223.5.5.5）与国外 DNS（Cloudflare 1.1.1.1）解析，用本仓库 `ChinaIP` 网段判定归属，**并在中国大陆宽带下直连实测可达性与延迟**。`z.ai` 虽无国内 GeoDNS 节点（国内外都解析到阿里云国际 8.216.131.x），但移动宽带实测直连 0.33~0.62s 稳定（CMI 对阿里国际链路有优化），与代理持平，故走直连；`kimi.ai` / `moonshot.ai` / `minimax.io` 等国际站直连 0.5~3.5s 且抖动大，走代理。

阿里 / 百度 / 腾讯 / 字节主站（`aliyuncs.com` `baidu.com` `tencent.com` `bytedance.com` 等）已被 `CN` 集合覆盖，未在 `Direct` 重复登记。

## 许可与上游署名

本仓库的聚合产物与构建脚本以 **AGPL-3.0** 发布（见 [LICENSE](LICENSE)）——采用所用上游中最严格的许可，避免跨许可组合产生歧义。**这不是法律意见**，商用或再分发前请自行核对各上游条款。

规则内容来自下列上游，**各上游著作权归其作者**：

| 上游 | 许可 | 用于 |
|---|---|---|
| [SukkaW/Surge](https://github.com/SukkaW/Surge)（ruleset.skk.moe） | AGPL-3.0；`ip/china_ip.conf` 为 CC BY-SA 2.0 | CN / CDN / ChinaIP / TG / GFW / Speedtest / AI / AppleCN / Direct |
| [Loyalsoldier/surge-rules](https://github.com/Loyalsoldier/surge-rules) | GPL-3.0 | ChinaIP / GFW |
| [ACL4SSR/ACL4SSR](https://github.com/ACL4SSR/ACL4SSR) | CC BY-SA 4.0 | GFW |
| [blackmatrix7/ios_rule_script](https://github.com/blackmatrix7/ios_rule_script) | GPL-2.0 | AppleProxy |
| [Elysian-Realme/FuGfConfig](https://github.com/Elysian-Realme/FuGfConfig) | MIT | AppleCN / AppleProxy |
| [fmz200/wool_scripts](https://github.com/fmz200/wool_scripts) | GPL-3.0 | AI |
| [EAlyce/conf](https://github.com/EAlyce/conf) | MIT | AI |
| [kelee.one/Tool](https://git.repcz.link/kelee.one/Tool) | 未声明 | AI / Speedtest |

每个产物头部都写有 `# 许可:` 与 `# 来源:`，订阅文件离开本仓库后仍可溯源。新增或更换上游时，同步修改 `Merge.yml` 的 `license_for()` 与本表。

## 构建流水线

`Merge.yml` 共 13 个步骤，以下几项机制值得了解：

### 上游降级（`.github/upstream-cache/`）

每个上游 URL 在 `.github/upstream-cache/` 有一份「最近一次成功」的快照，由 `manifest.tsv` 记录状态：

- 抓取成功 → 覆盖快照，更新时间戳
- 抓取失败 / 返回 HTML 挑战页 → 沿用快照继续构建，源在 manifest 中标记降级，并在 job summary 与提交消息里留痕
- 抓取失败且**没有**快照（新增源从未成功过）→ 直接失败，不猜内容
- 内容未变则保留旧时间戳，避免产生「只改时间」的空提交

### 回归闸门

Lint 会把本次产物与 `HEAD`（上一版）逐文件比对条目数：

- 单文件跌幅 > 10% → 失败（疑似上游异常）
- 单文件跌幅 > 5% → 警告
- 平台合计跌幅 > 5% → 失败
- **扣除上一版的重复条目**后再比，避免「修复去重」被自身误判为上游异常

### 产物 Lint

推送前校验：字段结构与平台越权选项、域名/WILDCARD 字符集、头部计数与实际条目数一致、Egern YAML 可解析、每个集合在每个平台都有产出、**`# 许可:` / `# 来源:` 缺失即失败**。

### 历史清理

`ClearCommits.yml`（仅手动触发，`workflow_dispatch`）把历史重建为单提交，同时删除旧的运行记录。与 `Merge` 共用 `concurrency: repo-write` 排队，避免 force-push 与自动构建竞态。

## 本地验证

改完 workflow 或规则源，推送前跑一次：

```
scripts/verify.sh
```

它做三件事：`actionlint`（含 `shellcheck`，校验 workflow 语义与内嵌脚本）→ 在临时副本里按顺序跑一遍构建 → 报告「推送后 CI 会提交哪些文件」。**不碰当前工作区**：构建在临时目录进行，失败也不会留下半成品。

```
scripts/verify.sh -q    # 只看结论
scripts/verify.sh -k    # 保留临时目录，排查用
```

依赖：`bash` 4+、`actionlint`、`shellcheck`、`curl`、`python3`（Lint 需要 PyYAML，缺失时脚本自建 venv）。

## 本地规则源

上游没有、但需要长期存在的条目，写成 `.github/sources/<名称>.list`，然后在 `Merge.yml` 对应集合的源表里加一行 `local:` 引用：

```
Speedtest)
  cat <<'EOF'
https://ruleset.skk.moe/List/domainset/speedtest.conf
https://git.repcz.link/kelee.one/Tool/Loon/Lsr/SpeedtestInternational.lsr
local:.github/sources/Speedtest.list
EOF
```

`local:` 路径相对仓库根。它和上游源走**同一条**流水线：一样参与标准化、去重、排序，重复条目不会产生冗余；区别只是不下载、不进 `upstream-cache` 快照——内容本来就跟 git 一起版本化。文件不存在或为空会直接构建失败，不会静默略过。

目前的本地源：

| 文件 | 条目 | 内容 |
|---|---:|---|
| `.github/sources/Speedtest.list` | 2 | `DOMAIN,speed.skk.moe`（skk 自建测速页）+ `DOMAIN-SUFFIX,radar.cloudflare.com`（Cloudflare Radar 测速）——上游均未收录 |
| `.github/sources/AppleCN.list` | 5 | Apple ID 认证域名（`appleid` / `gsa` / `idmsa` / `account` / `albert`）。上游已有 `DOMAIN-SUFFIX,apple.com` 覆盖，此处作兜底与显式化 |
| `.github/sources/Direct.list` | 21 | 中国 AI 服务商国内站（全为 `DOMAIN-SUFFIX`），判定依据见上节 |
| `.github/sources/Direct-CDN.list` | 1,751 | CDN 集合中「直连安全」子集（`DOMAIN` 1,507 + `DOMAIN-SUFFIX` 244）。2026-11-14 两轮独立实测确认（`<1.5s`），92 个单轮通过但复测失败的抖动域名已剔除 |

> `Direct-CDN.list` 是网络实测快照，会随时间与网络环境过期。建议每隔数月用同样方法（国内 DNS 与国外 DNS 对比 + 大陆宽带直连实测）复核。

## 已停止产出

- **Shadowrocket**（2026-10-28 起）：该客户端无公开的官方规则语法文档，无法验证适配是否正确，不再维护。
- **Stash**（2026-10-28 起）：不再产出。

## 维护

改 `.github/workflows/Merge.yml` 即可。bash 基线为 4+：CI 用 ubuntu-24.04 自带的 bash 5.x，本地复跑用 `brew install bash` 后的 `/opt/homebrew/bin/bash`（macOS 自带仍是 3.2）。

产物头部（规则名称 / 统计 / 许可 / 来源）由 `scripts/rulehdr.sh` 统一生成，五个平台共用同一份实现——改头部格式只改这一个文件。新增上游源时记得同步 `Merge.yml` 的 `license_for()` 与本文档的许可表。

`actions/checkout` / `Mattraks/delete-workflow-runs` 等 Action 由 Dependabot 每日检查更新（`.github/dependabot.yml`），均以 commit SHA 固定。
