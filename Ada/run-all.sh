#!/usr/bin/env bash
# ============================================================
# run-all.sh —— Linux/macOS 版全量编译运行脚本（等价于 build.ps1）
#
#   ./run-all.sh            编译并运行全部 25 个示例，打印通过/失败摘要
#   ./run-all.sh -v         附带每个示例的完整输出
#   ./run-all.sh 01 13      只跑指定章节编号（如 01 13 16）
#   ./run-all.sh --clean    清理 build 目录
#
# 与 build.ps1 的对应关系：
#   build.ps1 -All     ->  ./run-all.sh
#   build.ps1 -File X  ->  ./run-all.sh <章节编号>
#   build.ps1 -Clean   ->  ./run-all.sh --clean
#
# 平台差异（相对 Windows build.ps1）：
#   * ch20_c_interop 导入 C 的 sqrtf，Linux 下数学函数在独立的
#     libm 中，链接时必须附加 -largs -lm（Windows UCRT 无需）
#   * ch24_contracts / ch25_spark 需 -gnata 启用契约断言检查
#   * gnatmake 从 PATH 定位，也可用环境变量 GNATMAKE 指定
# ============================================================
set -u
cd "$(dirname "$0")"

VERBOSE=0
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        --clean|-c)   CLEAN=1 ;;
        *)            SELECT+=("$arg") ;;
    esac
done
CLEAN=${CLEAN:-0}

BUILD_DIR=build
OBJ_DIR=$BUILD_DIR/obj

if [ "$CLEAN" -eq 1 ]; then
    rm -rf "$BUILD_DIR"
    echo "[Clean] 已清理 build 目录。"
    exit 0
fi

# ------------------------------------------------------------
# 工具链定位：环境变量 GNATMAKE 优先，其次 PATH
# ------------------------------------------------------------
if [ -n "${GNATMAKE:-}" ]; then
    GNAT="$GNATMAKE"
elif command -v gnatmake >/dev/null 2>&1; then
    GNAT=$(command -v gnatmake)
else
    echo "未找到 gnatmake。请先安装 GNAT（如 sudo apt install gnat），" >&2
    echo "或用 GNATMAKE=/path/to/gnatmake 指定。" >&2
    exit 1
fi

echo "gnatmake : $GNAT"
"$GNAT" --version | head -1
echo

# 章节编号:单元名:额外编译选项
UNITS=(
    "02:ch02_hello:"
    "03:ch03_types:"
    "04:ch04_control:"
    "05:ch05_subprograms:"
    "06:ch06_arrays:"
    "07:ch07_records:"
    "08:ch08_discriminants:"
    "09:ch09_access:"
    "10:ch10_packages:"
    "11:ch11_exceptions:"
    "12:ch12_generics:"
    "13:ch13_generics_deep:"
    "14:ch14_oop:"
    "15:ch15_tasking:"
    "16:ch16_protected:"
    "17:ch17_select:"
    "18:ch18_fileio:"
    "19:ch19_files:"
    "20:ch20_c_interop:-largs -lm"
    "21:ch21_lowlevel:"
    "22:ch22_fixed:"
    "23:ch23_containers:"
    "24:ch24_contracts:-gnata"
    "25:ch25_spark:-gnata"
    "26:ch26_separate:"
)

TIMEOUT=""
command -v timeout >/dev/null 2>&1 && TIMEOUT="timeout 60"

mkdir -p "$OBJ_DIR"
PASS=0
FAIL=0
FAILED_LIST=()

for spec in "${UNITS[@]}"; do
    num=${spec%%:*}
    rest=${spec#*:}
    name=${rest%%:*}
    extra=${rest#*:}

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
        [ "$hit" -eq 1 ] || continue
    fi

    echo "==== $num $name ===="

    # 与 build.ps1 一致：在 build/ 目录内调用 gnatmake，
    # 对象文件集中放 obj/，可执行文件输出到 build/ 根下。
    # 注意 $extra 必须置于最后：-largs 之后的参数全部传给链接器
    if ! ( cd "$BUILD_DIR" && "$GNAT" -q -D obj -aI../examples \
           -aOobj -o "$name" "../examples/$name.adb" $extra \
           >"$name.build" 2>&1 ); then
        echo "  [FAIL] $name —— 编译失败（见 build/$name.build）"
        head -8 "$BUILD_DIR/$name.build" | sed 's/^/        /'
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$num $name")
        continue
    fi

    # 统一在 build/ 下运行：ch18_fileio 会在当前目录创建数据文件
    if ! ( cd "$BUILD_DIR" && $TIMEOUT "./$name" >"$name.out" 2>"$name.err" ); then
        rc=$?
        echo "  [FAIL] $name —— 运行失败（退出码 $rc，见 build/$name.out/.err）"
        tail -5 "$BUILD_DIR/$name.out" | sed 's/^/        /'
        [ -s "$BUILD_DIR/$name.err" ] && tail -3 "$BUILD_DIR/$name.err" | sed 's/^/        stderr: /'
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$num $name")
        continue
    fi
    if [ -s "$BUILD_DIR/$name.err" ]; then
        echo "  [FAIL] $name —— stderr 非空"
        tail -3 "$BUILD_DIR/$name.err" | sed 's/^/        stderr: /'
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$num $name")
        continue
    fi

    PASS=$((PASS + 1))
    echo "  [OK] $name"
    if [ "$VERBOSE" -eq 1 ]; then
        sed 's/^/        /' "$BUILD_DIR/$name.out"
    fi
done

echo
echo "通过 $PASS   失败 $FAIL"
if [ "$FAIL" -eq 0 ]; then
    echo "全部通过"
    exit 0
else
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
    exit 1
fi
