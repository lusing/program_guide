#!/usr/bin/env bash
# ============================================================
# fsharp/run-all.sh — macOS / Linux 入口（与 build.ps1 等价）
#
# 行为分级（与 PowerShell 入口一致）：
#   控制台工程  构建 + 运行
#   测试工程    dotnet test
#   GUI 工程    只构建（netX.0-windows，非 Windows 上需 EnableWindowsTargeting）
#
# 判定：
#   1. 退出码为 0
#   2. stderr 为空（dotnet 的警告走 stderr，静默放过会掩盖问题）
#   运行输出存到 build/log/<工程名>.out
#
# 用法：
#   ./run-all.sh                      全部示例
#   ./run-all.sh 06_collections       单个示例目录（嵌套目录构建其下全部 fsproj）
#   ./run-all.sh --clean              清理 build 目录
#   DOTNET=/path/to/dotnet ./run-all.sh
# ============================================================
set -u

cd "$(dirname "$0")"
ROOT=$PWD
EXAMPLES=$ROOT/examples
BUILD=$ROOT/build
LOG=$BUILD/log

# ---------- 工具链解析：环境变量 → 常见安装位置 → PATH ----------
resolve_dotnet() {
    if [ -n "${DOTNET:-}" ]; then
        [ -x "$DOTNET" ] || { echo "DOTNET 指定的不可执行: $DOTNET" >&2; exit 1; }
        printf '%s' "$DOTNET"; return
    fi
    local c
    for c in /opt/local/bin/dotnet /opt/homebrew/bin/dotnet \
             /usr/local/bin/dotnet /usr/share/dotnet/dotnet /usr/lib/dotnet/dotnet; do
        [ -x "$c" ] && { printf '%s' "$c"; return; }
    done
    command -v dotnet 2>/dev/null || printf ''
}

DOTNET_BIN=$(resolve_dotnet)
if [ -z "$DOTNET_BIN" ]; then
    echo "找不到 dotnet。请安装 .NET 10 SDK，或用 DOTNET=/path/to/dotnet ./run-all.sh 指定。" >&2
    exit 1
fi

FAILURES=()

# ---------- 清扫 examples 下游离的 obj/bin ----------
# 读者直接 dotnet run 会在示例目录生成默认产物，与本脚本的集中重定向路径冲突
if [ -d "$EXAMPLES" ]; then
    find "$EXAMPLES" -type d \( -name obj -o -name bin \) -prune -exec rm -rf {} + 2>/dev/null
fi

# ---------- clean ----------
if [ "${1:-}" = "--clean" ] || [ "${1:-}" = "-Clean" ]; then
    if [ -d "$BUILD" ]; then
        rm -rf "$BUILD"
        echo "[Clean] 已清理 build 目录。"
    else
        echo "[Clean] build 目录不存在，无需清理。"
    fi
    exit 0
fi

# ---------- 收集工程列表 ----------
# 不用 mapfile：macOS 自带的 /bin/bash 是 3.2，没有这个内建
collect_projects() {
    local src=$1
    PROJECTS=()
    while IFS= read -r line; do
        [ -n "$line" ] && PROJECTS+=("$line")
    done < <(find "$src" -name "*.fsproj" | sort)
}

if [ "$#" -gt 0 ]; then
    TARGET=$EXAMPLES/$1
    [ -d "$TARGET" ] || { echo "找不到示例工程: $TARGET" >&2; exit 1; }
    collect_projects "$TARGET"
else
    collect_projects "$EXAMPLES"
fi

if [ "${#PROJECTS[@]}" -eq 0 ] || [ -z "${PROJECTS[0]}" ]; then
    echo "examples 目录下没有 fsproj 工程。" >&2
    exit 1
fi

