#!/usr/bin/env bash
# ============================================================
# run-all.sh —— Go 教程的 shell 入口（等价于 build.ps1，给 macOS/Linux 用）
#
#   ./run-all.sh              只打印每条通道的通过/失败摘要
#   ./run-all.sh -v           附带每个示例的完整输出
#   ./run-all.sh 12 23        只跑指定编号（12_collections、23_tooling）
#   ./run-all.sh --no-cross   跳过末尾的交叉编译检查
#
# 每个示例四层验证（与 build.ps1 一致）：
#   gofmt -l（输出必须为空） → go vet → go test（16/17/18 加 -race）
#   → go build 到 build/ → 运行
#
# 判定标准：
#   退出码 0 + stderr 为空 + stdout 非空 + 输出无控制字符 + gofmt 无待格式化文件
#
#   这里没有别的教程目录用的「==== NN 结束 ====」那一条：本目录的示例是
#   examples/NN_topic/main.go 的目录形式，23 个示例都没写结束标记。
#   用「stdout 非空」兜住「进程没跑到业务代码、退出码却是 0」这一类假阳性
#   （这是别的项目踩过的坑：命令被当成文档"打开"，退出码仍然是 0）。
#   哪天给示例补了结束标记，把 check() 里的 marker 判断打开即可。
#
# 已知会写 stderr 的示例见 stderr_reason()：Go 的 log 包默认写 stderr，
# 22_http 的中间件日志正是用它演示的，不是失败。
# ============================================================

set -u
cd "$(dirname "$0")"
PROJECT_ROOT=$(pwd)   # 子 shell 里 cd 来 cd 去，路径一律用绝对量

VERBOSE=0
CROSS=1
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        --no-cross)   CROSS=0 ;;
        *)            SELECT+=("$arg") ;;
    esac
done

# ------------------------------------------------------------
# 工具链定位：环境变量 GO 优先（指向 go 可执行文件），其次平台常见安装路径，
#             最后退回 PATH。gofmt 从 GOROOT 里取，保证与 go 同版本——
#             另找一个 gofmt 可能来自别的 Go 版本，判过的代码不算数。
# ------------------------------------------------------------
GO=""
for c in "${GO:-}" /opt/local/bin/go /opt/local/bin/go-1.27 /usr/local/go/bin/go; do
    [ -n "$c" ] && [ -x "$c" ] && GO="$c" && break
done
if [ -z "$GO" ]; then
    GO=$(command -v go 2>/dev/null || true)
fi
if [ -z "$GO" ]; then
    echo "未找到 go。请安装 Go 1.27+，或用 GO=/path/to/go ./run-all.sh 指定。"
    exit 1
fi

GOROOT=$("$GO" env GOROOT)
GOFMT="$GOROOT/bin/gofmt"
[ -x "$GOFMT" ] || GOFMT=$(command -v gofmt 2>/dev/null || true)
[ -n "$GOFMT" ] || { echo "未找到 gofmt（GOROOT=$GOROOT）"; exit 1; }

# -race 依赖 cgo，cgo 又依赖 C 编译器（macOS 用 clang，Windows 用 gcc）。
# 不可用就退化成不带 -race 跑，最后提示——总比直接失败好。
CGO_ENABLED=$("$GO" env CGO_ENABLED)
RACE_OK=0
[ "$CGO_ENABLED" = "1" ] && RACE_OK=1

echo "go      : $GO ($("$GO" version))"
echo "gofmt   : $GOFMT"
echo "平台    : $("$GO" env GOOS)/$("$GO" env GOARCH) / cgo=$CGO_ENABLED / race=$RACE_OK"
echo

mkdir -p build
PASS=0
FAIL=0
FAILED_LIST=()

# 输出里是否混进了控制字符（TAB/LF/CR 除外）。用退出码判定，不要比较
# 抓出来的字符串：往管道里插话的东西会污染字符串，用退出码才免疫。
has_ctrl() {
    LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

# 已知会写 stderr 的示例及原因。这些不是失败——打印原因即可，不计入告警。
stderr_reason() {
    case "$1" in
        22_http) echo "中间件用 log.Printf，log 包默认写 stderr（示例故意演示）" ;;
        *)       echo "" ;;
    esac
}

# 用法：check <标签> <stdout文件> <stderr文件> <退出码> <额外失败原因>
check() {
    local tag="$1" out="$2" err="$3" rc="$4" extra="${5:-}"
    local ok=1 why=()

    [ "$rc" -eq 0 ]     || { ok=0; why+=("退出码 $rc"); }
    [ -n "$extra" ]     && { ok=0; why+=("$extra"); }
    [ -s "$out" ]       || { ok=0; why+=("stdout 为空"); }
    has_ctrl "$out"     && { ok=0; why+=("输出含控制字符"); }
    if [ -s "$err" ]; then
        local reason; reason=$(stderr_reason "${tag%% *}")
        if [ -n "$reason" ]; then
            printf '  [stderr] %s —— 已知：%s\n' "$tag" "$reason"
        else
            ok=0; why+=("stderr 非空")
        fi
    fi

    if [ "$ok" -eq 1 ]; then
        PASS=$((PASS + 1))
        printf '  [%s] %s\n' "OK" "$tag"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$tag")
        printf '  [%s] %s —— %s\n' "FAIL" "$tag" "$(printf '%s；' "${why[@]}")"
        [ -s "$err" ] && sed 's/^/        stderr: /' "$err" | head -5
    fi

    if [ "$VERBOSE" -eq 1 ]; then
        sed 's/^/        /' "$out"
    fi
    return 0
}

