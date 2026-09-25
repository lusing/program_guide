#!/bin/bash
# ============================================================
# build-att.sh - AT&T(GNU as) 版示例的汇编 + 链接 + 运行
# ============================================================
# 在 WSL（或任意 Linux）中执行：
#   ./build-att.sh            # 全部
#   ./build-att.sh 01         # 只跑 01 类
# 依赖：as、gcc（glibc）。含 att_io.inc 的示例需 -I lib-att。
# ============================================================
set -u
cd "$(dirname "$0")"
mkdir -p build-att

ok=0; bad=0; total=0

build_one() {
    src="$1"
    name=$(basename "$src" .s)
    obj="build-att/$name.o"
    exe="build-att/$name"
    total=$((total+1))
    if ! as -I lib-att -o "$obj" "$src" 2> "build-att/$name.err"; then
        echo "[FAIL:as] $name"
        head -3 "build-att/$name.err"
        bad=$((bad+1))
        return
    fi
    extra=""
    case "$src" in
        *11_calculus_mkl*) extra="-lm -lmvec";;
        *test_link*) extra="-e _start -nostartfiles";;
    esac
    if ! gcc -no-pie -o "$exe" "$obj" $extra 2>> "build-att/$name.err"; then
        echo "[FAIL:ld] $name"
        head -3 "build-att/$name.err"
        bad=$((bad+1))
        return
    fi
    "./$exe" > "build-att/$name.out" 2>&1
    rc=$?
    if [ $rc -ne 0 ]; then
        echo "[FAIL:run rc=$rc] $name"
        head -3 "build-att/$name.out"
        bad=$((bad+1))
        return
    fi
    ok=$((ok+1))
}

if [ "${1:-all}" = "all" ]; then
    for f in $(find examples-att -name "*.s" | sort); do
        build_one "$f"
    done
else
    for f in $(find "examples-att/${1}"* -name "*.s" | sort); do
        build_one "$f"
    done
fi

echo "=========================================="
echo "  AT&T 构建汇总: 总计 $total, 成功 $ok, 失败 $bad"
echo "=========================================="
[ $bad -gt 0 ] && exit 1
exit 0