mkdir -p "$BUILD" "$LOG"
# 清掉上一轮的日志：下面 Todo 是多步追加写，不清会一轮轮堆上去
rm -f "$LOG"/*.out "$LOG"/*.err 2>/dev/null

# 关掉首次运行体验与遥测：
#   - 遥测会往 ~/.dotnet/TelemetryStorageService 写临时文件，在 CI 容器、只读 HOME、
#     受限沙箱里这步失败会让子进程直接被杀（退出码 131），看起来像"示例崩了"；
#   - 首次体验横幅会污染 stdout，干扰日志比对。
export DOTNET_CLI_TELEMETRY_OPTOUT=1
export DOTNET_NOLOGO=1
export DOTNET_SKIP_FIRST_TIME_EXPERIENCE=1

echo "[Info] dotnet = $DOTNET_BIN"
echo "[Info] SDK    = $("$DOTNET_BIN" --version 2>/dev/null)"
echo "[Info] 平台   = $(uname -s)"

# MSBuild 属性一律用正斜杠：Unix 上反斜杠不是分隔符，会拼出带 \ 的怪目录名
OUT_PATH="${BUILD}/bin/"
OBJ_PATH="${BUILD}/obj/"

run_project() {
    local fsproj=$1
    local name
    name=$(basename "$fsproj" .fsproj)
    local raw
    raw=$(cat "$fsproj")

    # ---------- 测试工程 ----------
    if printf '%s' "$raw" | grep -q 'Microsoft\.NET\.Test\.Sdk'; then
        echo "[Test] ${name}"
        if ! "$DOTNET_BIN" test "$fsproj" --nologo -v minimal -c Release; then
            FAILURES+=("测试未通过: ${name}")
            echo "[FAIL] ${name}"
        fi
        return
    fi

    # ---------- 构建 ----------
    echo "[Build] ${name}"
    local is_gui=0
    printf '%s' "$raw" | grep -qE 'net[0-9]+\.[0-9]+-windows' && is_gui=1

    local -a build_args=(build "$fsproj" --nologo -v minimal -c Release
                         "-p:BaseOutputPath=$OUT_PATH"
                         "-p:BaseIntermediateOutputPath=${OBJ_PATH}${name}/")
    # 非 Windows 上构建 netX.0-windows 工程必须显式开启 Windows targeting，
    # 否则报 NETSDK1100（Windows 上这个开关无副作用，所以不区分平台直接加）
    if [ "$is_gui" -eq 1 ]; then
        build_args+=("-p:EnableWindowsTargeting=true")
    fi

    if ! "$DOTNET_BIN" "${build_args[@]}"; then
        FAILURES+=("编译失败: ${name}")
        echo "[FAIL] ${name}"
        return
    fi

    if [ "$is_gui" -eq 1 ]; then
        echo "[BuildOnly] ${name}（GUI 工程，跳过运行）"
        return
    fi

    # ---------- 定位产物 ----------
    # 刻意用 `dotnet X.dll`，不用 apphost（那个同名无扩展名的原生启动器）：
    # apphost 只在固定位置找运行时（/usr/local/share/dotnet、DOTNET_ROOT、注册位置），
    # 而 MacPorts 装在 /opt/local、Homebrew 装在 /opt/homebrew 时它一概找不到，直接报
    #   You must install .NET to run this application.
    # 并以退出码 131 收场——看着像示例崩了，其实是"运行时装在不常规的位置"。
    # dotnet X.dll 复用的是脚本已解析出的那个 dotnet，不受安装位置影响。
    # （Windows 上拿到 X.exe 就直接跑，那里不存在这个问题。）
    local release_dir="$BUILD/bin/Release"
    local tfm_dir
    tfm_dir=$(find "$release_dir" -maxdepth 1 -type d ! -path "$release_dir" | sort | head -1)
    if [ -z "$tfm_dir" ]; then
        FAILURES+=("未找到输出目录: ${name}")
        echo "[FAIL] ${name}（没找到 $release_dir 下的目标框架目录）"
        return
    fi

    local runner=""
    local use_dotnet=0
    if [ -f "$tfm_dir/${name}.exe" ]; then
        runner="$tfm_dir/${name}.exe"
    elif [ -f "$tfm_dir/${name}.dll" ]; then
        runner="$tfm_dir/${name}.dll"
        use_dotnet=1
    else
        FAILURES+=("未找到生成的可执行文件: ${name}")
        echo "[FAIL] ${name}（产物缺失）"
        return
    fi

    local out_log="$LOG/${name}.out"
    local err_log="$LOG/${name}.err"

    # 每轮先截断，避免和上一轮的输出混在一起
    : > "$out_log"
    : > "$err_log"

    # ---------- Todo 有多步演示序列 ----------
    if [ "${name}" = "Todo" ]; then
        local -a seq_args=("reset" "add|learn F#" "add|write tutorial" "show" "done|2" "show" "remove|1" "show")
        local step bad=0
        for step in "${seq_args[@]}"; do
            IFS='|' read -r -a parts <<< "$step"
            echo "[Run] Todo ${parts[*]}"
            # 每步单独落临时文件再 append：否则"本步无输出"会被前面步骤的累积内容盖住
            local tmp_out
            tmp_out=$(mktemp)
            if [ "$use_dotnet" -eq 1 ]; then
                "$DOTNET_BIN" "$runner" "${parts[@]}" >"$tmp_out" 2>"$err_log"
            else
                "$runner" "${parts[@]}" >"$tmp_out" 2>"$err_log"
            fi
            local rc=$?
            cat "$tmp_out" >>"$out_log"
            if [ "$rc" -ne 0 ]; then
                FAILURES+=("运行失败: Todo ${parts[*]}")
                bad=1
            fi
            # 兜底断言：本示例每一步都有输出。空输出说明进程根本没执行到业务代码
            if [ ! -s "$tmp_out" ]; then
                FAILURES+=("无输出: Todo ${parts[*]}（进程可能没真正启动）")
                bad=1
            fi
            rm -f "$tmp_out"
            if [ -s "$err_log" ]; then
                FAILURES+=("stderr 非空: Todo ${parts[*]}")
                bad=1
            fi
        done
        [ "$bad" -eq 1 ] && echo "[FAIL] Todo"
        return
    fi

    # ---------- 运行 ----------
    echo "[Run] ${name}"
    if [ "$use_dotnet" -eq 1 ]; then
        "$DOTNET_BIN" "$runner" >"$out_log" 2>"$err_log"
    else
        "$runner" >"$out_log" 2>"$err_log"
    fi
    local code=$?
    if [ "${code}" -ne 0 ]; then
        FAILURES+=("运行失败: ${name}（退出码 ${code}）")
        echo "[FAIL] ${name}"
        return
    fi
    if [ -s "$err_log" ]; then
        FAILURES+=("stderr 非空: ${name}")
        echo "[FAIL] ${name}（stderr 有输出）"
        return
    fi
    # 兜底断言：每个示例都打印内容。空输出说明进程根本没执行到业务代码
    # （dll 被当成文档"打开"时退出码仍是 0，只有这条能抓到）
    if [ ! -s "$out_log" ]; then
        FAILURES+=("无输出: ${name}（进程可能没真正启动）")
        echo "[FAIL] ${name}（stdout 为空）"
    fi
}

for p in "${PROJECTS[@]}"; do
    run_project "$p"
done

echo ""
if [ "${#FAILURES[@]}" -gt 0 ]; then
    echo "[FAILED] 共 ${#FAILURES[@]} 项："
    printf '  - %s\n' "${FAILURES[@]}"
    exit 1
fi
echo "[Done] 全部验证通过。运行输出见 build/log/*.out"
exit 0
