# Rules

多平台分流规则集。由 GitHub Actions 每日两次（UTC 00:05 / 12:05）从上游源自动聚合 → 标准化 → 去重排序 → 转换为各客户端格式。

## 订阅地址

```
https://raw.githubusercontent.com/justin0406/Rules/main/<平台>/<集合>.<后缀>
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
³ Egern 无进程规则；`AND`/`OR`/`NOT` 官方文档未给出规则集内可验证的嵌套写法，暂不产出。

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

## 维护

改 `.github/workflows/Merge.yml` 即可。bash 基线为 4+：CI 用 ubuntu-24.04 自带的 bash 5.x，本地复跑用 `brew install bash` 后的 `/opt/homebrew/bin/bash`（macOS 自带的仍是 3.2）。推送前有 Lint 环节拦截格式、字段数、头部计数与平台越权选项问题。
