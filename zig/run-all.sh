#!/usr/bin/env bash
# Linux/macOS 全量回归:镜像 build.ps1 的三层验证(fmt --check → test → build-exe → 运行)
# 用法:./run-all.sh [示例名]   例如 ./run-all.sh 12_collections ;不带参数则全量
set -u
cd "$(dirname "$0")"

ZIG_BIN="${ZIG:-}"
if [ -z "$ZIG_BIN" ]; then
    if command -v zig >/dev/null 2>&1; then
        ZIG_BIN="$(command -v zig)"
    else
        echo "未找到 zig:请安装 0.16.0,或用 ZIG=/path/to/zig $0 指定" >&2
        exit 1
    fi
fi
echo "[Toolchain] $ZIG_BIN ($("$ZIG_BIN" version))"

BUILD_DIR="$PWD/build"
EXAMPLES_DIR="$PWD/examples"
mkdir -p "$BUILD_DIR"

FAILURES=()

run_zig() { # run_zig <工作目录> <参数...>
    local dir="$1"; shift
    (cd "$dir" && "$ZIG_BIN" "$@")
}

# 普通示例三层验证:fmt --check → test → build-exe → 运行
# ExtraArgs(如 -lc)只传给 test 与 build-exe,fmt 不接受链接参数
test_plain_example() { # test_plain_example <目录> [额外参数...]
    local dir="$1"; shift
    local name; name="$(basename "$dir")"
    echo ""
    echo "[Example] $name"
    run_zig "$dir" fmt --check . || return 1
    run_zig "$dir" test main.zig "$@" || return 1
    run_zig "$dir" build-exe main.zig -femit-bin="$BUILD_DIR/$name" "$@" || return 1
    "$BUILD_DIR/$name" || return 1
}

# build.zig 工程:fmt --check . → build test → build run
test_project_example() { # test_project_example <目录>
    local dir="$1"
    local name; name="$(basename "$dir")"
    echo ""
    echo "[Example] $name (build.zig 工程)"
    run_zig "$dir" fmt --check . || return 1
    run_zig "$dir" build test || return 1
    run_zig "$dir" build run || return 1
}

# 18_cross:本机三层 + 三目标交叉编译(编译即验证)+ zig cc 编 C
test_cross_example() { # test_cross_example <目录>
    local dir="$1"
    local name; name="$(basename "$dir")"
    echo ""
    echo "[Example] $name (交叉编译)"
    run_zig "$dir" fmt --check . || return 1
    run_zig "$dir" test main.zig || return 1
    run_zig "$dir" build-exe main.zig -femit-bin="$BUILD_DIR/$name" || return 1
    "$BUILD_DIR/$name" || return 1
    run_zig "$dir" build-exe main.zig -target aarch64-linux \
        -femit-bin="$BUILD_DIR/${name}_aarch64-linux" || return 1
    run_zig "$dir" build-lib wasm_lib.zig -target wasm32-freestanding \
        -femit-bin="$BUILD_DIR/$name.wasm" || return 1
    run_zig "$dir" cc hello.c -o "$BUILD_DIR/${name}_hello_c" || return 1
    "$BUILD_DIR/${name}_hello_c" || return 1
}

test_one() { # test_one <目录>
    local dir="$1"
    case "$(basename "$dir")" in
        16_build | 24_minigrep) test_project_example "$dir" ;;
        17_cinterop) test_plain_example "$dir" -lc ;;
        18_cross) test_cross_example "$dir" ;;
        *) test_plain_example "$dir" ;;
    esac
}

if [ "${1:-}" != "" ]; then
    dir="$EXAMPLES_DIR/$1"
    if [ ! -d "$dir" ]; then
        echo "找不到示例目录: $dir" >&2
        exit 1
    fi
    test_one "$dir" && echo "" && echo "[Done] $1 验证通过。" || exit 1
    exit $?
fi

for dir in "$EXAMPLES_DIR"/*/; do
    name="$(basename "$dir")"
    if ! test_one "$dir"; then
        FAILURES+=("$name")
        echo "[FAIL] $name" >&2
    fi
done

echo ""
if [ "${#FAILURES[@]}" -eq 0 ]; then
    echo "[Done] 全部示例三层验证通过。"
else
    echo "[Done] 失败示例: ${FAILURES[*]}" >&2
    exit 1
fi
