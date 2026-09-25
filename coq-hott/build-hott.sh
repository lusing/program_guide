#!/usr/bin/env bash
#
# 构建 HoTT 库（一次性，约 3-5 分钟，8 核并行）。
#
# 用法:
#   ./build-hott.sh              # 构建到 $HOTT_SRC/theories 下的 .vo
#   ./build-hott.sh -j 16        # 指定并行度
#   ./build-hott.sh -Clean       # 删除本脚本生成的中间文件（不动 .vo）
#
# 环境变量:
#   HOTT_SRC   HoTT 源码根，默认 /Volumes/mac004/lang/Coq-HoTT
#   COQBIN     coqc 所在目录，默认自动探测（优先 /opt/local/bin）
#
# 为什么不用仓库自带的 Makefile：
#   官方入口是 [make]，它会先跑 [etc/generate_coqproject.sh] 生成 _CoqProject，
#   再调 [coq_makefile]。但仓库里的脚本/Makefile.coq.local 是 CRLF 行尾，
#   bash 5 解析 CRLF 的 [if ... fi] 会报
#       syntax error: unexpected end of file from `if' command
#   所以这里直接用 [coqdep] 生成依赖，再套一个自己写的两行 Makefile 规则。
#
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOTT_SRC="${HOTT_SRC:-/Volumes/mac004/lang/Coq-HoTT}"
BUILD_DIR="$PROJECT_ROOT/build"
DEPS="$BUILD_DIR/hott.deps"
MK="$BUILD_DIR/hott-makefile"

JOBS="$(sysctl -n hw.ncpu 2>/dev/null || echo 4)"

# ---- 参数 ----
while [ $# -gt 0 ]; do
  case "$1" in
    -j) JOBS="$2"; shift 2 ;;
    -Clean)
      rm -f "$DEPS" "$MK"
      echo "[Clean] 已删除中间文件：$DEPS $MK"
      exit 0 ;;
    *) echo "用法: $0 [-j N] [-Clean]"; exit 1 ;;
  esac
done

# ---- 探测工具 ----
find_tool() {
  local name="$1"
  if [ -n "${COQBIN:-}" ] && [ -x "$COQBIN/$name" ]; then
    echo "$COQBIN/$name"; return 0
  fi
  for dir in /opt/local/bin /usr/local/bin /usr/bin; do
    if [ -x "$dir/$name" ]; then echo "$dir/$name"; return 0; fi
  done
  local p
  p="$(command -v "$name" 2>/dev/null || true)"
  if [ -n "$p" ]; then echo "$p"; return 0; fi
  return 1
}

COQC="$(find_tool coqc)"    || { echo "错误：找不到 coqc"; exit 1; }
COQDEP="$(find_tool coqdep)" || { echo "错误：找不到 coqdep"; exit 1; }
MAKE="$(find_tool gmake || find_tool make)" || { echo "错误：找不到 make"; exit 1; }

if [ ! -d "$HOTT_SRC/theories" ]; then
  echo "错误：HOTT_SRC 下没有 theories/：$HOTT_SRC"
  echo "      可用 HOTT_SRC=/path/to/Coq-HoTT $0 指定。"
  exit 1
fi

echo "[HoTT] 源码根   : $HOTT_SRC"
echo "[HoTT] coqc     : $("$COQC" --version 2>&1 | head -1)"
echo "[HoTT] 并行度   : $JOBS"

mkdir -p "$BUILD_DIR"
cd "$HOTT_SRC" || exit 1

# ---- 1. 生成依赖 ----
echo "[HoTT] coqdep ..."
mapfile -t VFILES < <(find theories -type f -name '*.v' | LC_ALL=C sort)
if [ "${#VFILES[@]}" -eq 0 ]; then
  echo "错误：theories/ 下没有 .v 文件"; exit 1
fi
"$COQDEP" -R theories HoTT "${VFILES[@]}" > "$DEPS" 2>/dev/null
echo "[HoTT] 依赖条目 : $(wc -l < "$DEPS" | tr -d ' ')"

# ---- 2. 自制 Makefile ----
# 只编译 theories/（HoTT 库本体）；contrib/ 与 test/ 不在教程范围内，
# 且 contrib 里有文件需要 Stdlib，在 -noinit 下取不到。
{
  echo "COQC ?= $COQC"
  echo 'COQFLAGS = -q -noinit -indices-matter -R theories HoTT'
  echo '%.vo: %.v'
  printf '\t$(COQC) $(COQFLAGS) $<\n'
  echo ''
  cat "$DEPS"
} > "$MK"

# ---- 3. 并行编译 ----
echo "[HoTT] 编译中（首次约 3-5 分钟）..."
VOFILES="$(printf '%s\n' "${VFILES[@]}" | sed 's/\.v$/.vo/')"

# 注意：Makefile 里的 recipe 用制表符缩进，不能让 shell 做单词切分出错，
# 这里故意把目标列表交给 make 自己去排依赖顺序。
printf '%s\n' "$VOFILES" > "$BUILD_DIR/hott-targets.txt"

if "$MAKE" -f "$MK" -j"$JOBS" -k $(printf '%s\n' "$VOFILES" | tr '\n' ' ') \
     > "$BUILD_DIR/hott-build.log" 2>&1; then
  echo "[HoTT] 构建完成。"
else
  echo "[HoTT] 构建过程有错误输出，日志：$BUILD_DIR/hott-build.log"
  grep -n "^Error" "$BUILD_DIR/hott-build.log" | head -20
  exit 1
fi

VO_COUNT="$(find theories -name '*.vo' | wc -l | tr -d ' ')"
V_COUNT="${#VFILES[@]}"
echo "[HoTT] .vo 数量  : $VO_COUNT / $V_COUNT"
if [ "$VO_COUNT" -lt "$V_COUNT" ]; then
  echo "[HoTT] 警告：有文件没编译出来。"
  exit 1
fi
echo "[HoTT] 全部就绪。现在可以跑 ./run-all.sh"
