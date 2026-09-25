#!/usr/bin/env bash
#
# Coq-HoTT 教程全量验证脚本。
#
# 用法:
#   ./run-all.sh            验证 examples/ 下全部示例
#   ./run-all.sh 03         只验证 03 章示例
#   ./run-all.sh -Clean     清理 build/（不动 HoTT 库的 .vo）
#
# 环境变量:
#   HOTT_SRC   HoTT 源码根，默认 /Volumes/mac004/lang/Coq-HoTT
#   COQBIN     coqc 所在目录
#
# 判定标准（每条示例都要全部满足）:
#   1. coqc 退出码 0
#   2. stderr 为空（0 字节）—— 连警告都不许有
#   3. 标记行 [sec_NN_BEGIN] / [sec_NN_END] 各恰好出现一次（整行严格相等）
#   4. 标记圈出的区间非空
#   5. 区间里没有控制字符
#   6. 同一文件连跑两遍，区间逐字节一致（Coq 是单引擎，用运行间确定性代替跨通道比对）
#   7. 至少有一个示例被验证（杜绝「通过 0」的假绿）
#   8. 全量模式下追加文档机器核查（build/check-docs.py，五关：
#      节号对应 / 输出行逐字节可溯 / 坑位数一致 / 导航链 / CHEATSheet 引用）
#
set -uo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOTT_SRC="${HOTT_SRC:-/Volumes/mac004/lang/Coq-HoTT}"
EXAMPLES_DIR="$PROJECT_ROOT/examples"
BUILD_DIR="$PROJECT_ROOT/build"
RUN1="$BUILD_DIR/run1"
RUN2="$BUILD_DIR/run2"
OUT_DIR="$BUILD_DIR/out"

ONLY=""
CLEAN=0
while [ $# -gt 0 ]; do
  case "$1" in
    -Clean) CLEAN=1; shift ;;
    *) ONLY="$1"; shift ;;
  esac
done

if [ "$CLEAN" -eq 1 ]; then
  rm -rf "$BUILD_DIR/run1" "$BUILD_DIR/run2" "$BUILD_DIR/out" "$BUILD_DIR/examples"
  echo "[Clean] 已清理 $BUILD_DIR 下的验证产物（hott.deps / hott-build.log 保留）。"
  exit 0
fi

# ---- 工具探测（不硬编码路径） ----
find_tool() {
  local name="$1"
  if [ -n "${COQBIN:-}" ] && [ -x "$COQBIN/$name" ]; then echo "$COQBIN/$name"; return 0; fi
  for dir in /opt/local/bin /usr/local/bin /usr/bin; do
    [ -x "$dir/$name" ] && { echo "$dir/$name"; return 0; }
  done
  local p; p="$(command -v "$name" 2>/dev/null || true)"
  [ -n "$p" ] && { echo "$p"; return 0; }
  return 1
}

if ! COQC="$(find_tool coqc)"; then
  echo "错误：找不到 coqc。请用 COQBIN=... 指定所在目录。"; exit 1
fi

# ---- HoTT 库是否就绪 ----
if [ ! -f "$HOTT_SRC/theories/HoTT.vo" ]; then
  echo "错误：HoTT 库尚未构建（缺少 $HOTT_SRC/theories/HoTT.vo）。"
  echo "      请先运行： ./build-hott.sh"
  exit 1
fi

# ---- 收集目标 ----
if [ -n "$ONLY" ]; then
  mapfile -t TARGETS < <(ls "$EXAMPLES_DIR"/"$ONLY"_*.v 2>/dev/null)
else
  mapfile -t TARGETS < <(ls "$EXAMPLES_DIR"/[0-9][0-9]_*.v 2>/dev/null | LC_ALL=C sort)
fi

if [ "${#TARGETS[@]}" -eq 0 ] || [ -z "${TARGETS[0]}" ]; then
  echo "错误：没有找到任何示例文件（目标数 0）——不要把它当成「通过」。"
  exit 1
fi
echo "[Info] 待验证示例 : ${#TARGETS[@]} 个"
echo "[Info] coqc       : $("$COQC" --version 2>&1 | head -1)"
echo "[Info] HoTT 库    : $HOTT_SRC/theories"

rm -rf "$RUN1" "$RUN2" "$OUT_DIR"
mkdir -p "$RUN1" "$RUN2" "$OUT_DIR"

COQFLAGS=(-q -noinit -indices-matter -R "$HOTT_SRC/theories" HoTT)

PASS=0
FAIL=0
FAILED_LIST=()

