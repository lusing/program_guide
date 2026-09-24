#!/usr/bin/env bash
# Isabelle/HOL 教程示例验证脚本（Isabelle2025-2，macOS + Linux 均已实测）
# 用法:
#   ./run-all.sh                       # 全量验证：build + 输出抽取 + 两遍比对
#   ISABELLE=/path/to/isabelle ./run-all.sh   # 覆盖默认路径
#   ./run-all.sh T07_simp              # 只报告一个 theory（build/抽取仍全量）
#   ./run-all.sh clean                 # 清理 build/ 下本脚本产物
#
# 验证纪律（与仓库其他语言项目一致，按 Isabelle 特性定制）:
#   1. isabelle build -D examples 退出码 0，且日志无溃逃痕迹
#      —— Isabelle/Scala 工具失败不一定让进程退出码非 0，必须查日志。
#   2. isabelle process_theories -O 捕获每个示例的
#      ==== NN 开始 ==== / ==== NN 结束 ==== 区间，要求标记齐、区间非空、
#      无 ASCII 控制字符、无溃逃痕迹（Error/FAILED/Unfinished/Uncaught）。
#   3. 同一命令连跑两遍，标记区间逐字节一致
#      —— 单引擎无多通道可比，用「运行间确定性」替代「跨通道一致性」；
#      输出漂移往往指向示例自身依赖随机/环境，不只是工具噪声。
#
# 环境前置条件（macOS + Linux 双端实测，换了环境重新确认）：
#   * Isabelle 的构建库用 SQLite。写库时要 unlink 掉 -journal 文件。
#     - Linux：普通权限即可，无 unlink 问题。脚本仍保留下面 USER_HOME
#       的处理，好处是产物与用户 `~/.isabelle` 隔离，重跑不受污染。
#     - macOS：本机实测对 `~/` 下未签名二进制的 unlink 返回 EPERM，
#       SQLite 删不掉 -journal 就报
#         [SQLITE_ERROR] cannot commit / [SQLITE_IOERR_DELETE]。
#       唯一有效解法就是把 heaps/构建库整体挪出 `~/`。
#   * ISABELLE_HOME_USER / ISABELLE_HEAPS **不能靠环境变量直接改**（实测：
#     env ISABELLE_HOME_USER=/tmp/x isabelle getenv 仍然打印
#     ~/.isabelle/Isabelle2025-2）—— etc/settings 里是**无条件**赋值，
#     把传进来的值覆盖掉了。但它们都由 USER_HOME 派生，而 USER_HOME
#     只在为空时才被赋值（lib/scripts/getsettings）。所以本脚本改的是
#     **USER_HOME**。
#   * 平台差异：控制字符检查用 POSIX `[[:cntrl:]]` 而不是 `[^[:print:]]`——
#     后者的补集在 Linux 的 LC_ALL=C 下会把 CJK 的 UTF-8 高字节
#     (≥ 0x80) 全判成"非可打印"，导致每个 theory 误报；前者只匹配
#     0x00–0x1F / 0x7F，两平台语义一致。
set -uo pipefail
cd "$(dirname "$0")"

# 平台自适应：Darwin 走 .app，Linux 走 /home/admin/hol 与 PATH，
# 找不到时交给用户显式设 ISABELLE。
if [[ -z "${ISABELLE:-}" ]]; then
  case "$(uname -s)" in
    Darwin)
      for cand in \
        /Applications/Isabelle2025-2.app/bin/isabelle \
        "$HOME/Applications/Isabelle2025-2.app/bin/isabelle"; do
        [[ -x "$cand" ]] && ISABELLE="$cand" && break
      done ;;
    Linux)
      for cand in \
        /home/admin/hol/Isabelle2025-2/bin/isabelle \
        /opt/Isabelle2025-2/bin/isabelle \
        /usr/local/Isabelle2025-2/bin/isabelle; do
        [[ -x "$cand" ]] && ISABELLE="$cand" && break
      done
      [[ -z "${ISABELLE:-}" ]] && command -v isabelle >/dev/null && ISABELLE="$(command -v isabelle)" ;;
  esac
fi
ISABELLE="${ISABELLE:-isabelle}"
# 见文件头：USER_HOME 是唯一能把 heaps/构建库挪出 ~/ 的入口（macOS 必需）。
export USER_HOME="${USER_HOME:-/tmp/isb-user}"
mkdir -p "$USER_HOME"
EXAMPLES=examples
OUT=build
FAIL=0
only="${1:-}"

if [[ ! -x "$ISABELLE" ]]; then
  echo "未找到 isabelle：请设 ISABELLE=/path/to/isabelle" >&2
  exit 1
fi

clean() {
  rm -rf "$OUT/first" "$OUT/second"
  echo "已清理 $OUT/"
}

theories=$(grep -E '^    T[0-9]{2}_.*$' "$EXAMPLES/ROOT" | tr -d ' ')

