#!/usr/bin/env bash
# FreeBASIC 教程统一验证（Git Bash 入口，与 build.ps1 判定等价）：
#   每示例双层（-g -exx 断言+边界检查 / 发布形态）× 四条判定（退出码 0 / stderr 空 / stdout 非空 / 含 [OK]）
#   注意：1.10.1 实测 Assert 由 -g 激活（老文档说 -e/-exx，已过时）
set -euo pipefail
cd "$(dirname "$0")"

FBC="G:/scoop/apps/freebasic/current/fbc.exe"
[ -x "$FBC" ] || FBC="$(command -v fbc)" || true
[ -x "$FBC" ] || { echo "未找到 fbc.exe" >&2; exit 1; }
mkdir -p build

fail() { echo "[FAIL] $*" >&2; exit 1; }

run_judged() {  # $1=exe(绝对) $2=workdir $3=label
    local exe="$1" dir="$2" label="$3" out err
    err="$(mktemp)"
    out="$(cd "$dir" && timeout 60 "$exe" 2>"$err")" || fail "$label 退出码非 0"
    [ -s "$err" ] && { cat "$err" >&2; fail "$label stderr 非空"; }
    [ -z "$out" ] && fail "$label stdout 为空"
    grep -q '\[OK\]' <<<"$out" || fail "$label 缺少 [OK] 标记"
    echo "    [$label] OK"
    rm -f "$err"
}

compile_run() {  # $1=dir  层循环内复用
    local dir="$1" name srcs layer flags exe
    name="$(basename "$dir")"
    echo ""
    echo "[Example] $name"
    srcs=()
    local f base
    for f in "$dir"/*.bas; do
        base="$(basename "$f")"
        [ "$base" = "legacy_qb.bas" ] && continue
        srcs+=("$f")
    done
    [ "${#srcs[@]}" -gt 0 ] || fail "$dir 下没有 .bas"
    for layer in "-g -exx" ""; do
        flags=(-w all)
        if [ -n "$layer" ]; then
            read -ra extra <<< "$layer"     # "-g -exx" 拆成两个参数
            flags+=("${extra[@]}")
        fi
        exe="$(pwd)/build/${name}.exe"
        "$FBC" "${flags[@]}" "${srcs[@]}" -x "$exe" 2>build/fbc_diag.txt || { cat build/fbc_diag.txt >&2; fail "$name $layer 编译失败"; }
        [ -s build/fbc_diag.txt ] && { cat build/fbc_diag.txt >&2; fail "$name $layer 编译有诊断输出"; }
        run_judged "$exe" "$dir" "$name $layer"
    done
    if [ "$name" = "22_langs" ]; then
        exe="$(pwd)/build/22_langs_qb.exe"
        "$FBC" -lang qb -w none "$dir/legacy_qb.bas" -x "$exe" 2>build/fbc_diag.txt || { cat build/fbc_diag.txt >&2; fail "$name qb 编译失败"; }
        [ -s build/fbc_diag.txt ] && { cat build/fbc_diag.txt >&2; fail "$name qb 编译有诊断输出"; }
        run_judged "$exe" "$dir" "$name -lang qb"
    fi
}

if [ "${1:-}" = "-Clean" ]; then
    rm -rf build
    echo "[Clean] 已清理 build 目录。"
    exit 0
fi

if [ "${1:-}" = "-Example" ] && [ -n "${2:-}" ]; then
    compile_run "examples/$2"
    echo ""
    echo "[Done] $2 验证通过。"
    exit 0
fi

for dir in examples/*/; do
    compile_run "${dir%/}"
done
echo ""
echo "[Done] 全部示例验证通过。"
