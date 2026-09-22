#!/usr/bin/env bash
# ============================================================
# run-all.sh —— SDL2 教程统一验证入口（shell 版，判定与 build.ps1 对齐）
#
#   ./run-all.sh              跑全部示例，只打印摘要
#   ./run-all.sh -v           附带每个示例的区间输出
#   ./run-all.sh 02 06        只跑指定编号（两位数字或文件名均可）
#   ./run-all.sh --one        只跑 shared 一条通道（省一半时间）
#
# 通道：同一份源码分别用两种方式链接 SDL2
#   shared  -lSDL2                        动态链接（运行时按 rpath/安装前缀找 dylib）
#   static  sdl2-config --static-libs     静态链接（含 Cocoa/CoreAudio/CoreVideo…）
# 两个产物由同一份源码编译，所以「跨通道逐字节一致」检验的不是两种语义，
# 而是**示例有没有偷偷依赖动态库加载或安装前缀**。
# macOS 上这两条通道的编译命令差别极大：静态链接必须显式带 frameworks，
# 否则 libSDL2.a 里的 Objective-C 符号（objc_msgSend 等）全部找不到——
# 这是本仓库实测到的头号 macOS 差异，见 README「平台差异速查」。
#
# 判定标准（每条通道都要过）：
#   1. 编译退出码 0，且编译期 stderr 为空（-Wall -Wextra 下任何告警即失败）
#   2. 运行退出码 0
#   3. 运行 stderr 为空
#   4. stdout 里同时出现 "==== NN 开始 ====" 与 "==== NN 结束 ===="
#   5. 两标记之间的区间非空，且不含 \r 或 ESC
#   6. 同一条通道连跑两次，区间逐字节一致（抓帧长、线程调度、设备枚举等抖动）
#   7. 两条通道抽出的区间逐字节一致
#
# 工具链一律探测、不硬编码路径；缺 sdl2-config 时退回 pkg-config sdl2，
# 再退回 /opt/local 手工拼参数。都拿不到就不猜，直接报环境缺口退出。
# 运行一律带超时，免得一个不返回的示例把整个回归挂住。
# ============================================================
set -u
cd "$(dirname "$0")" || exit 1

PROJECT_ROOT=$(pwd)
BUILD_DIR="$PROJECT_ROOT/build"
EXAMPLES_DIR="$PROJECT_ROOT/examples"

VERBOSE=0
CHANNELS=(shared static)
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        --one)        CHANNELS=(shared) ;;
        -h|--help)    sed -n '2,34p' "$0"; exit 0 ;;
        *)            SELECT+=("$arg") ;;
    esac
done

# ------------------------------------------------------------
# 工具探测：find_tool <name> [候选绝对路径...]
# ------------------------------------------------------------
find_tool() {
    local name="$1"; shift
    local hit c
    hit=$(command -v "$name" 2>/dev/null) && { printf '%s\n' "$hit"; return 0; }
    for c in "$@"; do
        if [ -x "$c" ]; then printf '%s\n' "$c"; return 0; fi
    done
    return 1
}

CXX=$(find_tool clang++ /opt/local/bin/clang++ /usr/bin/clang++ \
                c++ /usr/bin/c++ g++ /opt/local/bin/g++) || CXX=""
TIMEOUT=$(find_tool gtimeout /opt/local/bin/gtimeout /usr/local/bin/gtimeout \
                    timeout /usr/bin/timeout) || TIMEOUT=""
SDL2CONFIG=$(find_tool sdl2-config /opt/local/bin/sdl2-config /usr/local/bin/sdl2-config) || SDL2CONFIG=""
PKGCONFIG=$(find_tool pkg-config /opt/local/bin/pkg-config /usr/local/bin/pkg-config) || PKGCONFIG=""

RUN_LIMIT=20            # 单个示例的墙钟上限（秒）
WARN="-Wall -Wextra"
STD="-std=c++20"

if [ -z "$CXX" ]; then
    echo "[环境缺口] 找不到 C++ 编译器（clang++/c++/g++）。请先安装 Xcode CLT：xcode-select --install"
    exit 2
fi
if [ -z "$SDL2CONFIG" ] && [ -z "$PKGCONFIG" ]; then
    echo "[环境缺口] 找不到 sdl2-config 与 pkg-config，无法定位 SDL2 头文件与库。"
    echo "           macOS 安装方式：sudo port install libsdl2"
    exit 2
fi

# ------------------------------------------------------------
# 编译/链接参数：sdl2-config 优先，否则 pkg-config
# ------------------------------------------------------------
CFLAGS=""
LIBS_SHARED=""
LIBS_STATIC=""
if [ -n "$SDL2CONFIG" ]; then
    CFLAGS=$("$SDL2CONFIG" --cflags)
    LIBS_SHARED=$("$SDL2CONFIG" --libs)
    LIBS_STATIC=$("$SDL2CONFIG" --static-libs)
