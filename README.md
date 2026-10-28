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

## 补充规则

上游没有、但需要长期存在的条目，写在 `.github/extra/<集合名>.list`（例如 `.github/extra/Speedtest.list`）。构建时按文件名追加到同名上游集合，再统一去重排序，因此与上游重复不会产生冗余；文件名必须与工作流里的集合同名，否则构建直接报错。

目前已有的补充：

| 集合 | 条目 | 原因 |
|---|---|---|
| Speedtest | `DOMAIN,speed.skk.moe` | skk.moe 自建测速页，上游 `speedtest.conf` 未收录 |

## 维护

改 `.github/workflows/Merge.yml` 即可。bash 基线为 4+：CI 用 ubuntu-24.04 自带的 bash 5.x，本地复跑用 `brew install bash` 后的 `/opt/homebrew/bin/bash`（macOS 自带的仍是 3.2）。推送前有 Lint 环节拦截格式、字段数、头部计数与平台越权选项问题。
