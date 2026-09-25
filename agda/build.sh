#!/usr/bin/env bash
# Agda 教程示例验证脚本（macOS 实测：Agda 2.9.0 + agda-stdlib 3.0；Linux/WSL 同样适用）
# 用法:
#   ./build.sh                 # 类型检查全部示例
#   ./build.sh Ex13_induction  # 只检查一个（不带 .agda 后缀）
#   ./build.sh run Ex20_io     # 编译为可执行文件并运行
#   ./build.sh clean           # 清理 _build/
set -euo pipefail
cd "$(dirname "$0")"

# Agda 的输出/警告包含 Unicode 记号（≟、ℕ、≤ 等），
# 在非 UTF-8 locale 下打印时会报 commitAndReleaseBuffer 编码错误。
case "${LC_ALL:-${LANG:-}}" in
  *UTF-8*|*utf8*) ;;
  *) export LC_ALL=en_US.UTF-8 ;;
esac

# 定位 agda：先看 PATH，再试常见安装位置（stack / cabal / ghcup / Homebrew / 系统）。
AGDA="$(command -v agda 2>/dev/null || true)"
if [[ -z "$AGDA" ]]; then
  for cand in "$HOME/.stack-home/bin/agda" "$HOME/.local/bin/agda" \
              "$HOME/.cabal/bin/agda" "$HOME/.ghcup/bin/agda" \
              /Volumes/*/.stack-home/bin/agda \
              /opt/homebrew/bin/agda /usr/local/bin/agda /usr/bin/agda; do
    if [[ -x "$cand" ]]; then AGDA="$cand"; break; fi
  done
fi
if [[ -z "$AGDA" ]]; then
  echo "未找到 agda，请安装（apt install agda agda-stdlib 或 cabal install Agda）并加入 PATH" >&2
  exit 1
fi
echo "使用 Agda: $AGDA"
EXAMPLES=examples

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