# 跑一个示例目录。$1=目录名 $2=build 目标 $3..=运行参数
run_example() {
    local name="$1" target="$2"; shift 2
    local dir="examples/$name"
    local out="build/$name.out" err="build/$name.err"
    : >"$out"; : >"$err"
    local rc=0 extra=""

    # 1) gofmt：退出码恒为 0，必须看输出是否为空
    if [ -n "$(cd "$dir" && "$GOFMT" -l .)" ]; then
        extra="gofmt 未通过：$(cd "$dir" && "$GOFMT" -l . | tr '\n' ' ')"
    fi

    # 2) vet：工程用 ./...，单包用 .
    local pkgspec="."
    [ -f "$dir/go.mod" ] && pkgspec="./..."
    ( cd "$dir" && "$GO" vet $pkgspec ) >"build/$name.vet" 2>&1 \
        || { extra="$extra${extra:+；}go vet 失败"; cat "build/$name.vet" >&2; }

    # 3) test：并发三章加 -race
    local race_flag=""
    case "$name" in
        16_goroutines|17_channels|18_sync) [ "$RACE_OK" -eq 1 ] && race_flag="-race" ;;
    esac
    ( cd "$dir" && "$GO" test $race_flag $pkgspec ) >"build/$name.test" 2>&1 \
        || { extra="$extra${extra:+；}go test 失败"; sed 's/^/        /' "build/$name.test"; }

    # 4) build
    ( cd "$dir" && "$GO" build -o "$PROJECT_ROOT/build/$name" $target ) >"build/$name.build" 2>&1 \
        || { extra="$extra${extra:+；}go build 失败"; sed 's/^/        /' "build/$name.build"; }

    # 5) 运行（cwd 保持在示例目录：示例里有相对路径读写）
    if [ ! -x "$PROJECT_ROOT/build/$name" ]; then
        rc=1
    else
        ( cd "$dir" && "$PROJECT_ROOT/build/$name" "$@" ) >"$out" 2>"$err"
        rc=$?
    fi

    check "$name" "$out" "$err" "$rc" "$extra"
}

for d in examples/[0-9]*/; do
    [ -d "$d" ] || continue
    name=$(basename "$d")
    num=${name%%_*}

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do [ "$s" = "$num" ] && hit=1; done
        [ "$hit" -eq 1 ] || continue
    fi

    echo "==== $name ===="
    case "$name" in
        14_module)   run_example "$name" "./cmd/app" ;;
        24_minigrep) run_example "$name" "." "func" "main.go" ;;
        *)           run_example "$name" "." ;;
    esac
done

# ------------------------------------------------------------
# 附加：交叉编译检查。纯 Go 代码不该依赖任何平台相关的东西——
# 这能抓出「只在某一平台编译得过」的问题（比如误用 syscall 常量、
# 构建标签写错）。有 go.mod 的子工程要单独进目录编。
# ------------------------------------------------------------
CROSS_FAIL=0
if [ "$CROSS" -eq 1 ]; then
    echo
    echo "==== 交叉编译检查 ===="
    for pair in windows/amd64 linux/amd64 darwin/arm64; do
        g=${pair%/*}; a=${pair#*/}
        ok=1
        # 不带 -o：多包时 go build 只编译不落地文件（-o 非目录会直接报错）
        ( GOOS=$g GOARCH=$a "$GO" build ./... ) >"build/cross-$g-$a.log" 2>&1 || ok=0
        for d in examples/14_module examples/24_minigrep; do
            ( cd "$d" && GOOS=$g GOARCH=$a "$GO" build ./... ) >>"build/cross-$g-$a.log" 2>&1 || ok=0
        done
        if [ "$ok" -eq 1 ]; then
            printf '  [%s] GOOS=%s GOARCH=%s\n' "OK" "$g" "$a"
        else
            CROSS_FAIL=$((CROSS_FAIL + 1))
            printf '  [%s] GOOS=%s GOARCH=%s\n' "FAIL" "$g" "$a"
            sed 's/^/        /' "build/cross-$g-$a.log" | head -8
        fi
    done
fi

echo
echo "通过 $PASS   失败 $FAIL   交叉编译失败 $CROSS_FAIL"
if [ "$FAIL" -eq 0 ] && [ "$CROSS_FAIL" -eq 0 ]; then
    [ "$RACE_OK" -eq 0 ] && echo "（cgo 不可用，16/17/18 未启用 -race）"
    echo "全部通过"
    exit 0
fi
[ "$FAIL" -gt 0 ] && { echo "失败项："; for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done; }
exit 1
