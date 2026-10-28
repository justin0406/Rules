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
| Stash | `Stash/` | `.list` |
| QuantumultX | `QuantumultX/` | `.list` |
| mihomo | `mihomo/` | `.list` |
| Egern | `Egern/` | `.yaml` |

规则集合（10 个）：`AI` `AppleCN` `AppleProxy` `CDN` `CN` `ChinaIP` `Direct` `GFW` `Speedtest` `TG`

例：`https://raw.githubusercontent.com/justin0406/Rules/main/Surge/AI.list`

## 平台能力差异

各平台支持的规则类型不同，构建时按平台裁剪/改写，下表为实际处理方式（依据各平台官方文档）：

| 规则类型 | Surge | Loon | Stash | QuantumultX | mihomo | Egern |
|---|:--:|:--:|:--:|:--:|:--:|:--:|
| `DOMAIN` / `DOMAIN-SUFFIX` / `DOMAIN-KEYWORD` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `DOMAIN-WILDCARD` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `IP-CIDR` / `IP-CIDR6` / `no-resolve` | ✅ | ✅ | ✅ | ✅¹ | ✅ | ✅ |
| `IP-ASN` / `GEOIP` | ✅ | ✅ | ✅ | ✅ | ✅ | ✅ |
| `PROCESS-NAME` | ✅ | ✅² | ✅ | ❌ | ✅ | ❌³ |
| `USER-AGENT` | ✅ | ✅ | ✅ | ✅ | ❌ | ✅ |
| `URL-REGEX` | ✅ | ✅ | ✅ | ❌ | ❌ | ✅ |
| `AND` / `OR` / `NOT` | ✅ | ✅ | ✅ | ❌ | ✅ | ❌³ |
| `extended-matching`（仅 Surge 专有） | ✅ | ❌ | ❌ | ❌ | ❌ | ❌ |

¹ QuantumultX 不支持 `no-resolve`，构建时会移除。
² Loon 的进程规则仅在 macOS 生效，iOS / tvOS 会忽略。
³ Egern 无进程规则；`AND`/`OR`/`NOT` 官方文档未给出规则集内可验证的嵌套写法，暂不产出。

> Stash 引用本仓库规则集时需使用 `behavior: classical`，否则 `USER-AGENT` / `URL-REGEX` / `AND` 类条目不会生效。

## 已停止产出

- **Shadowrocket**（2026-10-28 起）：该客户端没有公开的官方规则语法文档，无法验证适配是否正确，不再维护。

## 维护

改 `.github/workflows/Merge.yml` 即可。脚本刻意保持 bash 3.2 兼容（不用关联数组 / mapfile / GNU `sed -i`），可在 macOS 上本地复跑整条构建链验证。推送前有 Lint 环节拦截格式、字段数、头部计数与平台越权选项问题。
