# 上游源快照

这里存放每个上游规则源「最近一次抓取成功」的原始内容，由 `Merge.yml` 的
`Download upstream sources` 步骤维护，**不要手工编辑**。

## 为什么要存

上游有 20+ 个源，其中 `git.repcz.link`（第三方自建 Gitea）和 `raw.githubusercontent.com`
偶发 5xx / 超时 / 返回 HTML 挑战页。没有快照时只有两种坏结局：整轮构建失败，
或者静默发布缺了几百条规则的订阅。有了快照就可以「沿用上次的好数据」继续发布。

## 规则

- 抓取成功 → 用新内容覆盖对应快照，`manifest.tsv` 里时间戳更新
- 抓取失败 → 用快照内容继续构建，该源在 `manifest.tsv` 里标记为降级，
  并在 job summary 与提交消息里留痕
- 抓取失败且没有快照（刚新增、从未成功过）→ 构建失败，不猜内容
- 响应看起来是 HTML（挑战页/错误页）→ 当作失败处理，不污染快照
- URL 从工作流里移除后，对应快照会在下一次构建时被清理

## manifest.tsv

`slug <TAB> url <TAB> 最近成功时间(UTC) <TAB> 状态(ok / 失败原因)`
