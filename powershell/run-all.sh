#!/usr/bin/env bash
# ============================================================
# run-all.sh —— PowerShell 教程的 macOS/Linux 全量验证入口
#
#   ./run-all.sh              跑全部 34 个示例
#   ./run-all.sh 09 14        只跑指定章号（也可写完整目录名）
#   ./run-all.sh -v           附带每个示例的完整输出
#
# 判定标准（与 build.ps1 的 pwsh 通道逐项一致）：
#   ① 每个示例退出码 0
#   ② report.txt 非空（没有 report 一律判失败，不放过"静默通过"）
#   ③ report.txt 里没有 FAIL: 行（示例自校验自己判的）
#   ④ **同命令连跑两遍，report.txt 逐字节一致**（见下）
#
# 为什么不双通道对账：
#   build.ps1 的主验证形态是 pwsh 7 + Windows PowerShell 5.1 两通道对账，
#   但 **Windows PowerShell 5.1 只存在于 Windows**——macOS 上只有 pwsh 7。
#   所以本脚本按本仓库既有的单引擎纪律改用「同命令连跑两遍」：先跑一遍存产物，
#   再跑一遍，逐字节比对。这一条能抓住非确定性输出（时间戳、随机数、
#   进程名/ID 之类每次都变的值混进了 report.txt），而单跑一遍是抓不到的。
#   跑两遍之前先确认 report.txt 本身是确定的——本教程的 report 只记断言
#   结论（OK/FAIL/SKIP），不记时间、随机数、PID，所以两遍必然一致；
#   若哪天把 `Get-Date` 的值写进了 report，这条判据会立刻变红（这是它的用途）。
#
# 与 Windows 侧的平台差异（示例里都改成事实条件或带 [platform] 的 SKIP，
# 不是用平台宏把断言 #ifdef 掉；详见 README 平台差异表）：
#   * Get-Service / Get-CimInstance / Registry:: / Win32_* 类是 Windows-only，
#     Unix 版 pwsh 7 完全没有 → 相关断言按能力探测走 SKIP [platform]
#   * 执行策略（ExecutionPolicy）在 Unix 上恒 Unrestricted 且不可设置
#   * NTFS 备用数据流（-Stream / Zone.Identifier / MOTW）依赖文件系统，APFS 无
#   * Authenticode 签名 cmdlet 是 Windows-only
#   * New-PSSessionOption 的 WSMan 超时参数在 Unix 版被剔除（只剩 SSL 校验开关）
#
# 写本脚本的硬约束：所有变量写 ${var}——bash 5.3 下 $var 紧跟全角标点
# （中文括号、中文冒号）会被吞进变量名，set -u 时报 unbound variable。
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
# 工具链定位
# ------------------------------------------------------------
PWSH=""
for c in "${PWSH:-}" pwsh /opt/local/bin/pwsh /usr/local/bin/pwsh /usr/bin/pwsh; do
    if [ -n "${c}" ] && command -v "${c}" >/dev/null 2>&1; then PWSH="${c}"; break; fi
done
if [ -z "${PWSH}" ]; then
    echo "未找到 pwsh（PowerShell 7）。" >&2
    echo "修复：MacPorts 执行 sudo port install powershell-7，或用 PWSH=/path/to/pwsh ${0} 指定。" >&2
    exit 1
fi

PWSH_VER=$("${PWSH}" -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>/dev/null || echo unknown)
PWSH_EDITION=$("${PWSH}" -NoProfile -Command '$PSVersionTable.PSEdition' 2>/dev/null || echo unknown)
PWSH_OS=$("${PWSH}" -NoProfile -Command '$PSVersionTable.OS' 2>/dev/null || echo unknown)
if command -v powershell >/dev/null 2>&1; then
    echo "注意：本机存在 powershell（5.1），但它只支持 Windows 通道；本脚本按单引擎纪律验证。" >&2
fi

BUILD_DIR="${PWD}/build"
RUN1="${BUILD_DIR}/run1"
RUN2="${BUILD_DIR}/run2"

# 只清自己写的两个子目录，不 rm -rf build（build/ 下有人工留档的证据文件）
rm -rf "${RUN1}" "${RUN2}"
mkdir -p "${RUN1}" "${RUN2}"

echo "引擎: ${PWSH} (PowerShell ${PWSH_VER}, ${PWSH_EDITION}, ${PWSH_OS})"
echo "判定: 退出码 0 + report 非空 + 无 FAIL + 连跑两遍 report.txt 逐字节一致"
echo

# ------------------------------------------------------------
# 收集示例目录（NN_slug 形式，按名排序 = 按章号排序）
# ------------------------------------------------------------
mapfile -t ALL_EXAMPLES < <(find examples -mindepth 1 -maxdepth 1 -type d | sort)
if [ "${#ALL_EXAMPLES[@]}" -eq 0 ]; then
    echo "错误：examples/ 下没找到任何示例目录（收到 0 个目标就退出，不要静默通过）。" >&2
    exit 1
fi

EXAMPLES=()
if [ "${#SELECT[@]}" -eq 0 ]; then
    EXAMPLES=("${ALL_EXAMPLES[@]}")
else
    for sel in "${SELECT[@]}"; do
        matched=0
        for d in "${ALL_EXAMPLES[@]}"; do
            base=$(basename "${d}")
            # 支持 "09"、"09_*"、"09_pipeline_deep"、"*pipeline*" 几种写法
            case "${base}" in
                "${sel}"*|*"${sel}"*) EXAMPLES+=("${d}"); matched=1 ;;
            esac
        done
        if [ "${matched}" -eq 0 ]; then
            echo "指定的示例没匹配到：${sel}" >&2
            exit 1
        fi
    done
