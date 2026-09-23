#!/usr/bin/env bash
# Agda 教程示例验证脚本（Agda 2.8.0 + stdlib 2.3，Linux/WSL）
# 用法:
#   ./build.sh                 # 类型检查全部示例
#   ./build.sh Ex13_induction  # 只检查一个（不带 .agda 后缀）
#   ./build.sh run Ex20_io     # 编译为可执行文件并运行
#   ./build.sh clean           # 清理 _build/
set -euo pipefail
cd "$(dirname "$0")"

AGDA="$(command -v agda)"
EXAMPLES=examples

if [[ ! -f "$AGDA" && -z "$AGDA" ]]; then
  echo "未找到 agda，请安装（apt install agda agda-stdlib 或 cabal install Agda）" >&2
  exit 1
fi

clean() { rm -rf _build; echo "已清理 _build/"; }

typecheck() {
  local f="$1"
  echo "== agda $f"
  "$AGDA" "$EXAMPLES/$f.agda"
}

runmain() {
  local f="$1"
  echo "== agda --compile $f"
  "$AGDA" --compile "$EXAMPLES/$f.agda"
  "$EXAMPLES/$f" | sed 's/^/   | /'
  rm -rf "$EXAMPLES/MAlonzo" "$EXAMPLES/$f"
}

case "${1:-all}" in
  clean) clean ;;
  run)   runmain "${2:?用法: ./build.sh run ExNN_name}" ;;
  all)
    fail=0
    for f in "$EXAMPLES"/Ex*.agda; do
      b="$(basename "$f" .agda)"
      typecheck "$b" || { echo "!! FAIL: $b"; fail=1; }
    done
    [[ $fail -eq 0 ]] && echo "全部示例类型检查通过" || { echo "存在失败示例"; exit 1; }
    ;;
  *) typecheck "$1" ;;
esac
