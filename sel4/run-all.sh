#!/usr/bin/env bash
# seL4 教程示例验证脚本（Isabelle2025-2，macOS）
# 用法:
#   ./run-all.sh              # 全量验证：build + 输出抽取 + 两遍比对 + 引用检查
#   ./run-all.sh S07_nondet_monad   # 只报告一个 theory（build/抽取仍全量）
#   ./run-all.sh clean        # 清理 build/ 下本脚本产物
#
# 验证纪律（沿用 Isabelle/HOL 教程，并按 seL4 教程补了第 5 关）:
#   1. isabelle build -D examples 退出码 0，且日志无溃逃痕迹
#      —— Isabelle/Scala 工具失败不一定让进程退出码非 0，必须查日志。
#   2. isabelle process_theories -O 捕获每个示例的
#      ==== NN 开始 ==== / ==== NN 结束 ==== 区间，要求标记齐、区间非空、
#      无控制字符、无溃逃痕迹（Error/FAILED/Unfinished/Uncaught）。
#   3. 同一命令连跑两遍，标记区间逐字节一致
#      —— 单引擎无多通道可比，用「运行间确定性」替代「跨通道一致性」。
#   4. 真实代码引用检查：docs/ 里出现的每个 seL4/… 与 l4v/… 路径
#      都要在 SE4SRC 下真实存在（教程不写想象中的引用）。
#
# 运行前置条件（本机实测，换了环境要重新确认）：
#   * Isabelle 的构建库用 SQLite。写库时要 unlink 掉 -journal 文件，
#     一旦 unlink 被拦（受限沙箱、或 macOS 下 ~/ 里未签名二进制的 EPERM），
#     build 会报 [SQLITE_ERROR] / [SQLITE_IOERR_DELETE]。
#     应对写在脚本里：把 USER_HOME 指到 /tmp 下（ISABELLE_HOME_USER /
#     ISABELLE_HEAPS 在 etc/settings 里是无条件赋值，改不动；它们都由
#     USER_HOME 派生，而 USER_HOME 只在为空时才被赋值）。
set -uo pipefail
cd "$(dirname "$0")"

ISABELLE="${ISABELLE:-/Applications/Isabelle2025-2.app/bin/isabelle}"
export USER_HOME="${USER_HOME:-/tmp/isb-sel4-user}"
SE4SRC="${SE4SRC:-/Volumes/mac004/lang/seL4}"
EXAMPLES=examples
DOCS=docs
OUT=build
FAIL=0
only="${1:-}"

if [[ ! -x "$ISABELLE" ]]; then
  echo "未找到 isabelle：请设 ISABELLE=/path/to/isabelle" >&2
  exit 1
fi

if [[ "$only" == "clean" ]]; then
  rm -rf "$OUT/first" "$OUT/second"
  echo "已清理 $OUT/"
  exit 0
fi

theories=$(grep -E '^    S[0-9]{2}_.*$' "$EXAMPLES/ROOT" | tr -d ' ')

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
  # 三个 -o 是"两遍逐字节可比"的前提（本机实测，缺一个都不行）：
  #   parallel_print=false —— 否则消息按线程异步落地，两遍顺序不同；
  #   parallel_proofs=0 / threads=1 —— 关掉命令级并行，固定执行顺序。
  # -l HOL-Library（不是 HOL）：S07/S08 里 import 了
  # "HOL-Library.Monad_Syntax"，基线会话必须包含 HOL-Library，
  # 否则报 "Bad import ... need to include sessions HOL-Library in ROOT"
  # 并且 **run.log 是空的、错误只进 stderr** —— 表现就是"每个区间都为空"。
  "$ISABELLE" process_theories -O -l HOL-Library \
    -o parallel_print=false -o parallel_proofs=0 -o threads=1 \
    -H 'S[0-9]{2}_[a-z_]+\.thy' -D "$EXAMPLES" $theories \
    >"$1/run.log" 2>"$1/run.err"
}

# --- 第 1 关：会话构建（全部证明/类型错误在此暴露） -------------------------
echo "== [1/5] isabelle build -D $EXAMPLES"
mkdir -p "$OUT"
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
echo "== [2/5] process_theories 第一遍"
run_once "$OUT/first"
echo "== [3/5] process_theories 第二遍"
run_once "$OUT/second"

# --- 第 4 关：抽区间、查标记/控制字符/溃逃、逐字节比对 ----------------------
echo "== [4/5] 抽取与比对"
for t in $theories; do
  extract "$OUT/first" "$t" "$OUT/first/out/$t.txt"
  extract "$OUT/second" "$t" "$OUT/second/out/$t.txt"
  f1="$OUT/first/out/$t.txt"
  st=ok
  b=$(grep -c '开始' "$f1"); e=$(grep -c '结束' "$f1")
  [[ "$b" -ge 1 && "$b" -eq "$e" ]] || st=bad
  [[ -s "$f1" ]] || st=empty
  # 控制字符必须用 POSIX [[:cntrl:]]（0x00–0x1F / 0x7F）。
  # 不能写 [^[:print:][:space:]]：LC_ALL=C 下 CJK 的 UTF-8 字节（≥0x80）
  # 不在 [:print:] 里，而本教程的标记是中文（==== 21 开始 ====），
  # 用补集写法会 24/24 全误报。
  if LC_ALL=C grep -q '[[:cntrl:]]' "$f1"; then st=ctrl; fi
  # 溃逃判据必须是"行首锚定"的组合，不能裸搜 Error：
  # seL4 的词汇里 Error 是正常标识符（throwError / DError / seL4_Error），
  # 裸搜会让 S08、S10 恒误报。横幅形状才是证据：*** 开头、行首 Error、
  # FAILED / Unfinished / Uncaught。
  grep -qE '^\*\*\*|^Error|FAILED|Unfinished|Uncaught' "$f1" && st=escape
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

# --- 第 5 关：真实代码引用检查 ----------------------------------------------
echo "== [5/5] 文档里的真实代码引用"
missing=0; checked=0
if [[ -d "$SE4SRC" ]]; then
  for p in $(grep -ohE '(seL4|l4v)/[A-Za-z0-9_][A-Za-z0-9_./-]*' "$DOCS"/*.md "$DOCS"/../*.md 2>/dev/null | sort -u); do
    # 行号引用形如 path:123 或 path 第 123 行，这里只取路径本体
    p="${p%%:*}"
    [[ "$p" == *.md ]] && continue
    checked=$((checked + 1))
    # 用 -e 而不是 -f：l4v/spec/capDL/ 这类"目录级"引用也是有效引用。
    if [[ ! -e "$SE4SRC/$p" ]]; then
      echo "!! 引用不存在: $p"; missing=$((missing + 1)); FAIL=1
    fi
  done
  echo "   检查了 $checked 个引用，缺失 $missing 个"
else
  echo "   (跳过：未找到 $SE4SRC，可用 SE4SRC=... 指定)"
fi

echo "产物目录: $OUT/{first,second}/out/ 与 $OUT/build.log"
if [[ "$FAIL" -eq 0 ]]; then
  echo "全部示例验证通过"
else
  echo "存在失败项"; exit 1
fi