fi

echo "示例数: ${#EXAMPLES[@]}"

# ------------------------------------------------------------
# 跑两遍
#
# 注意 pwsh 的调用形式：本机 pwsh 7.6 在 `pwsh -File x.ps1` 下会崩
# （Call to 'procargs' failed with errno 5），必须走 -Command '& ./x.ps1'。
# 这是本仓库 PowerShell 侧验证的固定写法（见 CHEATSheet 26b）。
# ------------------------------------------------------------
run_pass() {
    local outdir="$1" d name base
    for d in "${EXAMPLES[@]}"; do
        base=$(basename "${d}")
        name="${base}"
        # 两次运行各自独立目录，report.txt 由示例自己写到 examples/ 下，
        # 所以每跑完一个就立刻拷出来，避免被下一个覆盖。
        ( cd "${d}" && "${PWSH}" -NoProfile -NonInteractive -ExecutionPolicy Bypass \
            -Command '& ./run.ps1' ) >"${outdir}/${name}.stdout" 2>"${outdir}/${name}.stderr"
        echo "$?" > "${outdir}/${name}.rc"
        if [ -f "${d}/report.txt" ]; then
            cp "${d}/report.txt" "${outdir}/${name}.report"
        else
            : > "${outdir}/${name}.report"
        fi
    done
}

echo "--- 第一遍 ---"
run_pass "${RUN1}"
echo "--- 第二遍（确定性对账用） ---"
run_pass "${RUN2}"
echo

# ------------------------------------------------------------
# 判定
# ------------------------------------------------------------
PASS=0
FAIL=0
ROWS=()
check_one() {
    local name="$1" pass=1 why=""

    local rc_file="${RUN1}/${name}.rc"
    local rc
    rc=$(cat "${rc_file}" 2>/dev/null || echo "-1")

    local report="${RUN1}/${name}.report"
    local report2="${RUN2}/${name}.report"

    # ② report 非空
    if [ ! -s "${report}" ]; then
        why="${why} report 缺失/空;"
        pass=0
    fi
    # ① 退出码
    if [ "${rc}" != "0" ]; then
        why="${why} 退出码 ${rc};"
        pass=0
    fi
    # ③ 无 FAIL 行
    if grep -q '^FAIL:' "${report}" 2>/dev/null; then
        why="${why} 有 FAIL 断言;"
        pass=0
    fi
    # ④ 连跑两遍逐字节一致
    if ! cmp -s "${report}" "${report2}"; then
        why="${why} 两遍 report 不一致;"
        pass=0
    fi

    local nskip=0 nok=0
    if [ -f "${report}" ]; then
        # 注意：grep -c 无匹配时**仍输出 0 并返回 1**，所以不能再 `|| echo 0` 叠加，
        # 否则计数会变成 "0\n0"，printf 里就把换行打进了表格（实测踩过，CHEATSheet 34a）。
        nskip=$(grep -c '^SKIP:' "${report}" 2>/dev/null) || true
        nok=$(grep -c '^OK:' "${report}" 2>/dev/null) || true
        nskip=${nskip:-0}
        nok=${nok:-0}
    fi

    if [ "${pass}" -eq 1 ]; then
        ROWS+=("$(printf '  %-26s PASS   OK=%-3s SKIP=%-3s' "${name}" "${nok}" "${nskip}")")
        PASS=$((PASS + 1))
    else
        ROWS+=("$(printf '  %-26s FAIL   %s' "${name}" "${why}")")
        FAIL=$((FAIL + 1))
    fi
}

for d in "${EXAMPLES[@]}"; do
    check_one "$(basename "${d}")"
done

printf '%s\n' "${ROWS[@]}"
echo

# 「零断言通过」要显式点名。PASS 只说明没有 FAIL，但如果一个 OK 都没有、
# 全是 SKIP，它其实什么都没验证——和「查过了没问题」不是一回事。
ALL_SKIP=()
for d in "${EXAMPLES[@]}"; do
    name=$(basename "${d}")
    rep="${RUN1}/${name}.report"
    if [ -s "${rep}" ] && ! grep -q '^OK:' "${rep}" 2>/dev/null; then
        ALL_SKIP+=("${name}")
    fi
done
if [ "${#ALL_SKIP[@]}" -gt 0 ]; then
    echo "零断言通过（全部 SKIP，等于本机没验证到东西）: ${ALL_SKIP[*]}"
    echo
fi

echo "通过 ${PASS} / 失败 ${FAIL} / 共 $((PASS + FAIL))（pwsh ${PWSH_VER} 单引擎 · 连跑两遍确定性对账）"

if [ "${VERBOSE}" -eq 1 ]; then
    echo
    echo "================ 详细输出 ================"
    for d in "${EXAMPLES[@]}"; do
        name=$(basename "${d}")
        echo "---------------- ${name} ----------------"
        echo "--- stdout ---"; cat "${RUN1}/${name}.stdout" 2>/dev/null
        echo "--- stderr ---"; cat "${RUN1}/${name}.stderr" 2>/dev/null
        echo "--- report ---"; cat "${RUN1}/${name}.report" 2>/dev/null
    done
fi

[ "${FAIL}" -eq 0 ] || exit 1
exit 0