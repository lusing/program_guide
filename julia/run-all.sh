#!/usr/bin/env bash
# ============================================================
# run-all.sh —— 用 Julia 跑遍所有示例（shell 版，等价于 build.ps1）
#
#   ./run-all.sh            只打印每条通道的通过/失败摘要
#   ./run-all.sh -v         附带每个示例的完整输出
#   ./run-all.sh 13 23      只跑指定编号（两位数字或目录名均可）
#
# 三层验证（与 build.ps1 完全一致）：
#   * 运行层：julia --check-bounds=yes main.jl  —— exit 0 + 结束标记
#   * 测试层：julia runtests.jl（@testset）—— exit 0
#   * 特判层：17/24 走 Pkg 工程流程（env/ 已锁版本，直接跑；只有 Manifest 缺失时才
#     Pkg.instantiate），20 加 -t 4
#
# 判定标准（六条，两个入口共用）：
#   1. 退出码为 0
#   2. stderr 为空（Julia 的警告/错误都走 stderr，所以这一条等价于「零告警」）
#      示例若**故意**触发诊断（如 14_macros 的世界年龄警告），由示例自己用
#      redirect_stderr(devnull) 把那段圈起来 —— 判定标准不为任何示例放宽。
#   3. stdout 非空（只判退出码会漏掉「进程根本没执行到业务代码」的假阳性）
#   4. stdout 里没有多余控制字符（TAB/LF/CR 除外）
#   5. stdout 里有结束标记 "==== NN 结束 ===="
#   6. stdout 里没有 Julia 的诊断字样（WARNING/ERROR/MethodError…）
#      注：Julia 的 @warn 与异常默认走 stderr，第 2 条已覆盖；
#      这里再兜一层是防某些第三方输出绕过 stderr。示例自己的文案里
#      出现这些字样会被自己判失败 —— 那正是这条想抓的「把诊断当正文写」。
#
#   判定函数处理「待验证输出」时一律带 LC_ALL=C：本机的 tr/grep 是 toybox，
#   UTF-8 locale 下碰到非法字节会报 Illegal byte sequence 并截断输入，
#   结束标记若在截断点之后就会误报「缺少结束标记」。
# ============================================================

set -u
cd "$(dirname "$0")"

VERBOSE=0
SELECT=()
for arg in "$@"; do
    case "$arg" in
        -v|--verbose) VERBOSE=1 ;;
        *) SELECT+=("$arg") ;;
    esac
done

# ------------------------------------------------------------
# 工具链定位：环境变量 JULIA 优先，其次常见安装位置，最后退回 PATH。
# 别硬编码某一台机器的路径 —— 教程目录要能在 Windows/macOS/Linux 上都跑。
# ------------------------------------------------------------
resolve_tool() {
    local envval="$1"; shift
    local c
    if [ -n "${envval}" ]; then
        printf '%s' "$envval"
        return
    fi
    for c in "$@"; do
        if command -v "$c" >/dev/null 2>&1; then
            command -v "$c"
            return
        fi
    done
    printf ''
}

JULIA=$(resolve_tool "${JULIA:-}" \
    julia \
    /opt/local/bin/julia \
    /opt/homebrew/bin/julia \
    /usr/local/bin/julia \
    "$HOME/.juliaup/bin/julia")

if [ -z "$JULIA" ]; then
    echo "未找到 julia（可设 JULIA=/path/to/julia，或确认它在 PATH 上）"
    exit 1
fi
echo "julia    : $JULIA"
"$JULIA" --version

# Pkg 一律离线：本教程的依赖只有本地路径包（[sources]）和标准库，不需要联网。
# 不设这一条时，Pkg 首次运行会先去下载/解压 General registry（几百 MB），
# 在没有 registry 的机器上表现为「instantiate 卡住十几分钟」——看上去像死锁。
export JULIA_PKG_OFFLINE=true
echo "JULIA_PKG_OFFLINE = $JULIA_PKG_OFFLINE"
echo

BUILD_DIR="build"
# 不清目录：删文件会被沙箱拦（而且 build/ 里本来只有上一轮的 stdout/stderr）。
# 每次运行直接覆盖同名文件即可。
mkdir -p "$BUILD_DIR"

PASS=0
FAIL=0
FAILED_LIST=()

# ------------------------------------------------------------
# 判定函数：只依赖退出码 / 存在性，不依赖被捕获的文本内容。
# 把子进程 stdout 抓进 $(...) 再比较字符串，会被任何往管道里插话的东西污染。
# ------------------------------------------------------------
has_ctrl() {   # 0..31 里除 TAB(11)/LF(12)/CR(15)（八进制）
    LC_ALL=C tr -d '\11\12\15' < "$1" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'
}

marker_present() {
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null | LC_ALL=C grep -qF "$2"
}

has_diag() {   # Julia 诊断字样
    LC_ALL=C tr -d '\000' < "$1" 2>/dev/null \
        | LC_ALL=C grep -qE 'WARNING:|ERROR:|MethodError|UndefVarError|Stacktrace'
}

