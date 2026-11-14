# Rules

多平台分流规则集。由 GitHub Actions 每日两次（UTC 00:05 / 12:05）从上游源自动聚合 → 标准化 → 去重排序 → 转换为各客户端格式。

## 许可与上游署名

本仓库的聚合产物与构建脚本以 **AGPL-3.0** 发布（见 [LICENSE](LICENSE)）——取所用上游中最严格的许可，避免跨许可组合产生歧义。**这不是法律意见**，商用或再分发前请自行核对各上游条款。

规则内容来自下列上游，**各上游的著作权归其作者**：

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

每个产物文件头部都写有 `# 许可:` 与 `# 来源:`，订阅文件离开本仓库后仍可溯源。上游改动或新增源时，同步更新 `Merge.yml` 里的 `license_for()` 与本表。

## 订阅地址

```
https://raw.githubusercontent.com/justin0406/Rules/main/<平台>/<集合>.<后缀>
```

raw.githubusercontent.com 在部分网络下不可直连，可用 jsDelivr 镜像（同一内容，按 tag/分支缓存）：

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

> `Speedtest` 集合约 1.9 万条，其中约 85% 来自 kelee 的 `SpeedtestInternational.lsr`（各国 ISP 自建测速域名长尾）。只为常规测速需求订阅时可考虑跳过该集合。

## 平台能力差异

各平台支持的规则类型不同，构建时按平台裁剪/改写，下表为实际处理方式（依据各平台官方文档）：

| 规则类型 | Surge | Loon | QuantumultX | mihomo | Egern |
|---|:--:|:--:|:--:|:--:|:--:|
| `DOMAIN` / `DOMAIN-SUFFIX` / `DOMAIN-KEYWORD` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `DOMAIN-WILDCARD` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `IP-CIDR` / `IP-CIDR6` / `no-resolve` | ✅ | ✅ | ✅¹ | ✅ | ✅ |
| `IP-ASN` / `GEOIP` | ✅ | ✅ | ✅ | ✅ | ✅ |
| `PROCESS-NAME` | ✅ | ✅² | ❌ | ✅ | ❌³ |
| `USER-AGENT` | ✅ | ✅ | ✅ | ❌ | ✅ |
| `URL-REGEX` | ✅ | ✅ | ❌ | ❌ | ✅ |
| `AND` / `OR` / `NOT` | ✅ | ✅ | ❌ | ✅ | ❌³ |
| `extended-matching`（仅 Surge 专有） | ✅ | ❌ | ❌ | ❌ | ❌ |

¹ QuantumultX 不支持 `no-resolve`，构建时会移除。
² Loon 的进程规则仅在 macOS 生效，iOS / tvOS 会忽略。
³ Egern 无进程规则；`AND`/`OR`/`NOT` 的规则集字段（`and_set`/`or_set`/`not_set`）文档确认存在，但未给出可验证的嵌套写法，暂不产出。

通配符差异：Loon 的 `DOMAIN-WILDCARD` 支持 `*`、`?`、`[...]`（build 1008+），原样透传；mihomo 当前文档写明支持 `*` 与 `?`，构建时仍把含 `?` 的转成 `DOMAIN-REGEX`（语义等价，且兼容只认 `*` 的旧版本）；Egern 的 `domain_wildcard_set` 官方仅以 `*` 示例，含 `?` 的条目同样转为 `domain_regex_set`。

## 已停止产出

- **Shadowrocket**（2026-10-28 起）：该客户端没有公开的官方规则语法文档，无法验证适配是否正确，不再维护。
- **Stash**（2026-10-28 起）：不再产出。

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

上游没有、但需要长期存在的条目，写成 `.github/sources/<集合名>.list`，然后在 `Merge.yml` 对应集合的源表里加一行引用：

```
Speedtest)
  cat <<'EOF'
https://ruleset.skk.moe/List/domainset/speedtest.conf
https://git.repcz.link/kelee.one/Tool/Loon/Lsr/SpeedtestInternational.lsr
local:.github/sources/Speedtest.list
EOF
```

`local:` 是本地源的写法（路径相对仓库根）。它和上游源走**同一条**流水线：一样参与标准化、去重、排序，重复条目不会产生冗余；区别只是不下载、不进 `upstream-cache` 快照——内容本来就跟 git 一起版本化了。文件不存在或为空会直接构建失败，不会静默略过。

目前已有的本地源：

