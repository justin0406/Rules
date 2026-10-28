#!/usr/bin/env bash
# 推送前本地验证：lint + 完整构建 + 产物变更统计
#
#   用法：scripts/verify.sh [-k] [-q]
#     -k  保留临时目录（排查用，结束时打印路径）
#     -q  只打印结论，不打印每个步骤的日志
#
# 做的事：
#   1. actionlint（同时用 shellcheck 检查每个 run 块）
#   2. 把仓库复制到临时目录，抽出 Merge.yml 的各步骤按顺序本地跑一遍
#   3. 报告「这次构建会产生哪些产物变更」——等于 CI 推上去会提交什么
#
# 全程不碰当前工作区：构建在临时副本里进行，失败也不会留下半成品。

set -euo pipefail

KEEP=0
QUIET=0
while getopts "kqh" opt; do
  case "$opt" in
    k) KEEP=1 ;;
    q) QUIET=1 ;;
    h) sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) exit 2 ;;
  esac
done

REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
cd "$REPO_DIR"

say() { printf '%s\n' "$*"; }
hr() { printf '%s\n' "────────────────────────────────────────────────────────────"; }
step() { hr; say "$*"; }

# ── 0. 环境自检 ──────────────────────────────────────────────────────────
pick_bash() {
  local candidate
  for candidate in "${BASH_VERIFY:-}" /opt/homebrew/bin/bash /usr/local/bin/bash "$(command -v bash)"; do
    [[ -n "$candidate" && -x "$candidate" ]] || continue
    if "$candidate" -c '[[ ${BASH_VERSINFO[0]} -ge 4 ]]' 2>/dev/null; then
      printf '%s' "$candidate"; return 0
    fi
  done
  return 1
}

BASH_BIN=$(pick_bash) || {
  say "错误：需要 bash 4+（CI 使用 ubuntu-24.04 自带的 bash 5.x）。"
  say "  macOS 自带的是 3.2，请先安装：brew install bash"
  exit 1
}
BASH_VER=$("$BASH_BIN" -c 'printf "%s.%s.%s" "${BASH_VERSINFO[@]:0:3}"')