elif [ -n "$PKGCONFIG" ]; then
    if ! "$PKGCONFIG" --exists sdl2; then
        echo "[环境缺口] pkg-config 找不到 sdl2.pc。"
        exit 2
    fi
    CFLAGS=$("$PKGCONFIG" --cflags sdl2)
    LIBS_SHARED=$("$PKGCONFIG" --libs sdl2)
    LIBS_STATIC=$("$PKGCONFIG" --libs --static sdl2)
fi
[ -n "$LIBS_STATIC" ] || LIBS_STATIC="$LIBS_SHARED"

echo "== 工具链 =="
echo "   CXX          : $CXX ($("$CXX" --version 2>/dev/null | head -1))"
echo "   SDL2 config  : ${SDL2CONFIG:-（用 pkg-config）}"
echo "   SDL2 version : ${SDL2CONFIG:+$(("$SDL2CONFIG" --version) 2>/dev/null)}"
echo "   CFLAGS       : $CFLAGS"
echo "   LIBS(shared) : $LIBS_SHARED"
echo "   LIBS(static) : $LIBS_STATIC"
echo "   TIMEOUT      : ${TIMEOUT:-（无，不设上限）} / ${RUN_LIMIT}s"
echo

# 只清自己会写的两个子目录，build/ 下的其它证据文件（反例记录等）保留
rm -rf "$BUILD_DIR/shared" "$BUILD_DIR/static"
mkdir -p "$BUILD_DIR"

# ------------------------------------------------------------
# 反例记录：证明 macOS 静态链接**必须**带 frameworks
# 故意用裸 libSDL2.a（不带 -framework）链接一次，把失败输出留档，
# 供文档引用——「为什么必须用 sdl2-config --static-libs」要有可复现的证据。
# ------------------------------------------------------------
STATIC_A=$(printf '%s\n' "$LIBS_STATIC" | grep -o '[^ ]*\.a' | head -1)
if [ -n "$STATIC_A" ] && [ -f "$STATIC_A" ]; then
    # shellcheck disable=SC2086
    "$CXX" $STD "$EXAMPLES_DIR/01_init_version.cpp" -o "$BUILD_DIR/no_frameworks_probe" \
        $CFLAGS "$STATIC_A" > /dev/null 2> "$BUILD_DIR/static-link-missing-frameworks.err"
fi

# 工具链摘要留档，供 check_docs.py 核对文档里引用的命令输出
{
    echo "CFLAGS       : $CFLAGS"
    echo "LIBS(shared) : $LIBS_SHARED"
    echo "LIBS(static) : $LIBS_STATIC"
} > "$BUILD_DIR/toolchain.txt"

PASS=0
FAIL=0
FAILED_ITEMS=()

# ------------------------------------------------------------
# 区间抽取：只取「开始/结束」标记之间的行
# ------------------------------------------------------------
extract_section() {
    awk '/^==== [0-9]+ 开始 ====$/ { f = 1; next }
         /^==== [0-9]+ 结束 ====$/ { f = 0 }
         f { print }' "$1"
}

