#!/usr/bin/env bash
# 产物头部生成器 —— 五个平台的 .list/.yaml 共用这一份实现
#
# 为什么单独成文件：Merge.yml 里五个 Platform 步骤各自要写头部，若各写一遍，
# 格式（字段名、顺序、缩进）迟早漂移，Lint 的计数校验与人工排查都会走样。
#
# 用法（在 Merge.yml 的步骤里）：
#   . "$repo/scripts/rulehdr.sh"   # 注意 source 而不是执行
#   add_header "$out" "$fname" "$WORK/$fname.meta"
#
# meta 文件由「Download upstream sources」步骤生成，每行 <TAB> 分隔：
#   <url>	<license>
#
# 头部内容：规则名称 / 规则统计 / 许可 / 来源清单。
# 许可与来源随订阅文件一起流通——上游多为 AGPL/GPL，保留署名是许可要求，
# 也是文件离开本仓库后唯一的溯源线索。

# 统计条目数：.yaml 数「  - 」列表项，.list 数非空行
rule_count() {
  if [[ "$1" == *.yaml ]]; then
    grep -c '^  - ' "$1" || true
  else
    grep -c '[^[:space:]]' "$1" || true
  fi
}

# 打印「# 许可: ...」与「# 来源:」两段
header_text() { # $1=meta 文件
  local meta="$1" lic
  if [[ -s "$meta" ]]; then
    lic=$(cut -f2 "$meta" | sort -u | paste -sd'/' -)
    printf '# 许可: %s\n' "${lic:-未声明}"
    printf '# 来源:\n'
    awk -F'\t' 'NF >= 2 { printf "#   - %s (%s)\n", $1, $2 }' "$meta"
  else
    printf '# 许可: 未声明\n'
  fi
}

# 给产物文件加头部。就地改写，保留原内容不变。
add_header() { # $1=产物文件 $2=规则集名 $3=meta 文件
  local f="$1" n="$2" meta="${3:-}" cnt
  cnt=$(rule_count "$f")
  {
    printf '# 规则名称: %s\n# 规则统计: %s\n' "$n" "$cnt"
    header_text "$meta"
    printf '\n'
    cat "$f"
  } > "$f.tmp"
  mv "$f.tmp" "$f"
}