MISSING=()
command -v actionlint >/dev/null 2>&1 || MISSING+=("actionlint")
command -v shellcheck >/dev/null 2>&1 || MISSING+=("shellcheck")
command -v curl >/dev/null 2>&1 || MISSING+=("curl")
if [[ ${#MISSING[@]} -gt 0 ]]; then
  say "错误：缺少依赖：${MISSING[*]}"
  say "  安装：brew install ${MISSING[*]}"
  exit 1
fi

OTHER_PY=""
if ! python3 -c 'import yaml' >/dev/null 2>&1; then
  # Lint 步骤需要 PyYAML；没有就建个临时 venv 顶上去
  TMP_VENV=$(mktemp -d)/venv
  if python3 -m venv "$TMP_VENV" >/dev/null 2>&1 &&
     "$TMP_VENV/bin/pip" install -q pyyaml >/dev/null 2>&1; then
    OTHER_PY="$TMP_VENV/bin"
  else
    say "错误：Lint 步骤需要 PyYAML，且自动安装失败。"
    say "  手动：python3 -m pip install --user pyyaml"
    exit 1
  fi
fi

say "bash        $BASH_VER  ($BASH_BIN)"
say "actionlint  $(actionlint -version | head -1)"
say "shellcheck  $(shellcheck -V | awk -F': ' '/version:/{print $2}')"
[[ -n "$OTHER_PY" ]] && say "python      PyYAML venv: $OTHER_PY"

# ── 1. actionlint（含 shellcheck）──────────────────────────────────────────
step "1/3  lint workflow"
LINT_OUT=$(actionlint -no-color .github/workflows/*.yml 2>&1) || {
  say "$LINT_OUT"
  say ""
  say "❌ workflow 校验未通过，先修掉上面的问题"
  exit 1
}
[[ -n "$LINT_OUT" ]] && say "$LINT_OUT"
say "✅ actionlint + shellcheck 零问题"

# ── 2. 临时副本里按顺序跑构建步骤 ─────────────────────────────────────────
step "2/3  本地构建"
WORK_ROOT=$(mktemp -d)
cleanup() {
  if [[ "$KEEP" == "1" ]]; then
    say ""
    say "临时目录已保留：$WORK_ROOT"
  else
    rm -rf "$WORK_ROOT"
  fi
}
trap cleanup EXIT

COPY="$WORK_ROOT/repo"
mkdir -p "$COPY"
# 复制工作区（含 .git：Lint 步骤要 git show HEAD:<path> 做回归比对）
tar -C "$REPO_DIR" -cf - --exclude=.DS_Store . 2>/dev/null | tar -C "$COPY" -xf -
# 副本里把当前改动固化成一个提交，之后 git status 就只剩「本次构建产生的变化」
git -C "$COPY" -c user.name=verify -c user.email=verify@local \
  commit -q --allow-empty -am "verify baseline" >/dev/null 2>&1 || true

# 从 Merge.yml 抽出各步骤的 run 块（跳过 checkout / push / 清理运行记录）
python3 - "$COPY" "$WORK_ROOT/steps.sh" <<'PY'
import re, sys
repo, out = sys.argv[1], sys.argv[2]
wf = open(f"{repo}/.github/workflows/Merge.yml", encoding="utf-8").read()
body = wf[wf.index("\n    steps:\n"):]
blocks = re.split(r"\n      - name: ", body)[1:]
SKIP = {"Checkout Repository", "Push Update", "Cleanup Workflow"}
with open(out, "w", encoding="utf-8") as f:
    for blk in blocks:
        name = blk.split("\n")[0].strip()
        if name in SKIP:
            continue
        m = re.search(r"^        run: \|\n((?:          .*\n|\n)*)", blk, re.M)
        if not m:
            continue
        f.write(f"# ==== {name}\n")
        f.write("\n".join(l[10:] if l.startswith("          ") else l
                          for l in m.group(1).split("\n")))
        f.write("\n")
PY

# workflow 里有「必须在 Rules 仓库运行」的护栏，这里按 origin 推断 owner/repo
DETECTED_REPO="local/Rules"
if remote_url=$(git config --get remote.origin.url 2>/dev/null) && [[ -n "$remote_url" ]]; then
  detected=$(printf '%s' "$remote_url" \
    | sed -e 's|^[a-z]*://||' -e 's|^git@[^:]*:||' -e 's|^[^/]*/||' -e 's|\.git$||' -e 's|^/*||')
  [[ "$detected" == */* ]] && DETECTED_REPO="$detected"
fi

SUMMARY_FILE="$WORK_ROOT/summary.md"
: > "$SUMMARY_FILE"
START=$(date +%s)
LOG="$WORK_ROOT/build.log"
set +e
(
  cd "$WORK_ROOT"   # 步骤里的路径都以 repo/ 开头，工作区根目录下一层才是克隆
  export PATH="${OTHER_PY:+$OTHER_PY:}$PATH"
  export GITHUB_REPOSITORY="${GITHUB_REPOSITORY:-$DETECTED_REPO}"
  export GITHUB_STEP_SUMMARY="$SUMMARY_FILE"
  export TZ=Asia/Shanghai LC_ALL=C   # 与 workflow 的 env 保持一致
  "$BASH_BIN" "$WORK_ROOT/steps.sh"
) > "$LOG" 2>&1
BUILD_RC=$?
set -e
ELAPSED=$(( $(date +%s) - START ))

if [[ "$BUILD_RC" -ne 0 ]]; then
  say "❌ 构建失败（${ELAPSED}s），最后 30 行日志："
  tail -30 "$LOG" | sed 's/^/    /'
  exit 1
fi
say "✅ 构建通过（${ELAPSED}s）"
[[ "$QUIET" == "0" ]] && grep -E '::(warning|notice)::' "$LOG" | sed 's/^/    /' || true

# ── 3. 产物变更统计 ───────────────────────────────────────────────────────
step "3/3  产物变更（= 推送后 CI 会提交的内容）"
CHANGED=$(git -C "$COPY" status --porcelain -- Surge Loon QuantumultX mihomo Egern .github/upstream-cache | wc -l | tr -d ' ')
if [[ "$CHANGED" == "0" ]]; then
  say "0 个文件 —— 产物与当前提交完全一致，推送后不会产生新提交"
else
  say "$CHANGED 个文件有变化："
  git -C "$COPY" status --porcelain -- Surge Loon QuantumultX mihomo Egern .github/upstream-cache \
    | sed 's/^/    /' | head -30
  if [[ "$CHANGED" -gt 30 ]]; then
    say "    …（共 $CHANGED 个）"
  fi
  say ""
  say "各集合条目数（Surge / mihomo / Egern / Loon / QuantumultX / ΔSurge）："
  sed -n '/各集合条目数/,/平台合计/p' "$SUMMARY_FILE" \
    | grep -E '^\| (AI|AppleCN|AppleProxy|CDN|CN|ChinaIP|Direct|GFW|Speedtest|TG) ' \
    | sed 's/^/    /' || true
fi
grep -q '::warning::' "$LOG" && {
  say ""
  say "⚠️  构建过程中有降级告警（上游不可用，已沿用快照），详见上面输出"
}

hr
say "结论：lint 与构建均通过。"