run_one() {
    local src="$1" chan="$2"
    local base out rc
    base=$(basename "$src" .cpp)
    mkdir -p "$BUILD_DIR/$chan"
    out="$BUILD_DIR/$chan/$base"

    # --- 1) 编译 ---
    local libs="$LIBS_SHARED"
    [ "$chan" = static ] && libs="$LIBS_STATIC"
    # shellcheck disable=SC2086
    "$CXX" $STD $WARN -O1 $CFLAGS "$src" -o "$out" $libs 2> "$BUILD_DIR/$chan/$base.compile.err"
    rc=$?
    if [ "$rc" -ne 0 ] || [ -s "$BUILD_DIR/$chan/$base.compile.err" ]; then
        echo "  [失败] ${base} [${chan}] 编译未通过（exit=${rc}）"
        sed 's/^/         /' "$BUILD_DIR/$chan/$base.compile.err" | head -20
        return 1
    fi

    # --- 2) 运行两遍，比较区间 ---
    local run1="$BUILD_DIR/$chan/$base.run1"
    local run2="$BUILD_DIR/$chan/$base.run2"
    local sec1="$BUILD_DIR/$chan/$base.sec1"
    local sec2="$BUILD_DIR/$chan/$base.sec2"

    if [ -n "$TIMEOUT" ]; then
        "$TIMEOUT" "$RUN_LIMIT" "$out" > "$run1" 2> "$BUILD_DIR/$chan/$base.run.err"
    else
        "$out" > "$run1" 2> "$BUILD_DIR/$chan/$base.run.err"
    fi
    rc=$?
    if [ "$rc" -ne 0 ]; then
        echo "  [失败] $base [$chan] 运行退出码 $rc"
        sed 's/^/         stderr: /' "$BUILD_DIR/$chan/$base.run.err" | head -10
        return 1
    fi
    if [ -s "$BUILD_DIR/$chan/$base.run.err" ]; then
        echo "  [失败] $base [$chan] 运行期 stderr 非空"
        sed 's/^/         /' "$BUILD_DIR/$chan/$base.run.err" | head -10
        return 1
    fi

    if [ -n "$TIMEOUT" ]; then
        "$TIMEOUT" "$RUN_LIMIT" "$out" > "$run2" 2> /dev/null
    else
        "$out" > "$run2" 2> /dev/null
    fi

    # --- 4) 标记齐备 ---
    if ! grep -q '^==== [0-9][0-9]* 开始 ====$' "$run1" || ! grep -q '^==== [0-9][0-9]* 结束 ====$' "$run1"; then
        echo "  [失败] $base [$chan] 缺少分节标记"
        return 1
    fi

    extract_section "$run1" > "$sec1"
    extract_section "$run2" > "$sec2"

    # --- 5) 区间非空、无控制字符 ---
    if [ ! -s "$sec1" ]; then
        echo "  [失败] $base [$chan] 区间为空"
        return 1
    fi
    # BSD grep 不认 GNU 扩展，一律用 POSIX 字符类
    if LC_ALL=C grep -q '[[:cntrl:]]' "$sec1"; then
        echo "  [失败] $base [$chan] 区间含控制字符"
        return 1
    fi

    # --- 6) 连跑两遍一致 ---
    if ! cmp -s "$sec1" "$sec2"; then
        echo "  [失败] $base [$chan] 两次运行区间不一致"
        diff "$sec1" "$sec2" | sed 's/^/         /' | head -10
        return 1
    fi

    if [ "$VERBOSE" -eq 1 ]; then
        echo "  ---- $base [$chan] 区间 ----"
        sed 's/^/  | /' "$sec1"
    fi
    return 0
}

sources=()
if [ "${#SELECT[@]}" -gt 0 ]; then
    for sel in "${SELECT[@]}"; do
        case "$sel" in
            *.cpp) sources+=("$EXAMPLES_DIR/$sel") ;;
            *)     sources+=("$EXAMPLES_DIR/${sel}_"*.cpp) ;;
        esac
    done
else
    for f in "$EXAMPLES_DIR"/*.cpp; do sources+=("$f"); done
fi

for src in "${sources[@]}"; do
    [ -e "$src" ] || { echo "[跳过] 找不到 $src"; continue; }
    base=$(basename "$src" .cpp)
    echo "[编译+运行] $base"
    ok=1
    for chan in "${CHANNELS[@]}"; do
        if ! run_one "$src" "$chan"; then ok=0; fi
    done

    # --- 7) 双通道区间逐字节一致 ---
    if [ "$ok" -eq 1 ] && [ "${#CHANNELS[@]}" -eq 2 ]; then
        s1="$BUILD_DIR/shared/$base.sec1"
        s2="$BUILD_DIR/static/$base.sec1"
        if [ -f "$s1" ] && [ -f "$s2" ] && ! cmp -s "$s1" "$s2"; then
            echo "  [失败] $base 两条通道区间不一致"
            diff "$s1" "$s2" | sed 's/^/         /' | head -10
            ok=0
        fi
    fi

    if [ "$ok" -eq 1 ]; then
        PASS=$((PASS + 1))
        echo "  [通过] $base"
    else
        FAIL=$((FAIL + 1))
        FAILED_ITEMS+=("$base")
    fi
done

# ------------------------------------------------------------
# 留档：dummy 驱动下 02 的输出（证明渲染器降级真的生效）
# 与 summary 摘要一起写进 build/，供 tools/check_docs.py 核对文档引用。
# ------------------------------------------------------------
if [ -x "$BUILD_DIR/shared/02_window_renderer" ]; then
    SDL_VIDEODRIVER=dummy "$BUILD_DIR/shared/02_window_renderer" \
        > "$BUILD_DIR/dummy-driver-02.out" 2>&1
fi

echo
echo "======================================"
echo " 通过 $PASS  失败 $FAIL  （示例总数 $((PASS + FAIL))，通道 ${#CHANNELS[@]} 条）"
if [ "$FAIL" -gt 0 ]; then
    printf ' 失败项: %s\n' "${FAILED_ITEMS[*]}"
fi
echo "======================================"

{
    echo " 通过 $PASS  失败 $FAIL  （示例总数 $((PASS + FAIL))，通道 ${#CHANNELS[@]} 条）"
} > "$BUILD_DIR/summary.txt"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
