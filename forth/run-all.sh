#!/usr/bin/env bash
# ------------------------------------------------------------
#  一键跑完所有 gforth 示例
#
#  用法：
#    ./run-all.sh              跑全部，只看结果摘要
#    ./run-all.sh -v           跑全部，顺便把每个例子的输出打出来
#    ./run-all.sh 07 15        只跑 07 和 15（写编号前缀即可）
#    ./run-all.sh -v 13        只跑 13，并显示完整输出
#
#  判定标准（三条全绿才算过）：
#    1. 退出码为 0
#    2. stderr 没有任何输出
#    3. 最后一行显示栈为空 <0>
#
#  第 3 条是 Forth 特有的：一个词悄悄在栈上多留一个值，
#  程序照样跑完不报错，但后续代码全被污染。
#  所以每个示例末尾都写了 .s 来兜底。
# ------------------------------------------------------------

set -u

cd "$(dirname "$0")"

VERBOSE=0
SELECT=()
for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=1 ;;
    *)            SELECT+=("$arg") ;;
  esac
done

PASS=0
FAIL=0
FAILED_FILES=()

run_one() {
  local f="$1"
  local out err rc last

  out=$(gforth "$f" 2>/tmp/gforth-runall-err.$$)
  rc=$?
  err=$(cat /tmp/gforth-runall-err.$$)
  rm -f /tmp/gforth-runall-err.$$

  last=$(printf '%s\n' "$out" | grep -v '^[[:space:]]*$' | tail -1)

  local ok=1
  local why=""

  [ $rc -ne 0 ] && { ok=0; why="退出码 $rc"; }
  if [ -n "$err" ]; then
    ok=0
    [ -n "$why" ] && why="$why；"
    why="${why}stderr 有输出"
  fi
  case "$last" in
    *"<0>"*) : ;;
    *) ok=0
       [ -n "$why" ] && why="$why；"
       why="${why}结束时栈非空（$last）" ;;
  esac

  if [ $ok -eq 1 ]; then
    PASS=$((PASS+1))
    printf '  \033[32m✓\033[0m %-28s %s\n' "$(basename "$f")" "$last"
  else
    FAIL=$((FAIL+1))
    FAILED_FILES+=("$f")
    printf '  \033[31m✗\033[0m %-28s %s\n' "$(basename "$f")" "$why"
  fi

  if [ $VERBOSE -eq 1 ]; then
    printf '%s\n' "$out" | sed 's/^/      /'
    [ -n "$err" ] && printf '%s\n' "$err" | sed 's/^/      [stderr] /'
    echo
  fi
}

echo "gforth: $(command -v gforth || echo '没找到')"
echo "版本:   $(gforth --version 2>&1 | head -1)"
echo
echo "开始运行 examples/ 下的示例："
echo

if [ ${#SELECT[@]} -gt 0 ]; then
  for s in "${SELECT[@]}"; do
    matched=$(ls examples/${s}*.fs 2>/dev/null)
    if [ -z "$matched" ]; then
      echo "  没有匹配 examples/${s}*.fs 的文件"
      FAIL=$((FAIL+1))
      continue
    fi
    for f in $matched; do run_one "$f"; done
  done
else
  for f in examples/*.fs; do run_one "$f"; done
fi

echo
echo "────────────────────────────────"
printf '通过 %d   失败 %d\n' "$PASS" "$FAIL"
if [ $FAIL -eq 0 ]; then
  echo "全部通过。"
else
  echo "失败的文件："
  for f in "${FAILED_FILES[@]}"; do echo "  $f"; done
fi
echo "────────────────────────────────"

[ $FAIL -eq 0 ]
