#!/usr/bin/env bash
# seL4 教程示例验证脚本（Isabelle2025-2，macOS + Linux 均已实测）
# 用法:
#   ./run-all.sh                       # 全量验证：build + 输出抽取 + 两遍比对 + 引用检查
#   ISABELLE=/path/to/isabelle ./run-all.sh   # 覆盖默认 isabelle 路径
#   SE4SRC=/path/to/seL4-root ./run-all.sh    # 覆盖真实代码根（下含 l4v/ 与 seL4/）
#   SE4DOC=/path/to/mirror ./run-all.sh       # 覆盖官方文档镜像根（下含 docs/、capdl/、microkit/）
#   ./run-all.sh S07_nondet_monad      # 只报告一个 theory（build/抽取仍全量）
#   ./run-all.sh clean                 # 清理 build/ 下本脚本产物
#
# 验证纪律（沿用 Isabelle/HOL 教程，并按 seL4 教程补了三关）:
#   1. isabelle build -D examples 退出码 0，且日志无溃逃痕迹
#      —— Isabelle/Scala 工具失败不一定让进程退出码非 0，必须查日志。
#   2. isabelle process_theories -O 捕获每个示例的
#      ==== NN 开始 ==== / ==== NN 结束 ==== 区间，要求标记齐、区间非空、
#      无控制字符、无溃逃痕迹（Error/FAILED/Unfinished/Uncaught）。
#   3. 同一命令连跑两遍，标记区间逐字节一致
#      —— 单引擎无多通道可比，用「运行间确定性」替代「跨通道一致性」。
#   4. 抽区间 + 逐字节比对（与 2、3 同一段代码，报告每个 theory 的状态）。
#   5. 真实代码引用检查：docs/、README、CHEATSheet、examples/ 里出现的
#      每个 seL4/… 与 l4v/… 路径都要在 SE4SRC 下真实存在；带行号的还要
#      "被引行上下 8 行内确实出现离它最近的那个标识名"（tools/check-refs.py）。
#   6. 正文实测块检查：docs/ 里每个 ```text 块默认按"实测输出"对待，
#      逐行（空白折叠后取子串）必须能在第一遍抽取的区间输出里找到；
#      不是实测输出的块必须显式标 <!-- 示意块 --> 或 <!-- 源码块：路径 -->。
#
# 环境前置条件（双平台实测，换了环境要重新确认）：
#   * Isabelle 的构建库用 SQLite，写库时要 unlink 掉 -journal 文件。
#     - Linux：普通权限即可，无 unlink 问题。脚本仍保留 USER_HOME 处理，
#       好处是 heaps 与用户 `~/.isabelle` 隔离，重跑不受污染。
#     - macOS：对 `~/` 下未签名二进制的 unlink 返回 EPERM，SQLite 删不掉
#       -journal 就报 [SQLITE_ERROR] cannot commit / [SQLITE_IOERR_DELETE]，
#       唯一有效解法是把 heaps/构建库整体挪出 `~/`。
#   * ISABELLE_HOME_USER / ISABELLE_HEAPS **不能靠环境变量直接改**：
#     etc/settings 里是无条件赋值，把传进来的值覆盖掉了。它们都由
#     USER_HOME 派生，而 USER_HOME 只在为空时才被赋值
#     （lib/scripts/getsettings），所以本脚本改的是 USER_HOME。
#   * 控制字符检查用 POSIX `[[:cntrl:]]` 而不是 `[^[:print:][:space:]]`：
#     后者的补集在 LC_ALL=C 下会把 CJK 的 UTF-8 高字节（≥0x80）全判成
#     非可打印，而本教程的标记是中文（==== 21 开始 ====），会 24/24 误报。
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

# 真实代码根：默认按平台找，两个子仓库是 l4v/（Isabelle 规范与证明）
# 和 seL4/（C 内核与 libsel4）。
if [[ -z "${SE4SRC:-}" ]]; then
  case "$(uname -s)" in
    Darwin) SE4SRC=/Volumes/mac004/lang/seL4 ;;
    Linux)  SE4SRC=/home/admin/hol/seL4 ;;
    *)      SE4SRC=/home/admin/hol/seL4 ;;
  esac
fi

