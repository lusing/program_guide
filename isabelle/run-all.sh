#!/usr/bin/env bash
# Isabelle/HOL 教程示例验证脚本（Isabelle2025-2，Windows/Cygwin + Linux + macOS 实测）
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
# 多会话布局（examples/ROOT 里一个会话一组，各自父会话即验证堆）:
#   IsaTut    = "HOL-Eisbach"   主线 30 章 + 手册覆盖章
#   IsaTutLib = "HOL-Library"   corec friends / HOL-Library 选讲章
#   IsaTutFOL = FOL             一阶逻辑对象逻辑章
#   IsaTutZF  = ZF              集合论对象逻辑章
#   脚本从 ROOT 解析「会话 → 父堆 → 理论清单」，逐堆各跑一路
#   process_theories；判定标准对所有会话一视同仁。
#
# 环境前置条件（Windows/Cygwin + Linux + macOS 三端实测，换环境重新确认）：
#   * Windows 版 Isabelle 不能在 Git Bash(MSYS/MINGW) 里直接跑：lib/scripts/
#     isabelle-platform 认 uname，MINGW64_NT-* 不认识，报
#       Failed to determine hardware and operating system type!
#     唯一正解是经发行版自带的 contrib/cygwin/bin/bash --login 进入 Cygwin
#     世界再调 isabelle（Cygwin-Terminal.bat 官方入口同款）。
#   * Cygwin 登录 shell 里 PATH 不含 isabelle：MSYS 环境变量能透传（Windows
#     环境块），但 PATH 会被 /etc/profile 重写，所以重入后用完整 cygwin 路径
#     /cygdrive/<盘>/.../bin/isabelle 定位，不依赖 PATH。
#   * 两个盘符体系：MSYS 的 /g/code 是 Cygwin 的 /cygdrive/g/code。重入时把
#     Windows 路径当媒介（cygpath -w 在 MSWS 端转出，cygpath -u 在 Cygwin 端
#     转回），不自己拼字符串。
#   * Isabelle 的构建库用 SQLite。写库时要 unlink 掉 -journal 文件。
#     - Linux/Windows：普通权限即可，无 unlink 问题。脚本仍保留下面 USER_HOME
#       的处理，好处是产物与用户 ~/.isabelle 隔离，重跑不受污染。
#     - macOS：本机实测对 ~/ 下未签名二进制的 unlink 返回 EPERM，
#       SQLite 删不掉 -journal 就报
#         [SQLITE_ERROR] cannot commit / [SQLITE_IOERR_DELETE]。
#       唯一有效解法就是把 heaps/构建库整体挪出 ~/。
#     - 并发陷阱（Windows 实测）：两个 isabelle build 同时写同一个构建库会报
#       [SQLITE_CONSTRAINT_PRIMARYKEY] isabelle_sources 主键冲突——孤儿构建
#       进程未清就重入必踩。本脚本 build 前清 -journal，但同一时间只允许一个
#       build 在跑。
#   * ISABELLE_HOME_USER / ISABELLE_HEAPS **不能靠环境变量直接改**（实测：
#     env ISABELLE_HOME_USER=/tmp/x isabelle getenv 仍然打印
#     ~/.isabelle/Isabelle2025-2）—— etc/settings 里是**无条件**赋值，
#     把传进来的值覆盖掉了。但它们都由 USER_HOME 派生，而 USER_HOME
#     只在为空时才被赋值（lib/scripts/getsettings）。所以本脚本改的是
#     **USER_HOME**。
#   * 平台差异：控制字符检查用 POSIX `[[:cntrl:]]` 而不是 `[^[:print:]]`——
#     后者的补集在 Linux 的 LC_ALL=C 下会把 CJK 的 UTF-8 高字节
#     (>= 0x80) 全判成"非可打印"，导致每个 theory 误报；前者只匹配
#     0x00-0x1F / 0x7F，三平台语义一致。
#   * 控制台显示：Cygwin 终端默认代码页可能把中文标记显示成乱码，
#     字节本身是 UTF-8，比对不受影响（Windows 实测）。
set -uo pipefail
cd "$(dirname "$0")"

