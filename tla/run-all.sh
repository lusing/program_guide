#!/usr/bin/env bash
# ------------------------------------------------------------
#  一键跑完所有 TLA+ / PlusCal 示例
#
#  用法：
#    ./run-all.sh              跑全部，只看结果摘要
#    ./run-all.sh -v           跑全部，顺便把每个例子的 TLC 输出打出来
#    ./run-all.sh 05 13        只跑 05 和 13（写编号前缀即可）
#    ./run-all.sh -v 11        只跑 11，并显示完整输出
#
#  判定标准：
#    · 普通示例：TLC 退出码 0 且报告 "No error has been found"
#    · 反例演示（DEMO_ERROR 列表里的）：TLC 必须“抓到”我们故意写错
#      的那条性质——抓到 = 通过（这正是模型检查的价值）。
#
#  每个 .tla 都配一个同名 .cfg（TLC 的模型配置：INIT/NEXT/INVARIANT/
#  CONSTANT 赋值）。若 .tla 里含 PlusCal 算法块，先调 pcal.trans 翻译，
#  再交给 TLC。
# ------------------------------------------------------------

set -u
cd "$(dirname "$0")"

# 工具箱自带的 tla2tools.jar；可用环境变量 TLA_TOOLS_JAR 覆盖
JAR="${TLA_TOOLS_JAR:-/Applications/TLA+ Toolbox 2.app/Contents/Eclipse/tla2tools.jar}"
if [[ ! -f "$JAR" ]]; then
  echo "找不到 tla2tools.jar（$JAR）" >&2
  echo "请设 TLA_TOOLS_JAR 指向你机器上的 tla2tools.jar" >&2
  exit 2
fi

JAVA_OPTS=(-XX:+UseParallelGC)

# 这些示例是“故意写错性质、让 TLC 抓反例”的演示——抓到才算通过
#   Ch08 计数器越界、Ch13 水壶问题（用反例当“求解器”找出 4 加仑配方）、
#   Ch17 竞态导致丢更新
DEMO_ERROR=( Ch08Counterexample Ch13DieHard Ch17RaceCondition )

is_demo_error() {
  local base="$1"
  for d in "${DEMO_ERROR[@]}"; do [[ "$base" == "$d" ]] && return 0; done
  return 1
}

VERBOSE=0
SELECT=()
for arg in "$@"; do
  case "$arg" in
    -v|--verbose) VERBOSE=1 ;;
    *)            SELECT+=("$arg") ;;
  esac
done

wanted() {
  # 示例名形如 Ch07SafetyLiveness；用编号子串匹配（./run-all.sh 07）
  local f="$1"
  [[ ${#SELECT[@]} -eq 0 ]] && return 0
  for s in "${SELECT[@]}"; do [[ "$f" == *"$s"* ]] && return 0; done
  return 1
}

PASS=0; FAIL=0; FAILED=()
WORK="$(pwd)/.run-all-states"

for spec in examples/*.tla; do
  base="$(basename "$spec" .tla)"
  wanted "$base" || continue

  cfg="examples/${base}.cfg"
  # 没有 .cfg 的 .tla 视为「库模块」（被别的示例 INSTANCE/EXTENDS），跳过不单独跑
  [[ -f "$cfg" ]] || continue

  # 工作目录：把 examples 下所有 .tla 都拷进去，保证 INSTANCE/EXTENDS 本地模块可解析；
  # TLC 生成的中间状态文件也隔离在这里。
  rm -rf "$WORK/$base"; mkdir -p "$WORK/$base"
  cp examples/*.tla "$WORK/$base/"
  if grep -qE -- '--algorithm|--fair algorithm' "$spec"; then
    # PlusCal：先翻译（pcal.trans 就地把算法块展开成 TLA+，并写一个默认 .cfg），
    # 之后**强制用我们自带的 .cfg 覆盖**——默认 cfg 不含我们的 INVARIANT/PROPERTY。
    java "${JAVA_OPTS[@]}" -cp "$JAR" pcal.trans "$WORK/$base/${base}.tla" >/dev/null 2>&1 || true
    cp "$cfg" "$WORK/$base/"
  else
    cp "$cfg" "$WORK/$base/"
  fi
  # PlusCal 算法可能 EXTENDS 别的模块，这里保持自包含即可

  out="$(java "${JAVA_OPTS[@]}" -cp "$JAR" tlc2.TLC -workers auto -cleanup "$WORK/$base/${base}.tla" 2>&1)"
  rc=$?

  ok=0
  if is_demo_error "$base"; then
    # 反例演示：期望 TLC 报错（违反不变式 / 死锁 / 时序属性失败）
    echo "$out" | grep -qE 'is violated|Error:|Invariant .* is violated|Temporal|deadlock' && ok=1
  else
    echo "$out" | grep -q 'No error has been found' && [[ $rc -eq 0 ]] && ok=1
  fi

  if [[ $ok -eq 1 ]]; then
    PASS=$((PASS+1)); status="PASS"
  else
    FAIL=$((FAIL+1)); FAILED+=("$base"); status="FAIL"
  fi

  printf '[%s] %s\n' "$status" "$base"
  if [[ $VERBOSE -eq 1 || $ok -eq 0 ]]; then
    echo "$out" | sed 's/^/      | /'
    echo
  fi
done

rm -rf "$WORK"
echo "------------------------------------------------------------"
echo "通过 ${PASS}，失败 ${FAIL}"
if [[ $FAIL -gt 0 ]]; then
  printf '失败示例：'; printf '%s ' "${FAILED[@]-}"; echo
  exit 1
fi