| 文件 | 内容 |
|---|---|
| `.github/sources/Speedtest.list` | `DOMAIN,speed.skk.moe`（skk 自建测速页，上游 `speedtest.conf` 未收录） |
| `.github/sources/AppleCN.list` | Apple ID 认证域名（`appleid` / `gsa` / `idmsa` / `account` / `albert`，上游已有 `DOMAIN-SUFFIX,apple.com` 覆盖，此处兜底 + 显式化） |
| `.github/sources/Direct.list` | 中国 AI 服务商的国内站（21 条后缀）。**Direct 集合需放在配置的最高优先级**，详见下节 |
| `.github/sources/Direct-CDN.list` | CDN 集合中「直连安全」的子集（1751 条，双重实测确认）。Direct 排在 CDN 之前时，这部分走直连省带宽，CDN 集合其余约 1/3 被墙/污染条目继续走原有策略 |

### 中国 AI 服务的直连 / 代理分界

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

判定依据：对每个域名分别用国内 DNS（阿里 223.5.5.5）与国外 DNS（Cloudflare 1.1.1.1）解析，再用本仓库 `ChinaIP` 网段判定归属，**并在中国大陆宽带下直连实测可达性与延迟**。`z.ai` 虽无国内 GeoDNS 节点（国内外 DNS 都解析到阿里云国际 8.216.131.x），但移动宽带实测直连 0.33~0.62s 稳定（CMI 对阿里国际链路有优化），与代理持平，故走直连；`kimi.ai` / `moonshot.ai` / `minimax.io` 等国际站直连 0.5~3.5s 且抖动大，走代理。

阿里 / 百度 / 腾讯 / 字节主站（`aliyuncs.com` `baidu.com` `tencent.com` `bytedance.com` 等）已被 `CN` 集合覆盖，未在 `Direct` 重复登记。

> **集合间存在匹配重叠，先后顺序决定行为，务必按此排列：**
>
> 1. **`Direct` 必须排在 `AI` 之前。** 上游 `AI` 集合也有 `DOMAIN-SUFFIX,z.ai`（走代理），与本仓库 `Direct` 的同一条目冲突——`z.ai` 及其全部子域谁生效完全取决于顺序；同理 `Direct` 的 `mchost.guru` / `longcat.chat` 后缀会捕获 `AI` 里的 `trae-api-sg` / `api.longcat.chat`。
> 2. **`Direct` 必须排在 `CDN` 之前。** `Direct-CDN` 本地源（1751 条实测可直连的 CDN 域名）与 CDN 集合天然重叠，Direct 在前时这部分走直连，其余 CDN 条目继续走 CDN 的策略。
> 3. **`AppleCN` 必须排在 `AppleProxy` 之前。** AppleProxy 里有 33 条 iTunes/开发者 CDN 类条目会被 AppleCN 覆盖（顺序对则直连，符合设计）；反过来 AppleCN 里 apps / updates.cdn-apple 等 20 条也被 AppleProxy 的后缀覆盖——顺序错了这些 Apple 国内服务会绕道代理（苹果认证/激活对出口 IP 敏感，实测走代理会 503）。

> **`Direct` 集合里的「不可达域名」是设计要求，不是错误。** 上游 direct.conf 含三类特殊条目：内网/保留域名（`lan`、`*.in-addr.arpa`、`tplinkwifi.net`、`router.asus.com` 等——让路由器管理页和本地服务不走代理）、PT/私有种子站（`m-team.cc`、`chdbits.co` 等——PT 规则明令禁止代理访问，直连防封号）、校园 IPv6 站（`bt.neu6.edu.cn` 等）。2026-11-14 全量直连实测确认这三类直连均正确，勿删。

## 维护

改 `.github/workflows/Merge.yml` 即可。bash 基线为 4+：CI 用 ubuntu-24.04 自带的 bash 5.x，本地复跑用 `brew install bash` 后的 `/opt/homebrew/bin/bash`（macOS 自带的仍是 3.2）。推送前有 Lint 环节拦截格式、字段数、头部计数、平台越权选项与许可署名缺失问题。

产物头部（规则名称 / 统计 / 许可 / 来源）由 `scripts/rulehdr.sh` 统一生成，五个平台共用同一份实现——改头部格式只改这一个文件。新增上游源时记得在 `Merge.yml` 的 `license_for()` 与 README 的许可表里同时登记。