# 官方文档镜像根：docs/（文档站 seL4_docs 仓库）、capdl/、microkit/。
# 教程里 `docs/Tutorials/…`、`docs/projects/…`、`capdl/…`、`microkit/…` 引用的
# 就是这里的文件——它们是官方文档的**本地副本**，所以引文能逐字核对，
# 不必依赖网络。docs/ 下只放行 Tutorials、projects、Hardware、processes、
# content_collections 五个子目录（避开本教程自己的 docs/NN-*.md）。
# SE4DOC=… 可覆盖；置为不存在的目录则相关块计入"未核"。
if [[ -z "${SE4DOC:-}" ]]; then
  case "$(uname -s)" in
    Darwin) SE4DOC=/Volumes/mac004/lang/seL4 ;;
    Linux)  SE4DOC=/home/admin/github/seL4 ;;
    *)      SE4DOC=/home/admin/github/seL4 ;;
  esac
fi

# 见文件头：USER_HOME 是唯一能把 heaps/构建库挪出 ~/ 的入口（macOS 必需）。
export USER_HOME="${USER_HOME:-/tmp/isb-sel4-user}"
mkdir -p "$USER_HOME"
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
  # -l HOL-Library（不是 HOL）：S07/S08 里 import 了
  # "HOL-Library.Monad_Syntax"，基线会话必须包含 HOL-Library，
  # 否则报 "Bad import ... need to include sessions HOL-Library in ROOT"，
  # 而且 **run.log 是空的、错误只进 stderr** —— 表现就是"每个区间都为空"。
  #
  # 三个 -o 是"两遍逐字节可比"的前提（双平台实测，缺一个都不行）：
  #   parallel_print=false —— 否则消息按线程异步落地，两遍顺序不同；
  #   parallel_proofs=0 / threads=1 —— 关掉命令级并行，固定执行顺序。
  # 实测关掉之后，两遍之间唯一差异只剩末尾那行耗时数字，而它在区间之外。
  "$ISABELLE" process_theories -O -l HOL-Library \
    -o parallel_print=false -o parallel_proofs=0 -o threads=1 \
    -H 'S[0-9]{2}_[a-z_]+\.thy' -D "$EXAMPLES" $theories \
    >"$1/run.log" 2>"$1/run.err"
}

# --- 第 1 关：会话构建（全部证明/类型错误在此暴露） -------------------------
if [[ "$only" == "refs" ]]; then
  # 快速模式：只跑第 5、6 关，沿用上一次构建留在 $OUT/first/out 里的抽取产物。
  # 改正文（引文、行号、实测块）时用这一档，几秒出结果，不用等 Isabelle。
  echo "== 只核引用与正文块（refs 模式，沿用 $OUT/first/out/ 的既有产物）"
  if [[ ! -d "$OUT/first/out" ]]; then
    echo "!! $OUT/first/out 不存在，先完整跑一遍 ./run-all.sh" >&2; exit 1
  fi
else
echo "== [1/6] isabelle build -D $EXAMPLES"
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
echo "== [2/6] process_theories 第一遍"
run_once "$OUT/first"
echo "== [3/6] process_theories 第二遍"
run_once "$OUT/second"

# --- 第 4 关：抽区间、查标记/控制字符/溃逃、逐字节比对 ----------------------
echo "== [4/6] 抽取与比对"
for t in $theories; do
  extract "$OUT/first" "$t" "$OUT/first/out/$t.txt"
  extract "$OUT/second" "$t" "$OUT/second/out/$t.txt"
  f1="$OUT/first/out/$t.txt"
  st=ok
  b=$(grep -c '开始' "$f1"); e=$(grep -c '结束' "$f1")
  [[ "$b" -ge 1 && "$b" -eq "$e" ]] || st=bad
  [[ -s "$f1" ]] || st=empty
  # 控制字符必须用 POSIX [[:cntrl:]]（0x00–0x1F / 0x7F），理由见文件头。
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
fi   # ← refs 模式在此跳过第 1–4 关

