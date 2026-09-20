#!/usr/bin/env bash
# ============================================================
# run-all.sh —— 用 GHC 跑遍所有示例（bash 版，等价于 build.ps1）
#
#   ./run-all.sh              全部示例（运行层 + 测试层）
#   ./run-all.sh 09_lists     单个示例
#
# 判定标准（与 build.ps1 六条一致）：
#   编译退出码 0 / 运行退出码 0 / stderr 空 / stdout 非空且无控制字符 /
#   含结束标记 "==== NN 结束 ====" / 无 GHC 诊断字样
#
# 每个示例目录：ChNN.hs（库）+ main.hs（演示）+ runtests.hs（测试）
# 20/24 为 stack 工程（build + test + exec，宽松判定）
# ============================================================
set -u
cd "$(dirname "$0")"

BUILD=build
mkdir -p "$BUILD"

# ---- 工具定位 ----
GHC_BIN="${GHC:-ghc}"
command -v "$GHC_BIN" >/dev/null 2>&1 || { echo "未找到 ghc（设 GHC 环境变量）"; exit 1; }

# ---- UTF-8 locale 兜底 ----
# macOS/Linux：LANG/LC_* 全空时 GHC 文件句柄退化为 ASCII 编码，写中文会抛
# "cannot encode character" 异常。示例已尽量显式 hSetEncoding utf8（不依赖 locale），
# 此处再兜一层：仅在完全未设时给 UTF-8，不覆盖用户显式的 LANG=C 等选择。
if [ -z "${LC_ALL:-}" ] && [ -z "${LC_CTYPE:-}" ] && [ -z "${LANG:-}" ]; then
    export LANG=en_US.UTF-8
fi

# ---- stack 工程旗标 ----
# stack.yaml 钉了具体 GHC 版本（Windows 实测机为 9.12.1），换机/换系统版本不匹配会
# 报 "No compiler found"。用系统 GHC 版本命令行覆盖，让 20/24 在任意机器都能构建。
STACK_FLAGS=()
if command -v stack >/dev/null 2>&1; then
    STACK_FLAGS=(--system-ghc "--compiler=ghc-$("$GHC_BIN" --numeric-version)")
fi

PASS=0
FAIL=0
FAILED=""
EXTRA_ARGS=()   # 演示参数（02_hello 专用；bash 数组不能走 env 前缀赋值，只能全局传）

# 控制字符检查：TAB/LF/CR 除外（perl 按 UTF-8 读，只拦 <0x20 的非常规字节）
has_ctrl() {
    perl -ne 'exit 1 if /[\x00-\x08\x0B\x0C\x0E-\x1F]/' "$1" 2>/dev/null
}

check_output() { # $1=标签 $2=out文件 $3=err文件 $4=退出码 $5=标记 [$6=relaxed]
    local tag="$1" outf="$2" errf="$3" rc="$4" marker="$5" relaxed="${6:-}"
    local why=""
    [ "$rc" -ne 0 ] && why="退出码 ${rc}；"
    if [ "$relaxed" != "relaxed" ] && [ -s "$errf" ]; then why="${why}stderr 非空；"
    fi
    [ -s "$outf" ] || why="${why}stdout 为空；"
    has_ctrl "$outf" || why="${why}输出含控制字符；"
    grep -qE 'Warning:|error:|rror:|Exception' "$outf" && why="${why}输出含 GHC 诊断字样；"
    grep -qF "$marker" "$outf" || why="${why}缺少结束标记"
    if [ -z "$why" ]; then
        echo "  [OK] $tag"; PASS=$((PASS + 1))
    else
        echo "  [FAIL] $tag —— $why"; FAIL=$((FAIL + 1)); FAILED="$FAILED\n  - $tag"
        [ -s "$errf" ] && { echo "        stderr 前 8 行："; head -8 "$errf" | sed 's/^/        /'; }
        echo "        stdout 最后 8 行："; tail -8 "$outf" | sed 's/^/        /'
    fi
}

# 编译并运行一个 Main：$1=目录 $2=源文件名 $3=exe 名 $4=标记 extra=编译旗标
run_ghc_main() {
    local dir="$1" src="$2" exe="$3" marker="$4"; shift 4
    local name; name="$(basename "$dir")"
    local out="$BUILD/$name.$exe.out" err="$BUILD/$name.$exe.err"
    if ! "$GHC_BIN" -v0 -O0 --make "-i$dir" -outputdir "$BUILD/$name.$exe.obj" \
            "$dir/$src" -o "$BUILD/$name.$exe.exe" "$@" 2>"$err"; then
        echo "  [FAIL] $exe      $name 编译"; FAIL=$((FAIL + 1)); FAILED="$FAILED\n  - $name $exe 编译"
        head -12 "$err" | sed 's/^/        /'
        return 1
    fi
    local rc=0
    (cd "$dir" && "$OLDPWD/$BUILD/$name.$exe.exe" "${EXTRA_ARGS[@]:-}") >"$out" 2>"$err" || rc=$?
    check_output "$exe      $name" "$out" "$err" "$rc" "$marker"
}

test_one() {
    local dir="$1"
    local name; name="$(basename "$dir")"
    local num="${name%%_*}"
    local marker="==== $num 结束 ===="
    echo "==== $name ===="

    # stack 工程
    if [ "$name" = "20_stackenv" ] || [ "$name" = "24_capstone" ]; then
        local exe_name=stackenv
        [ "$name" = "24_capstone" ] && exe_name=minilang
        local out="$BUILD/$name.build.out" err="$BUILD/$name.build.err" rc=0
        (cd "$dir" && stack build "${STACK_FLAGS[@]}") >"$out" 2>"$err" || rc=$?
        if [ "$rc" -ne 0 ]; then
            echo "  [FAIL] build   $name"; FAIL=$((FAIL + 1)); FAILED="$FAILED\n  - $name stack build"
            head -12 "$err" | sed 's/^/        /'; return
        fi
        out="$BUILD/$name.test.out"; err="$BUILD/$name.test.err"; rc=0
        (cd "$dir" && stack test "${STACK_FLAGS[@]}") >"$out" 2>"$err" || rc=$?
        check_output "test     $name (stack test)" "$out" "$err" "$rc" "$marker" relaxed
        out="$BUILD/$name.run.out"; err="$BUILD/$name.run.err"; rc=0
        [ "$name" = "24_capstone" ] && RUN_ARGS="demo"
        (cd "$dir" && stack exec "${STACK_FLAGS[@]}" "$exe_name" -- ${RUN_ARGS:-}) >"$out" 2>"$err" || rc=$?
        RUN_ARGS="" 
        check_output "run      $name (stack exec)" "$out" "$err" "$rc" "$marker" relaxed
        return
    fi

    local flags=()
    [ "$name" = "22_concurrency" ] && flags=(-threaded -rtsopts "-with-rtsopts=-N4")
    if [ "$name" = "02_hello" ]; then
        EXTRA_ARGS=("Haskell" "9.12")
        run_ghc_main "$dir" main.hs run "$marker" "${flags[@]}"
        EXTRA_ARGS=()
    else
        run_ghc_main "$dir" main.hs run "$marker" "${flags[@]}"
    fi
    run_ghc_main "$dir" runtests.hs test "$marker" "${flags[@]}"
}

if [ $# -ge 1 ]; then
    test_one "examples/$1"
else
    for d in examples/*/; do test_one "${d%/}"; done
fi

echo ""
echo "通过 $PASS   失败 $FAIL"
if [ "$FAIL" -eq 0 ]; then echo "全部通过"; exit 0
else echo -e "失败项：$FAILED"; exit 1; fi