# --- 平台自适应：Git Bash 重入 / 三端定位 isabelle --------------------------
os=$(uname -s)
if [[ "$os" == MINGW* || "$os" == MSYS* ]] && [[ -z "${ISABELLE_TUT_REEXEC:-}" ]]; then
  # Git Bash -> 自带 Cygwin 登录 shell -> 本脚本再跑一遍（ISABELLE_TUT_REEXEC 防套娃）
  ISABELLE_WIN_DIR="${ISABELLE_WIN_DIR:-G:\\xulun3\\isabelle\\Isabelle2025-2}"
  CYG_BASH="$(cygpath -u "$ISABELLE_WIN_DIR")/contrib/cygwin/bin/bash"
  if [[ -x "$CYG_BASH" ]]; then
    TUT_WIN_DIR=$(cygpath -w "$(pwd)")
    # LANG 必须显式带上（Cygwin-Terminal.bat 同款）：不传的话 Isabelle/Scala
    # 用 Windows ANSI 代码页转码 ML 输出，中文标记会写成 GBK 字节（bf aa ca
    # bc），UTF-8 的 awk 模式逐字节匹配不上，全部示例"区间为空"。
    export ISABELLE_TUT_REEXEC=1 CHERE_INVOKING=1 TUT_WIN_DIR \
      USER_HOME="${USER_HOME:-}" ISABELLE="${ISABELLE:-}" TUT_ARGS="${1:-}" \
      LANG="${LANG:-en_US.UTF-8}"
    exec "$CYG_BASH" --login -c \
      'cd "$(cygpath -u "$TUT_WIN_DIR")" && exec ./run-all.sh $TUT_ARGS'
  fi
  echo "!! MINGW 下未找到 $CYG_BASH，且无法重入 Cygwin；请设 ISABELLE_WIN_DIR 或直接在 Cygwin Terminal 里运行" >&2
  exit 1
fi

if [[ -z "${ISABELLE:-}" ]]; then
  case "$(uname -s)" in
    Darwin)
      for cand in \
        /Applications/Isabelle2025-2.app/bin/isabelle \
        "$HOME/Applications/Isabelle2025-2.app/bin/isabelle"; do
        [[ -x "$cand" ]] && ISABELLE="$cand" && break
      done ;;
    CYGWIN*)
      for cand in \
        /cygdrive/g/xulun3/isabelle/Isabelle2025-2/bin/isabelle \
        /opt/Isabelle2025-2/bin/isabelle; do
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
# 输出编码统一 UTF-8：Windows 下缺失 LANG 会让 ML writeln 按 ANSI 代码页
# （本机 GBK）转码，标记比对全灭；Linux/macOS 通常已带 UTF-8，此处兜底。
export LANG="${LANG:-en_US.UTF-8}"
# Windows 控制台编码补丁：JDK 18+ 管道 stdout 默认按 native.encoding
# （本机 ANSI=GBK）转码，-Dfile.encoding=UTF-8 管不到它，中文标记会变成
# GBK 字节（bf aa ca bc）导致比对全灭。系统 etc/settings 是无条件赋值盖不动，
# 唯一入口是用户级 settings（ISABELLE_HOME_USER/etc/settings，在系统
# settings 之后执行）。守卫式追加，重复运行不叠加。
US="$USER_HOME/.isabelle/Isabelle2025-2/etc"
if [[ -f "$US/settings" ]] && ! grep -q 'stdout.encoding' "$US/settings"; then
  printf '%s\n' 'ISABELLE_TOOL_JAVA_OPTIONS="$ISABELLE_TOOL_JAVA_OPTIONS -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8"' >> "$US/settings"
elif [[ ! -f "$US/settings" ]]; then
  mkdir -p "$US"
  printf '%s\n' 'ISABELLE_TOOL_JAVA_OPTIONS="-Djava.awt.headless=true -Xms512m -Xmx4g -Xss16m -Dstdout.encoding=UTF-8 -Dstderr.encoding=UTF-8"' > "$US/settings"