# --- 第 5 关：真实代码引用（路径存在 + 行号站得住） ------------------------
echo "== [5/6] 文档与示例里的真实代码引用"
if [[ -d "$SE4SRC" ]]; then
  # 引用长这样：`l4v/spec/abstract/CSpace_A.thy`、`…/CSpace_A.thy:292`、
  # "…CSpace_A.thy` 第 292 行"、裸文件名 `CSpace_A.thy 第 208 行`、目录级 `l4v/spec/capDL/`；
  # 官方文档那一路：`docs/Tutorials/setting-up.md 第 70 行`、`capdl/docs/capDL.md`、
  # `microkit/docs/manual.md`，在 SE4DOC 下核。
  # 中文句子要按字符（不是字节）解析，所以这一关用 python3 做。
  PY="${PYTHON:-python3}"
  if command -v "$PY" >/dev/null 2>&1; then
    if ! "$PY" tools/check-refs.py "$SE4SRC" "$SE4DOC" 8 \
         "$DOCS"/*.md README.md CHEATSheet.md "$EXAMPLES"/*.thy; then FAIL=1; fi
  else
    echo "   (跳过：没有 python3)"
  fi
else
  echo "   (跳过：未找到 $SE4SRC，可用 SE4SRC=... 指定)"
fi

# --- 第 6 关：正文里的"实测块"必须逐行来自构建产物 --------------------------
# 约定：docs/NN 里每个 ```text 块默认是"实测块"（必须能在第一遍抽取的区间输出里
# 逐行找到，空白折叠后按子串比）；不是实测输出的块必须显式标
#   <!-- 示意块：… -->      —— 手写示意，不比
#   <!-- 源码块：路径:起-止 --> —— 摘自真实文件，改比对那个文件。
#   路径前缀 l4v/、seL4/ 在 SE4SRC 下找；docs/{Tutorials,projects,Hardware,
#   processes,content_collections}/、capdl/、microkit/ 在文档镜像 SE4DOC 下找
#   （镜像不在时这些块计入"未核"并报数）。
#   标了行号（`:起-止`、`:N`、`第 起--止 行`、`第 N 行`）就**严格对齐**：块行数必须
#   等于区间长度，且逐行相等（只折叠空白）——省略、改写、挪位置都会被判失败；
#   只写路径不写行号则退化成"每行在该文件里找得到"，用于整份文件的摘录。
# 这条纪律把"想象中的输出"变成机器可查的断言。
echo "== [6/6] 正文实测块 vs 构建产物"
if [[ -d "$OUT/first/out" ]]; then
  DOCOK=0; [[ -d "$SE4DOC" ]] && DOCOK=1
  if ! awk -v outdir="$OUT/first/out" -v src="$SE4SRC" -v docsrc="$SE4DOC" -v docok="$DOCOK" -v ths="$theories" '
    BEGIN { for (i = split(ths, A, /[ \n]+/); i > 0; i--) if (A[i] ~ /^S[0-9][0-9]_/) map[substr(A[i], 2, 2)] = A[i] }
    function collapse(s) { gsub(/[ \t\r]+/, " ", s); gsub(/^ +| +$/, "", s); return s }
    function loadout(t,   f, l) {
      if (t in blob) return
      f = outdir "/" t ".txt"; blob[t] = ""
      while ((getline l < f) > 0) blob[t] = blob[t] " " collapse(l)
      close(f)
    }
    function loadfile(base, p,   l, f, n) {
      f = base "/" p
      if (f in fblob) return
      fblob[f] = ""; flen[f] = 0
      while ((getline l < f) > 0) {
        fblob[f] = fblob[f] " " collapse(l)
        n = flen[f] + 1; flines[f, n] = l; flen[f] = n
      }
      close(f)
    }
    function rng(mark,   r, A) {              # 取标记里声明的区间；没声明返回 0
      if (match(mark, /第 [0-9]+--[0-9]+ 行/)) {
        r = substr(mark, RSTART, RLENGTH); gsub(/[^0-9-]/, "", r); split(r, A, "--")
        return A[1] * 1000000 + A[2]
      }
      if (match(mark, /[:：][0-9]+-[0-9]+/)) {
        r = substr(mark, RSTART, RLENGTH); gsub(/[^0-9-]/, "", r); split(r, A, "-")
        return A[1] * 1000000 + A[2]
      }
      if (match(mark, /第 [0-9]+ 行/)) {                 # 单行：第 N 行
        r = substr(mark, RSTART, RLENGTH); gsub(/[^0-9]/, "", r)
        return r * 1000001
      }
      if (match(mark, /[:：][0-9]+[ ]*-->/)) {           # 单行：路径:N -->
        r = substr(mark, RSTART, RLENGTH); gsub(/[^0-9]/, "", r)
        return r * 1000001
      }
      return 0
    }
    FNR == 1 { marker = ""; inblk = 0; buf = "" }
    function flush_blk(   t, i, ln, p, base, f, g, s, e, n) {
      nblk++
      if (marker ~ /示意块/) { marker = ""; inblk = 0; return }
      split(buf, L, "\n")
      if (marker !~ /源码块/) {                     # 实测块：逐行找得到才算数
        base = FILENAME; sub(/^.*\//, "", base)     # docs/02-kernel-objects.md → 02-kernel-objects.md
        t = map[substr(base, 1, 2)]
        loadout(t)
        if (blob[t] == "") { printf "!! %s: 找不到抽取产物 %s.txt\n", FILENAME, t; bad++; marker = ""; inblk = 0; return }
        for (i in L) {
          ln = collapse(L[i]); if (ln == "") continue
          if (index(blob[t], ln) == 0) {
            printf "!! %s: 实测块里的这一行不在 %s 的输出里: %s\n", FILENAME, t, ln
            bad++
          }
        }
      } else {                                       # 源码块：比对真实文件
        p = ""; base = ""
        if (match(marker, /(l4v|seL4)\/[^ :]+/)) {
          p = substr(marker, RSTART, RLENGTH); base = src
        } else if (match(marker, /(docs\/(Tutorials|projects|Hardware|processes|content_collections)|capdl|microkit)\/[^ :]+/)) {
          p = substr(marker, RSTART, RLENGTH)
          if (!docok) { nskip++; marker = ""; inblk = 0; return }   # 没有镜像，跳过不判
          base = docsrc
        }
        if (base == "") { printf "!! %s: 源码块没写清文件路径\n", FILENAME; bad++ }
        else {
          f = base "/" p
          loadfile(base, p)
          if (fblob[f] == "") { printf "!! %s: 源码块指向的文件读不到: %s\n", FILENAME, p; bad++ }
          else {
            g = rng(marker); s = int(g / 1000000); e = g % 1000000
            if (g == 0) {                      # 只写了路径：每行在该文件里找得到即可
              for (i in L) {
                ln = collapse(L[i]); if (ln == "") continue
                if (index(fblob[f], ln) == 0) { printf "!! %s: 源码块这一行不在 %s 里: %s\n", FILENAME, p, ln; bad++ }
              }
            } else if (e > flen[f]) {
              printf "!! %s: 源码块声明到 %s 第 %d 行，该文件只有 %d 行\n", FILENAME, p, e, flen[f]; bad++
            } else {
              n = 0; for (i in L) n++
              if (n > 0 && L[n] == "") { delete L[n]; n-- }   # buf 末尾那个换行不是行
              if (n != e - s + 1) {
                printf "!! %s: 源码块声明 %s 第 %d--%d 行（%d 行），块里是 %d 行——区间要写准，不许省略\n", FILENAME, p, s, e, e - s + 1, n; bad++
              } else for (i = 1; i <= n; i++) {
                if (collapse(L[i]) != collapse(flines[f, s + i - 1])) {
                  printf "!! %s: 源码块第 %d 行与 %s:%d 不符: %s\n", FILENAME, i, p, s + i - 1, collapse(L[i]); bad++; break
                }
              }
            }
          }
        }
      }
      marker = ""; inblk = 0
    }
    {
      if (inblk) {
        if ($0 ~ /^```/) { flush_blk(); next }
        buf = buf $0 "\n"; next
      }
      if ($0 ~ /^<!--/ && $0 ~ /(示意块|源码块)/) { marker = $0; next }
      if ($0 ~ /^```[ ]*text$/) { inblk = 1; buf = ""; next }
      if ($0 ~ /^```/) { marker = ""; next }        # 其他语言的块不参与比对
    }
    END { printf "   比对 %d 个 text 块，%d 行不符", nblk + 0, bad + 0
          if (nskip + 0 > 0) printf "（另有 %d 个文档源码块因缺镜像未核）", nskip + 0
          printf "\n"; if (bad + 0 > 0) exit 1 }
  ' "$DOCS"/*.md; then FAIL=1; fi
else
  echo "   (跳过：没有 $OUT/first/out)"; FAIL=1
fi

echo "产物目录: $OUT/{first,second}/out/ 与 $OUT/build.log"
if [[ "$FAIL" -eq 0 ]]; then
  echo "全部示例验证通过"
else
  echo "存在失败项"; exit 1
fi