# 从某一遍 run.log 抽单个 theory 的标记区间
extract() { # $1=run目录 $2=theory名 $3=输出文件
  awk -v pat="/$2.thy" '
    /^(Output|Error) \(/ { inmsg = (index($0, pat) > 0); next }
    inmsg { print }
  ' "$1/run.log" | awk '
    /^==== .*开始 ====/ { grab=1 }
    grab { print }
    /^==== .*结束 ====/ { grab=0 }
  ' > "$3"
}

run_once() { # $1=run目录
  mkdir -p "$1/out"
  # -l HOL：绕过 examples/ROOT，用临时 Draft 会话逐条跑，
  # 与 build 那条路径互为独立检查（build 走会话，这里走命令行）。
  #
  # 三个 -o 是"两遍逐字节可比"的前提，缺一个都不行（本机实测）：
  #   parallel_print=false —— 否则消息按线程异步落地，同一条命令的输出
  #     在两遍里落到不同位置。12/24 个示例的差异全部来自这里，
  #     表现是 value/ML 的打印与证明态的 show ... 行互相移位。
  #   parallel_proofs=0 / threads=1 —— 关掉命令级并行，让执行顺序固定。
  # 实测关掉之后，两遍之间的唯一差异只剩末尾那行
  #   "Finished Draft (... cpu time, factor 0.51)"
  # 的耗时数字，而它在标记区间之外，不参与比对。
  "$ISABELLE" process_theories -O -l HOL \
    -o parallel_print=false -o parallel_proofs=0 -o threads=1 \
    -H 'T[0-9]{2}_[a-z_]+\.thy' -D "$EXAMPLES" $theories \
    >"$1/run.log" 2>"$1/run.err"
}

# --- 第 1 关：会话构建（全部证明/类型错误在此暴露） -------------------------
echo "== [1/4] isabelle build -D $EXAMPLES"
mkdir -p "$OUT"
# 清掉上次中断留下的半截 SQLite journal：它一存在，本次 commit 必失败。
# 路径不猜，问工具要（ISABELLE_HEAPS 不能靠环境变量改，见文件头注释）。
HEAPS=$("$ISABELLE" getenv -b ISABELLE_HEAPS 2>/dev/null)
if [[ -n "$HEAPS" && -d "$HEAPS" ]]; then
  find "$HEAPS" -maxdepth 2 -name '*.db-journal' -print -delete 2>/dev/null
fi
if ! "$ISABELLE" build -v -D "$EXAMPLES" >"$OUT/build.log" 2>&1; then
  echo "!! build 失败（退出码非 0），详见 $OUT/build.log"; tail -30 "$OUT/build.log"; exit 1
fi
if grep -E 'FAILED|Unfinished session|^\*\*\*' "$OUT/build.log" >/dev/null; then
  echo "!! build 日志含溃逃痕迹，详见 $OUT/build.log"
  grep -E 'FAILED|Unfinished session|^\*\*\*' "$OUT/build.log" | head
  exit 1
fi
echo "   build 通过"

# --- 第 2/3 关：process_theories 跑两遍 -------------------------------------
echo "== [2/4] process_theories 第一遍"
run_once "$OUT/first"
echo "== [3/4] process_theories 第二遍"
run_once "$OUT/second"

# --- 第 4 关：抽区间、查标记/控制字符/溃逃、逐字节比对 ----------------------
echo "== [4/4] 抽取与比对"
for t in $theories; do
  extract "$OUT/first" "$t" "$OUT/first/out/$t.txt"
  extract "$OUT/second" "$t" "$OUT/second/out/$t.txt"
  f1="$OUT/first/out/$t.txt"
  st=ok
  b=$(grep -c '开始' "$f1"); e=$(grep -c '结束' "$f1")
  [[ "$b" -ge 1 && "$b" -eq "$e" ]] || st=bad
  [[ -s "$f1" ]] || st=empty
  if LC_ALL=C grep -q '[[:cntrl:]]' "$f1"; then st=ctrl; fi
  grep -qE 'Error|FAILED|Unfinished|Uncaught' "$f1" && st=escape
  cmp -s "$f1" "$OUT/second/out/$t.txt" || st=differ
  if [[ -n "$only" && "$t" != "$only" ]]; then continue; fi
  case "$st" in
    ok)     echo "   ok   $t" ;;
    bad)    echo "!! 标记不全($b/$e): $t"; FAIL=1 ;;
    empty)  echo "!! 区间为空: $t"; FAIL=1 ;;
    ctrl)   echo "!! 含控制字符: $t"; FAIL=1 ;;
    escape) echo "!! 区间含溃逃痕迹: $t"; FAIL=1 ;;
    differ) echo "!! 两遍输出不一致: $t"; FAIL=1 ;;
  esac
done

echo "产物目录: $OUT/{first,second}/out/ 与 $OUT/build.log"
if [[ "$FAIL" -eq 0 ]]; then
  echo "全部示例验证通过"
else
  echo "存在失败示例"; exit 1
fi
