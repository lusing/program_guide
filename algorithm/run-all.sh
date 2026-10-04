#!/usr/bin/env bash
# run-all.sh —— algorithm 教程的 bash 入口
#
# 本教程在 Windows 上验证（MSVC 主线 + scoop clang 交叉核对 + MinGW g++ 探针
# 资格制），判定六条与 build.ps1 完全一致。Windows 上本脚本直接转发给
# build.ps1（两个入口结论必然一致）；非 Windows 平台【声明式跳过】——
# 打印说明后按 0 退出，不假装通过、也不算失败。
set -u
cd "$(dirname "$0")"

case "$(uname -s)" in
  Windows_NT|CYGWIN*|MINGW*|MSYS*)
    if command -v pwsh >/dev/null 2>&1; then
      exec pwsh -NoProfile -File ./build.ps1 "$@"
    elif command -v powershell >/dev/null 2>&1; then
      exec powershell -NoProfile -File ./build.ps1 "$@"
    else
      echo "[env] Windows 上找不到 pwsh/powershell —— 无法验证" >&2
      exit 1
    fi
    ;;
  *)
    echo "[声明式跳过] 本教程仅在 Windows 上验证（MSVC 主线）；非 Windows 平台不参与验证。"
    exit 0
    ;;
esac