fi
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

# --- 从 ROOT 解析「堆 -> 理论列表 -> 目录」三列会话分组 ---------------------
# 扫描 examples/ 及其子目录下所有 ROOT；条目形如
#   session IsaTut = "HOL-Eisbach" +  /  session IsaTutFOL = FOL +
# （父堆可带引号可不带），其后 4 空格缩进行是 theories 名单。
# 输出三列 TSV：堆 <TAB> 理论名 <TAB> 目录。
# BSD awk（macOS）兼容：不用 match 第三参。
parse_root() {
  find "$EXAMPLES" -name ROOT | LC_ALL=C sort | while read -r root; do
    awk -v dir="$(dirname "$root")" '
      /^session / {
        sess = $2
        rest = $0
        sub(/^session +[A-Za-z0-9_-]+ *= */, "", rest)
        if (rest ~ /^"/) { split(rest, a, "\""); heap = a[2] }
        else { split(rest, b, "+"); gsub(/^[ \t]+|[ \t\r]+$/, "", b[1]); heap = b[1] }
        inthy = 0
        next
      }
      /^  theories/ { inthy = 1; next }
      /^  [A-Za-z]/ { inthy = 0; next }
      inthy && /^    [A-Za-z0-9_]+[ \t\r]*$/ {
        gsub(/[ \t\r]/, "", $0)
        print heap "\t" $0 "\t" dir
      }
    ' "$root"
  done
}

ROOTMAP=$(parse_root)
if [[ -z "$ROOTMAP" ]]; then
  echo "!! 未能从 $EXAMPLES/ROOT 解析出任何会话分组" >&2
  exit 1
fi
heaps=$(awk -F'\t' '{print $1}' <<<"$ROOTMAP" | awk '!seen[$0]++')

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
  # 多会话布局：每个含 ROOT 的目录一个 -d（-D 只吃单目录）
  local dflags=""
  local d
  while read -r d; do dflags="$dflags -d $d"; done < <(find "$EXAMPLES" -name ROOT | xargs -n1 dirname | LC_ALL=C sort -u)
  # 每个会话堆一路 process_theories：Draft 会话的父堆由 -l 指定。
  # -l HOL-Eisbach：T27 用了 Eisbach `method` DSL，Draft 会话必须有 HOL-Eisbach
  # 才能装；主线其余章只用 HOL 的定理，父会话是 HOL 的超集，不受影响。
  # -l HOL-Library / FOL / ZF：corec friends、HOL-Library 选讲、FOL/ZF 对象
  # 逻辑章各自的父堆。
  #
  # 三个 -o 是"两遍逐字节可比"的前提，缺一个都不行（三端实测）：
  #   parallel_print=false —— 否则消息按线程异步落地，同一条命令的输出
  #     在两遍里落到不同位置。12/24 个示例的差异全部来自这里，
  #     表现是 value/ML 的打印与证明态的 show ... 行互相移位。
  #   parallel_proofs=0 / threads=1 —— 关掉命令级并行，让执行顺序固定。
  # 实测关掉之后，两遍之间的唯一差异只剩末尾那行
  #   "Finished Draft (... cpu time, factor 0.51)"
  # 的耗时数字，而它在标记区间之外，不参与比对。
  : >"$1/run.log"
  for heap in $heaps; do
    ths=$(awk -F'\t' -v h="$heap" '$1==h {print $2}' <<<"$ROOTMAP")
    local hdir
    hdir=$(awk -F'\t' -v h="$heap" '$1==h {print $3; exit}' <<<"$ROOTMAP")
    "$ISABELLE" process_theories -O -l "$heap" \
      -o parallel_print=false -o parallel_proofs=0 -o threads=1 \
      -H 'T[0-9]{2}_[a-z_]+\.thy' -D "$hdir" $ths \
      >"$1/run-$heap.log" 2>"$1/run-$heap.err" || FAIL=1
    cat "$1/run-$heap.log" >>"$1/run.log"
  done
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
for t in $(awk -F'\t' '{print $2}' <<<"$ROOTMAP"); do
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