# check <标签> <期望结束标记> <stdout 文件> <stderr 文件> <退出码>
check() {
    local tag="$1" marker="$2" out="$3" err="$4" rc="$5"
    local ok=1 why=()

    if [ "$rc" -ne 0 ];          then ok=0; why+=("退出码 $rc"); fi
    if [ -s "$err" ];            then ok=0; why+=("stderr 非空"); fi
    if [ ! -s "$out" ];          then ok=0; why+=("stdout 为空"); fi
    if has_ctrl "$out";          then ok=0; why+=("输出含控制字符"); fi
    if has_diag "$out";          then ok=0; why+=("输出含 Julia 诊断字样"); fi
    if ! marker_present "$out" "$marker"; then ok=0; why+=("缺少结束标记"); fi

    if [ "$ok" -eq 1 ]; then
        PASS=$((PASS + 1))
        printf "  [%s] %s\n" "OK" "$tag"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$tag")
        printf "  [%s] %s —— %s\n" "FAIL" "$tag" "$(printf '%s；' "${why[@]}")"
        if [ -s "$err" ]; then
            echo "        stderr 前 8 行："
            head -8 "$err" | LC_ALL=C tr -d '\000' | sed 's/^/        /'
        fi
        echo "        stdout 最后 8 行："
        tail -8 "$out" | LC_ALL=C tr -d '\000' | sed 's/^/        /'
    fi

    if [ "$VERBOSE" -eq 1 ]; then
        LC_ALL=C tr -d '\000' < "$out" | sed 's/^/        /'
    fi
}

# run_julia <stdout 文件> <stderr 文件> [参数...]
run_julia() {
    local out="$1" err="$2"; shift 2
    "$JULIA" "$@" >"$out" 2>"$err"
    return $?
}

for dir in examples/[0-9]*; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    num=${name%%_*}

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do
            [ "$s" = "$num" ] && hit=1
            [ "$s" = "$name" ] && hit=1
        done
        [ "$hit" -eq 1 ] || continue
    fi

    marker="==== $num 结束 ===="
    echo "==== $name ===="

    std_args=(--startup-file=no --history-file=no --check-bounds=yes)
    test_args=(--startup-file=no --history-file=no --check-bounds=yes)
    main_args=()
    project=""

    # ---- 特判层：按示例名调整参数 ----
    case "$name" in
        02_hello)        main_args=(Julia 1.13) ;;   # 演示 ARGS 与 Base.@main
        20_concurrency)  std_args+=(-t 4); test_args+=(-t 4) ;;   # 线程池示例需要多线程
        17_pkgenv|24_miniode) project="$PWD/$dir/env" ;;
    esac

    if [ -n "$project" ]; then
        std_args+=(--project="$project")
        test_args+=(--project="$project")
        # env/Manifest.toml 是本仓库入库的文件（版本已锁死），依赖只有 [sources] 路径包
        # 和 stdlib —— 直接跑即可，**不需要** Pkg.instantiate()。
        # 反过来，在没有 registry 的 depot 上强行 instantiate 会让 Julia 去下载并解压
        # General registry（7.5MB → 240MB、约 4 万个小文件），慢得像死锁（macOS 实测，
        # 十几分钟不返回）。所以：只有 Manifest 真缺了（首次从零解析）才 instantiate。
        if [ ! -f "$project/Manifest.toml" ]; then
            echo "  [info] $name 缺 env/Manifest.toml —— 首次解析环境"
            inst_out="$BUILD_DIR/$name.instantiate.out"
            inst_err="$BUILD_DIR/$name.instantiate.err"
            run_julia "$inst_out" "$inst_err" \
                --startup-file=no --history-file=no --project="$project" \
                -e 'using Pkg; Pkg.instantiate()'
            irc=$?
            # instantiate 只看退出码：Pkg 的「Precompiling…」进度本来就走 stderr，
            # 拿「stderr 为空」去判它必然误报失败。
            if [ $irc -ne 0 ]; then
                FAIL=$((FAIL + 1))
                FAILED_LIST+=("$name instantiate")
                printf "  [%s] %s —— %s\n" "FAIL" "$name instantiate" "Pkg.instantiate 失败（退出码 ${irc}）"
                head -8 "$inst_err" | sed 's/^/        /'
                continue
            fi
        fi
        # 预热：首次运行会触发本地包预编译，Pkg 的「Precompiling…」进度走 stderr，
        # 那不是告警。先把预编译跑掉（输出丢弃），判定层再跑就是干净的一次。
        "$JULIA" "${std_args[@]}" "$PWD/$dir/main.jl" "${main_args[@]}" >/dev/null 2>&1 || true
    fi

    # ---- 运行层 ----
    out="$BUILD_DIR/$name.run.out"
    err="$BUILD_DIR/$name.run.err"
    run_julia "$out" "$err" "${std_args[@]}" "$PWD/$dir/main.jl" "${main_args[@]}"
    check "run      $name" "$marker" "$out" "$err" $?

    # ---- 测试层：@testset 里的断言失败会让进程 exit 1 ----
    tout="$BUILD_DIR/$name.test.out"
    terr="$BUILD_DIR/$name.test.err"
    run_julia "$tout" "$terr" "${test_args[@]}" "$PWD/$dir/runtests.jl"
    trc=$?
    # 测试层不要求结束标记？要求 —— 它 include 了 main.jl，标记应当在
    check "test     $name" "$marker" "$tout" "$terr" "$trc"
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