# 抽取 [BEGIN, END) 区间；计数另行统计
extract_section() {
  awk -v b="$1" -v e="$2" '
    $0 == b { ins = 1; next }
    $0 == e { ins = 0; next }
    ins { print }
  ' "$3"
}

count_line() {
  grep -c "^$1\$" "$2" || true
}

for src in "${TARGETS[@]}"; do
  base="$(basename "$src")"
  stem="${base%.v}"
  nn="${stem%%_*}"
  ex="ex_$base"
  bmark="sec_${nn}_BEGIN"
  emark="sec_${nn}_END"

  cp "$src" "$RUN1/$ex"
  cp "$src" "$RUN2/$ex"

  ( cd "$RUN1" && "$COQC" "${COQFLAGS[@]}" "$ex" ) > "$OUT_DIR/$nn.run1.out" 2> "$OUT_DIR/$nn.run1.err"
  rc1=$?
  ( cd "$RUN2" && "$COQC" "${COQFLAGS[@]}" "$ex" ) > "$OUT_DIR/$nn.run2.out" 2> "$OUT_DIR/$nn.run2.err"
  rc2=$?

  err1_size="$(wc -c < "$OUT_DIR/$nn.run1.err" | tr -d ' ')"
  err2_size="$(wc -c < "$OUT_DIR/$nn.run2.err" | tr -d ' ')"

  bc1="$(count_line "$bmark" "$OUT_DIR/$nn.run1.out")"
  ec1="$(count_line "$emark" "$OUT_DIR/$nn.run1.out")"

  extract_section "$bmark" "$emark" "$OUT_DIR/$nn.run1.out" > "$OUT_DIR/$nn.sec1"
  extract_section "$bmark" "$emark" "$OUT_DIR/$nn.run2.out" > "$OUT_DIR/$nn.sec2"

  lines="$(wc -l < "$OUT_DIR/$nn.sec1" | tr -d ' ')"
  if LC_ALL=C grep -q '[[:cntrl:]]' "$OUT_DIR/$nn.sec1"; then ctrl=1; else ctrl=0; fi
  if cmp -s "$OUT_DIR/$nn.sec1" "$OUT_DIR/$nn.sec2"; then same=1; else same=0; fi

  why=""
  [ "$rc1" -ne 0 ] && why="$why 退出码(run1)=$rc1;"
  [ "$rc2" -ne 0 ] && why="$why 退出码(run2)=$rc2;"
  [ "$err1_size" -ne 0 ] && why="$why stderr(run1)非空=${err1_size}B;"
  [ "$err2_size" -ne 0 ] && why="$why stderr(run2)非空=${err2_size}B;"
  [ "$bc1" -ne 1 ] && why="$why BEGIN标记出现${bc1}次(应为1);"
  [ "$ec1" -ne 1 ] && why="$why END标记出现${ec1}次(应为1);"
  [ "$lines" -eq 0 ] && why="$why 区间为空;"
  [ "$ctrl" -ne 0 ] && why="$why 区间含控制字符;"
  [ "$same" -ne 1 ] && why="$why 两遍区间不一致;"

  if [ -z "$why" ]; then
    printf '  通过  %-28s 区间 %4d 行\n' "$stem" "$lines"
    PASS=$((PASS + 1))
  else
    printf '  失败  %-28s %s\n' "$stem" "$why"
    FAIL=$((FAIL + 1))
    FAILED_LIST+=("$stem")
  fi
done

echo "------------------------------------------------------------"
# 注意：bash 5 下 "$PASS，" 里的全角逗号会被吞进变量名（$PASS，），
# 所以这里一律写 ${PASS} / ${FAIL} 的花括号形式。
echo "通过 ${PASS} 个，失败 ${FAIL} 个"

if [ "${PASS}" -eq 0 ]; then
  echo "错误：一个都没通过（通过 0）——检查脚本或环境，不要当成干净。"
  exit 1
fi
if [ "${FAIL}" -ne 0 ]; then
  echo "失败列表：${FAILED_LIST[*]}"
  exit 1
fi
echo "全部示例验证通过。"

# ---- 文档机器核查（仅全量模式；缺 python3 则显式跳过，不静默放过） ----
if [ -z "$ONLY" ]; then
  if PY="$(find_tool python3)"; then
    echo "------------------------------------------------------------"
    echo "[Docs] $PY $PROJECT_ROOT/build/check-docs.py"
    if ! "$PY" "$PROJECT_ROOT/build/check-docs.py"; then
      echo "错误：文档机器核查未通过（见上）。"
      exit 1
    fi
  else
    echo "[Docs] 跳过：找不到 python3（文档核查未执行，此非「通过」）。"
  fi
fi
