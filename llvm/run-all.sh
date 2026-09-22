#!/usr/bin/env bash
# ============================================================
# run-all.sh —— LLVM 教程的 macOS/Linux 全量验证入口（build.ps1 的 shell 镜像）
#
#   ./run-all.sh              跑全部 24 个示例
#   ./run-all.sh 06 11        只跑指定章号（也可写完整目录名）
#   ./run-all.sh -v           附带每个步骤的完整输出
#
# 判定标准（与 build.ps1 逐项对齐，另有两条本侧加强）：
#   ① 每步命令退出码 0
#   ② strict 步骤的 stderr 必须为空（report 步骤放开——LLVM 的 pass 报告走 errs()）
#   ③ 声明了结束标记的步骤，stdout+stderr 里必须有 "==== NN ok ===="
#   ④ 声明了正则的步骤，输出必须匹配（--nregex 则必须**不**匹配）
#   ⑤ **编译日志必须为空**：-Wall -Wextra 下 clang 成功时一个字都不打，
#      日志非空 = 有告警 = 失败。这条抓到过 MiniLang 里一个没用到的
#      `BasicBlock *LBB`（MSYS2 的 g++ 不开 -Wall，Windows 侧一直没暴露）。
#   ⑥ 双通道产物输出逐字节一致（见下）
#
# 双通道：shared（链 libLLVM-2x.dylib）vs static（链几十个组件 .a）。
#   两产物同源，比对检验的是「示例有没有偷偷依赖动态库加载/安装前缀」——
#   ORC JIT 那章尤其敏感：宿主函数要能被 dlsym(RTLD_DEFAULT) 找到，
#   静态链接时若可见性写错就会只在 static 通道崩。
#
# 与 Windows 侧的平台差异（都改成事实条件，不是用平台宏把断言 #ifdef 掉）：
#   * 01 章 clang 不再 -target x86_64-pc-windows-gnu，用宿主机默认三元组
#   * 10 章本机汇编的乘法助记符随 CPU 变（x86_64→imul，arm64→mul），
#     交叉编 aarch64 恒为 mul
#   * 11 章宿主导出：Windows 要 __declspec(dllexport)，Unix 要
#     __attribute__((visibility("default")))，示例用宏统一（不是#if 掉一侧）
#   * 22 章跨版本 IR 互通：Windows 是 clang23→lli22，macOS 是 clang23→lli21
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
#
# 教程正文写的是 LLVM 22.1.8（MSYS2 UCRT64）。MacPorts 上只有 19/21/23，
# 选 23 的理由是**头文件布局**：22 起的 llvm/Plugins/PassPlugin.h 在 23 里
# 就位，而 21 还是老位置 llvm/Passes/PassPlugin.h（06/07 章会直接编不过）。
# 其余用到的 API（Triple 对象、parseIR(MemoryBufferRef)、
# getProcessSymbolsJITDylib）在 23 上行为一致，见 README 的平台差异表。
# ------------------------------------------------------------
LLVM_PREFIX_CANDIDATES=(
    "${LLVM_PREFIX:-}"
    /opt/local/libexec/llvm-23
    /opt/local/libexec/llvm-22
    /opt/local/libexec/llvm-21
    /opt/local/libexec/llvm-19
    /opt/local
    /opt/homebrew/opt/llvm
    /usr/local/opt/llvm
    /usr
)
NEED_TOOLS=(opt lli llc llvm-as llvm-dis llvm-config clang)

llvm_prefix_ok() {
    local p="$1" t
    [ -n "$p" ] || return 1
    for t in "${NEED_TOOLS[@]}"; do
        [ -x "$p/bin/$t" ] || return 1
    done
    return 0
}

LLVM_PREFIX=""
for c in "${LLVM_PREFIX_CANDIDATES[@]}"; do
    if llvm_prefix_ok "$c"; then LLVM_PREFIX="$c"; break; fi
done
if [ -z "$LLVM_PREFIX" ]; then
    echo "未找到完整 LLVM（bin 下需要有 ${NEED_TOOLS[*]}）。" >&2
    echo "修复：MacPorts 执行 sudo port install llvm-23，或用 LLVM_PREFIX=/path/to/llvm $0 指定。" >&2
    exit 1
fi

LLVM_BIN="$LLVM_PREFIX/bin"
LLVM_CONFIG="$LLVM_BIN/llvm-config"
BUILD_DIR="$PWD/build"

# C++ 编译器：优先 MacPorts 的 clang++-mp-<版本> 包装脚本，它内部走 xcrun，
# 会自己带上 Xcode SDK（少了 SDK，libc++ 的 <wchar.h> 依赖链就断，报
# mbstate_t/EOF 未声明）；其次是与 LLVM 同目录的 clang++，最后退回通用名字。
# 注意别用系统 g++：llvm-config --cxxflags 带 -stdlib=libc++，指向 libstdc++ 会打架。
LLVM_MAJOR=$("$LLVM_CONFIG" --version | cut -d. -f1)
LLVM_CXX=""
for c in "${CXX:-}" "/opt/local/bin/clang++-mp-${LLVM_MAJOR}" "$LLVM_BIN/clang++" \
         /opt/local/bin/clang++-mp-23 /opt/local/bin/clang++-mp-21 /opt/local/bin/clang++-mp-19 clang++ c++; do
    if [ -n "$c" ] && command -v "$c" >/dev/null 2>&1; then LLVM_CXX="$c"; break; fi
done
if [ -z "$LLVM_CXX" ]; then
    echo "未找到 C++ 编译器（可设 CXX=/path/to/clang++）" >&2
    exit 1
fi

# 第二套 LLVM：给第 22 章做「跨版本 IR 互通」（产 IR 与执行 IR 用不同版本）
LLVM2_BIN=""
for c in "${LLVM2_PREFIX:-}" /opt/local/libexec/llvm-21 /opt/local/libexec/llvm-19; do
    if [ -n "$c" ] && [ "$c" != "$LLVM_PREFIX" ] && [ -x "$c/bin/lli" ]; then LLVM2_BIN="$c/bin"; break; fi
done
[ -n "$LLVM2_BIN" ] || LLVM2_BIN="$LLVM_BIN"

# macOS：MacPorts 的 clang 不认 Xcode 的隐式 SDK 查找，少了 -isysroot
# 连 stdio.h 都找不到（链接期则是 ld: library 'System' not found）
SDK_ARGS=()
if [ "$(uname -s)" = "Darwin" ] && command -v xcrun >/dev/null 2>&1; then
    _sdk=$(xcrun --show-sdk-path 2>/dev/null || true)
    [ -n "$_sdk" ] && SDK_ARGS=(-isysroot "$_sdk")
fi

# 编译旗标：把 llvm-config 的 -I 换成 -isystem。
# 不换的话 -Wall -Wextra 会把 LLVM 自己的头文件刷屏（ilist.h、StringExtras.h
# 里一堆 unused parameter），真正属于示例的告警反而被淹掉。
LLVM_INCDIR=$("$LLVM_CONFIG" --includedir)
CXXFLAGS=()
while IFS= read -r _f; do
    [ -n "$_f" ] || continue
    case "$_f" in
        -I*) ;;                     # 换成下面的 -isystem
        *) CXXFLAGS+=("$_f") ;;
    esac
done < <("$LLVM_CONFIG" --cxxflags | tr ' ' '\n')
CXXFLAGS+=(-isystem "$LLVM_INCDIR" -Wall -Wextra)
# 显式带 SDK 根：LLVM 自己的头文件不碰 libc，但 llvm/FileCheck/FileCheck.h
# → ADL.h → <iterator> → <iosfwd> 这条链会用到 SDK 的 <wchar.h>，
# 少了 -isysroot 就报 "reference to unresolved using declaration"（mbstate_t）。
# 只靠 xcrun 包装脚本隐式补是碰运气，这里显式带上。
[ ${#SDK_ARGS[@]} -gt 0 ] && CXXFLAGS+=("${SDK_ARGS[@]}")

# llvm-config 的输出按空格切成数组（不用 mapfile：/bin/bash 3.2 没有）
LLVM_LF=()
llvm_link_flags() {   # llvm_link_flags <shared|static> <组件...>
    local mode="$1"; shift
    LLVM_LF=()
    local f src
    if [ "$mode" = "shared" ]; then
        src=$("$LLVM_CONFIG" --ldflags --link-shared --libs "$@")
    else
        src=$("$LLVM_CONFIG" --ldflags --libs "$@"; "$LLVM_CONFIG" --system-libs)
    fi
    while IFS= read -r f; do
        [ -n "$f" ] && LLVM_LF+=("$f")
    done < <(printf '%s\n' "$src" | tr ' ' '\n')
}

# ---- FileCheck：MacPorts 的 llvm-2x 只有库没有可执行文件 ----
# port contents llvm-23 里能搜到 libLLVMFileCheck.a 和 llvm/FileCheck/FileCheck.h，
# 但搜不到 bin/FileCheck。第 21 章的回归测试离不开它，于是用官方那份实现
# 自己链一个驱动（tools/filecheck_main.cpp）——同一个库、同一个解析器，
# 不是换个实现糊弄；工具链自带 FileCheck 时不会走到这里。
FILECHECK="$LLVM_BIN/FileCheck"
if [ ! -x "$FILECHECK" ]; then
    mkdir -p "$BUILD_DIR/bin"
    FILECHECK="$BUILD_DIR/bin/FileCheck"
    llvm_link_flags shared FileCheck support
    "$LLVM_CXX" "${CXXFLAGS[@]}" "$PWD/tools/filecheck_main.cpp" -o "$FILECHECK" "${LLVM_LF[@]}" \
        >"$BUILD_DIR/bin/filecheck.build" 2>&1 \
        || { echo "自制 FileCheck 驱动编译失败，见 build/bin/filecheck.build" >&2
             sed 's/^/    /' "$BUILD_DIR/bin/filecheck.build" >&2; exit 1; }
    echo "[FileCheck] 工具链未带 FileCheck，已用 libLLVMFileCheck 自建：${FILECHECK}"
fi

echo "[Toolchain] $("$LLVM_CONFIG" --version)  prefix=${LLVM_PREFIX}"
echo "[CXX      ] ${LLVM_CXX}"
[ "${LLVM2_BIN}" != "${LLVM_BIN}" ] && echo "[Cross IR ] 产 IR ${LLVM_BIN}/clang → 执行 ${LLVM2_BIN}/lli"
[ ${#SDK_ARGS[@]} -gt 0 ] && echo "[SDK      ] ${SDK_ARGS[*]}"
echo

STEP_DIR="$BUILD_DIR/steps"
EXAMPLES_DIR="$PWD/examples"
mkdir -p "$STEP_DIR"

# 导出给示例自带的 run.sh / regr.sh 用
export LLVM_PREFIX LLVM_BIN LLVM2_BIN LLVM_CONFIG LLVM_CXX
export SDK_ARGS_STR="${SDK_ARGS[*]:-}"
export REPO_BUILD="$BUILD_DIR"
export RUN_ALL_VERBOSE="$VERBOSE"

PASS=0
FAIL=0
SKIP=0
FAILED_LIST=()
SKIPPED_LIST=()

# ------------------------------------------------------------
# 步骤执行与判定
#
#   run_step <label> [选项] -- <cmd...>
#     选项： --allow-stderr   允许 stderr 非空（pass 报告走 errs()）
#           --marker  <str>   合并输出里必须出现该字面量
#           --regex   <re>    合并输出里必须匹配该正则（可多次给出）
#           --nregex  <re>    合并输出里必须**不**匹配该正则
#   build_step <label> -- <cmd...>   编译：stdout+stderr 归日志，日志非空即失败
# ------------------------------------------------------------
run_step() {
    local label="$1"; shift
    local policy="strict" marker="" all
    local -a regexes=() nregexes=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --allow-stderr) policy="report"; shift ;;
            --marker)  marker="$2";  shift 2 ;;
            --regex)   regexes+=("$2");  shift 2 ;;
            --nregex)  nregexes+=("$2"); shift 2 ;;
            --) shift; break ;;
            *) break ;;
        esac
    done
    local o="$STEP_DIR/$label.out" e="$STEP_DIR/$label.err"
    all="$STEP_DIR/$label.all"
    "$@" >"$o" 2>"$e"
    local rc=$?
    local why=() r
    cat "$o" "$e" >"$all"

    [ "$rc" -ne 0 ] && why+=("退出码 $rc")
    if [ "$policy" = "strict" ] && [ -s "$e" ]; then why+=("stderr 非空"); fi
    if [ -n "$marker" ]; then
        LC_ALL=C grep -qF -- "$marker" "$all" || why+=("缺少结束标记 '${marker}'")
        # 打印型步骤顺带查一下控制字符（示例把二进制/半截 UTF-8 打出来的信号）
        if LC_ALL=C tr -d '\11\12\15' < "$o" 2>/dev/null | LC_ALL=C grep -q '[[:cntrl:]]'; then
            why+=("stdout 含控制字符")
        fi
    fi
    for r in "${regexes[@]}"; do
        LC_ALL=C grep -qE -- "$r" "$all" || why+=("输出未匹配 /${r}/")
    done
    for r in "${nregexes[@]}"; do
        LC_ALL=C grep -qE -- "$r" "$all" && why+=("输出出现了不该有的 /${r}/")
    done

    if [ ${#why[@]} -eq 0 ]; then
        [ "$VERBOSE" -eq 1 ] && sed 's/^/        /' "$all"
        return 0
    fi
    echo "        步骤 ${label} 失败：$(printf '%s；' "${why[@]}")"
    sed 's/^/          /' "$all" | head -12
    return 1
}

build_step() {
    local label="$1"; shift
    [ "$1" = "--" ] && shift
    local log="$STEP_DIR/$label.log"
    "$@" >"$log" 2>&1
    local rc=$?
    if [ "$rc" -ne 0 ] || [ -s "$log" ]; then
        if [ "$rc" -ne 0 ]; then
            echo "        编译 ${label} 失败（退出码 ${rc}）"
        else
            echo "        编译 ${label} 有告警（-Wall -Wextra 下日志应为空）"
        fi
        sed 's/^/          /' "$log" | head -15
        return 1
    fi
    return 0
}

llvm_build() {   # llvm_build <标签> <源码> <产物> <shared|static> <组件...>
    local label="$1" src="$2" out="$3" mode="$4"; shift 4
    llvm_link_flags "$mode" "$@"
    build_step "$label" -- "$LLVM_CXX" "${CXXFLAGS[@]}" "$src" -o "$out" "${LLVM_LF[@]}"
}

# Pass 插件只做 shared 通道：静态链会把 libLLVM 复制进插件，
# opt 与插件各持一份 LLVM，等着符号打架
llvm_plugin() {  # llvm_plugin <标签> <源码> <产物.so> <组件...>
    local label="$1" src="$2" out="$3"; shift 3
    llvm_link_flags shared "$@"
    build_step "$label" -- "$LLVM_CXX" -shared "${CXXFLAGS[@]}" "$src" -o "$out" "${LLVM_LF[@]}"
}

# ------------------------------------------------------------
# 各章验证（步骤与 build.ps1 一一对应）
# ------------------------------------------------------------
EX_DIR=""
EX_OUT=""

# 01：clang 产 IR → 位码往返 → lli 执行 → 对照原生编译产物
ex_01_overview() {
    run_step "01.clang-ir" -- "$LLVM_BIN/clang" "${SDK_ARGS[@]}" -S -emit-llvm -O1 \
             "$EX_DIR/hello.c" -o "$EX_OUT/hello.ll" || return 1
    run_step "01.llvm-as"  -- "$LLVM_BIN/llvm-as"  "$EX_OUT/hello.ll" -o "$EX_OUT/hello.bc" || return 1
    run_step "01.llvm-dis" -- "$LLVM_BIN/llvm-dis" "$EX_OUT/hello.bc" -o "$EX_OUT/hello.roundtrip.ll" || return 1
    run_step "01.lli" --marker "==== 01 ok ====" -- "$LLVM_BIN/lli" "$EX_OUT/hello.ll" || return 1
    build_step "01.native" -- "$LLVM_BIN/clang" "${SDK_ARGS[@]}" "$EX_DIR/hello.c" -o "$EX_OUT/hello_native" || return 1
    run_step "01.native-run" --marker "==== 01 ok ====" -- "$EX_OUT/hello_native" || return 1
}

# 通用 .ll：llvm-as → llvm-dis 往返 → lli 运行
ll_roundtrip() {
    local tag="$1" f="$2" marker="$3" base
    base="${f%.ll}"
    run_step "$tag.as"  -- "$LLVM_BIN/llvm-as"  "$EX_DIR/$f" -o "$EX_OUT/$base.bc" || return 1
    run_step "$tag.dis" -- "$LLVM_BIN/llvm-dis" "$EX_OUT/$base.bc" -o "$EX_OUT/$base.dis.ll" || return 1
    run_step "$tag.lli" --marker "$marker" -- "$LLVM_BIN/lli" "$EX_DIR/$f" || return 1
}

ex_02_first_ir() { ll_roundtrip "02.add" "add.ll" "==== 02 ok ===="; }
ex_03_ir_types() { ll_roundtrip "03.types" "types.ll" "==== 03 ok ===="; }

ex_04_ssa_phi() {
    ll_roundtrip "04.phi" "phi.ll" "==== 04 ok ====" || return 1
    ll_roundtrip "04.alloca" "allocastyle.ll" "==== 04 ok ====" || return 1
    run_step "04.mem2reg" -- "$LLVM_BIN/opt" -passes=mem2reg "$EX_DIR/allocastyle.ll" -S \
             -o "$EX_OUT/allocastyle.mem2reg.ll" || return 1
    LC_ALL=C grep -qw phi "$EX_OUT/allocastyle.mem2reg.ll" \
        || { echo "        mem2reg 输出里没有 phi——提升没发生？"; return 1; }
    run_step "04.mem2reg-lli" --marker "==== 04 ok ====" -- "$LLVM_BIN/lli" "$EX_OUT/allocastyle.mem2reg.ll" || return 1
}

ex_05_opt_pipeline() {
    ll_roundtrip "05.naive" "naive.ll" "==== 05 ok ====" || return 1
    local o
    for o in 0 1 2 3; do
        run_step "05.opt-O$o" -- "$LLVM_BIN/opt" "-O$o" "$EX_DIR/naive.ll" -S -o "$EX_OUT/naive.O$o.ll" || return 1
        run_step "05.lli-O$o" --marker "==== 05 ok ====" -- "$LLVM_BIN/lli" "$EX_OUT/naive.O$o.ll" || return 1
    done
}

ex_06_hello_pass() {
    llvm_plugin "06.plugin" "$EX_DIR/HelloPass.cpp" "$EX_OUT/HelloPass.so" core || return 1
    run_step "06.opt" --allow-stderr --regex "hello-pass: square" -- \
             "$LLVM_BIN/opt" -load-pass-plugin="$EX_OUT/HelloPass.so" -passes=hello-pass \
             "$EX_DIR/test.ll" -S -o "$EX_OUT/after.ll" || return 1
    run_step "06.lli" --marker "==== 06 ok ====" -- "$LLVM_BIN/lli" "$EX_OUT/after.ll" || return 1
}

ex_07_pass_analysis() {
    llvm_plugin "07.plugin" "$EX_DIR/InstStats.cpp" "$EX_OUT/InstStats.so" core analysis || return 1
    run_step "07.named" --allow-stderr --regex "mem-stats: sum_to load=3 store=4 alloca=2" -- \
             "$LLVM_BIN/opt" -load-pass-plugin="$EX_OUT/InstStats.so" -passes=inst-stats,mem-stats \
             "$EX_DIR/test.ll" -disable-output || return 1
    run_step "07.o2-ep" --allow-stderr --regex "mem-stats: sum_to load=0" -- \
             "$LLVM_BIN/opt" -load-pass-plugin="$EX_OUT/InstStats.so" -O2 \
             "$EX_DIR/test.ll" -S -o "$EX_OUT/after.O2.ll" || return 1
    run_step "07.o1-nore" --allow-stderr --nregex "mem-stats:" -- \
             "$LLVM_BIN/opt" -load-pass-plugin="$EX_OUT/InstStats.so" -O1 \
             "$EX_DIR/test.ll" -S -o "$EX_OUT/after.O1.ll" || return 1
    run_step "07.lli" --marker "==== 07 ok ====" -- "$LLVM_BIN/lli" "$EX_OUT/after.O2.ll" || return 1
}

# 08/09/11：C++ 工具类 —— 两通道各自构建，输出逐字节比对
ex_08_irbuilder() {
    local ch
    for ch in shared static; do
        llvm_build "08.build.$ch" "$EX_DIR/gen_fib.cpp" "$EX_OUT/gen_fib.$ch" "$ch" \
            core support irreader asmparser analysis passes || return 1
        run_step "08.gen.$ch" -- "$EX_OUT/gen_fib.$ch" "$EX_OUT/fib.$ch.ll" || return 1
        # 比对用 lli 的输出：gen_fib 自己会打印 "wrote <路径>"，路径带通道名必然不同
        run_step "08.lli.$ch" --marker "==== 08 ok ====" -- "$LLVM_BIN/lli" "$EX_OUT/fib.$ch.ll" || return 1
        cp "$STEP_DIR/08.lli.$ch.all" "$EX_OUT/run.$ch"
    done
    cmp -s "$EX_OUT/run.shared" "$EX_OUT/run.static" \
        || { echo "        两通道输出不一致（见 ${EX_OUT}/run.shared 与 run.static）"; return 1; }
}

ex_09_value_model() {
    local ch
    for ch in shared static; do
        llvm_build "09.build.$ch" "$EX_DIR/walker.cpp" "$EX_OUT/walker.$ch" "$ch" \
            core support irreader asmparser analysis passes || return 1
        # walker 的报告走 errs()（和 opt 的 pass 报告同一套约定），不是 stdout。
        # build.ps1 把 2>&1 合并了所以看不出来；这里显式放开 stderr。
        # 比对用的输出文件两通道同名（各写各的，内容一样），否则 walker 打印的
        # "wrote <路径>" 会带上通道名，比对必然不等——那是路径噪声不是行为差异
        run_step "09.walk.$ch" --allow-stderr --regex "binary:mul x1" \
            --regex "after RAUW: uses of @square = 0" -- \
            "$EX_OUT/walker.$ch" "$EX_DIR/walk.ll" "$EX_OUT/after.ll" || return 1
        cp "$STEP_DIR/09.walk.$ch.all" "$EX_OUT/run.$ch"
        run_step "09.lli.$ch" --marker "==== 09 ok ====" -- "$LLVM_BIN/lli" "$EX_OUT/after.ll" || return 1
    done
    cmp -s "$EX_OUT/run.shared" "$EX_OUT/run.static" \
        || { echo "        两通道输出不一致（见 ${EX_OUT}/run.shared 与 run.static）"; return 1; }
}

ex_11_orc_jit() {
    local ch
    for ch in shared static; do
        llvm_build "11.build.$ch" "$EX_DIR/jit_demo.cpp" "$EX_OUT/jit_demo.$ch" "$ch" \
            core support executionengine orcjit irreader asmparser || return 1
        # 宿主函数可见性：JIT 侧靠 dlsym(RTLD_DEFAULT) 找，两通道都必须 yes
        run_step "11.run.$ch" --marker "==== 11 ok ====" --regex "host_mul visible: yes" -- \
            "$EX_OUT/jit_demo.$ch" || return 1
        cp "$STEP_DIR/11.run.$ch.all" "$EX_OUT/run.$ch"
    done
    cmp -s "$EX_OUT/run.shared" "$EX_OUT/run.static" \
        || { echo "        两通道输出不一致（见 ${EX_OUT}/run.shared 与 run.static）"; return 1; }
}

# 10：llc 本机 + 交叉
ex_10_codegen() {
    run_step "10.llc-s" -- "$LLVM_BIN/llc" "$EX_DIR/demo.ll" -o "$EX_OUT/demo.s" || return 1
    run_step "10.llc-o" -- "$LLVM_BIN/llc" "$EX_DIR/demo.ll" -filetype=obj -o "$EX_OUT/demo.o" || return 1
    build_step "10.link" -- "$LLVM_BIN/clang" "${SDK_ARGS[@]}" "$EX_OUT/demo.o" -o "$EX_OUT/demo" || return 1
    run_step "10.run" --marker "==== 10 ok ====" -- "$EX_OUT/demo" || return 1
    run_step "10.cross" -- "$LLVM_BIN/llc" --mtriple=aarch64-linux-gnu "$EX_DIR/demo.ll" \
             -o "$EX_OUT/demo.aarch64.s" || return 1
    # 本机乘法助记符随 CPU 变（x86_64→imul / arm64→mul），按事实条件断言，
    # 不用平台宏跳过——跳过了这条断言就永久失效了
    local native_mul="imul"
    [ "$(uname -m)" = "arm64" ] && native_mul="mul"
    LC_ALL=C grep -q -- "$native_mul" "$EX_OUT/demo.s" \
        || { echo "        本机汇编未见 ${native_mul}"; return 1; }
    LC_ALL=C grep -qw -- "mul" "$EX_OUT/demo.aarch64.s" \
        || { echo "        aarch64 汇编未见 mul"; return 1; }
}

# 12：纯 C++ 前端，不链 LLVM
ex_12_minilang_front() {
    build_step "12.build" -- "$LLVM_CXX" -std=c++17 -Wall -Wextra "$EX_DIR/minilang.cpp" -o "$EX_OUT/minilang" || return 1
    run_step "12.ast" --marker "==== 12 ok ====" \
        --regex "\(binary - \(binary \+ 1 \(binary \* 2 3\)\) \(binary / 4 2\)\)" -- \
        "$EX_OUT/minilang" --ast "$EX_DIR/test.mini" || return 1
}

# ---- MiniLang 系列（13-20/24）----
ML_LIBS=(core support orcjit executionengine passes analysis)
ML_NATIVE=(codegen target native mc)

ml_build() {   # ml_build <章号> [额外组件...]
    local n="$1"; shift
    local ch
    for ch in shared static; do
        llvm_build "$n.build.$ch" "$EX_DIR/minilang.cpp" "$EX_OUT/minilang.$ch" "$ch" \
            "${ML_LIBS[@]}" "$@" || return 1
    done
}

# ml_run <章号> <标记> -- <参数...>   参数里的 @BIN@ 会换成当前通道的产物
ml_run() {
    local n="$1" marker="$2"; shift 3
    local ch a
    local -a real=()
    for ch in shared static; do
        real=()
        for a in "$@"; do
            if [ "$a" = "@BIN@" ]; then real+=("$EX_OUT/minilang.$ch"); else real+=("$a"); fi
        done
        run_step "$n.run.$ch" --marker "$marker" -- "${real[@]}" || return 1
        cp "$STEP_DIR/$n.run.$ch.all" "$EX_OUT/run.$ch"
    done
    cmp -s "$EX_OUT/run.shared" "$EX_OUT/run.static" \
        || { echo "        两通道输出不一致（见 ${EX_OUT}/run.shared 与 run.static）"; return 1; }
}

ex_13_minilang_ir() {
    ml_build 13 || return 1
    ml_run 13 "==== 13 ok ====" -- @BIN@ --ir "$EX_DIR/test.mini" "$EX_OUT/test.ll" || return 1
    local e
    for e in '55\.0+' '5050\.0+' '7\.0+' '10\.0+' '25\.0+' '0\.0+'; do
        run_step "13.lli" --regex "$e" -- "$LLVM_BIN/lli" "$EX_OUT/test.ll" || return 1
    done
}

ex_14_minilang_funcs() {
    ml_build 14 || return 1
    ml_run 14 "==== 14 ok ====" -- @BIN@ --jit "$EX_DIR/test.mini" || return 1
    run_step "14.jit-result" --regex '6\.765000e\+03' -- \
        "$EX_OUT/minilang.shared" --jit "$EX_DIR/test.mini" || return 1
    run_step "14.redefine" --marker "==== 14 ok ====" --regex '2\.000000e\+01' --regex '4\.000000e\+01' -- \
        "$EX_OUT/minilang.shared" --jit "$EX_DIR/redefine.mini" || return 1
}

ex_15_minilang_vars() {
    ml_build 15 || return 1
    ml_run 15 "==== 15 ok ====" -- @BIN@ --jit "$EX_DIR/test.mini" || return 1
    run_step "15.jit-result" --regex '8\.320400e\+05' -- \
        "$EX_OUT/minilang.shared" --jit "$EX_DIR/test.mini" || return 1
    run_step "15.ir" -- "$EX_OUT/minilang.shared" --ir "$EX_DIR/test.mini" "$EX_OUT/test.ll" || return 1
    run_step "15.mem2reg" -- "$LLVM_BIN/opt" -passes=mem2reg "$EX_OUT/test.ll" -S -o "$EX_OUT/test.mem2reg.ll" || return 1
    local raw phi
    raw=$(LC_ALL=C grep -c alloca "$EX_OUT/test.ll")
    phi=$(LC_ALL=C grep -cw phi "$EX_OUT/test.mem2reg.ll")
    if [ "$raw" -lt 5 ] || [ "$phi" -lt 3 ]; then
        echo "        mem2reg 前后对比异常：alloca=${raw} phi=${phi}"
        return 1
    fi
}

ex_16_minilang_ops() {
    ml_build 16 || return 1
    ml_run 16 "==== 16 ok ====" -- @BIN@ --jit "$EX_DIR/test.mini" || return 1
    run_step "16.values" \
        --regex '7\.200000e\+02' --regex '7\.000000e\+00' --regex '6\.000000e\+00' \
        --regex '-2\.400000e\+01' --regex '5\.500000e\+01' -- \
        "$EX_OUT/minilang.shared" --jit "$EX_DIR/test.mini" || return 1
}

ex_17_minilang_opt() {
    ml_build 17 || return 1
    ml_run 17 "==== 17 ok ====" -- @BIN@ --jit "$EX_DIR/test.mini" || return 1
    run_step "17.jit0" --marker "==== 17 ok ====" --regex '6\.765000e\+03' -- \
        "$EX_OUT/minilang.shared" --jit0 "$EX_DIR/test.mini" || return 1
    run_step "17.jit-result" --regex '6\.765000e\+03' -- \
        "$EX_OUT/minilang.shared" --jit "$EX_DIR/test.mini" || return 1
    run_step "17.ir" -- "$EX_OUT/minilang.shared" --ir "$EX_DIR/foldcheck.mini" "$EX_OUT/foldcheck.ll" || return 1
    run_step "17.opt-o2" -- "$LLVM_BIN/opt" -O2 "$EX_OUT/foldcheck.ll" -S -o "$EX_OUT/foldcheck.O2.ll" || return 1
    LC_ALL=C grep -q '\.i:' "$EX_OUT/foldcheck.O2.ll" \
        || { echo "        -O2 输出无内联痕迹（.i 块）"; return 1; }
}

ex_18_minilang_cf() {
    ml_build 18 || return 1
    ml_run 18 "==== 18 ok ====" -- @BIN@ --jit "$EX_DIR/test.mini" || return 1
    run_step "18.values" --regex '1\.024000e\+03' --regex '0\.000000e\+00' --regex '1\.000000e\+00' -- \
        "$EX_OUT/minilang.shared" --jit "$EX_DIR/test.mini" || return 1
}

ex_19_minilang_pass() {
    ml_build 19 || return 1
    ml_run 19 "==== 19 ok ====" -- @BIN@ --stats "$EX_DIR/test.mini" || return 1
    run_step "19.values" \
        --regex 'sum_to bb=[0-9]+ insts=[0-9]+ alloca=[0-9]+' \
        --regex 'ml-stats: sum_to bb=[0-9]+ insts=[0-9]+ alloca=0 load=0 store=0' -- \
        "$EX_OUT/minilang.shared" --stats "$EX_DIR/test.mini" || return 1
}

ex_20_minilang_native() {
    ml_build 20 "${ML_NATIVE[@]}" || return 1
    ml_run 20 "==== 20 ok ====" -- @BIN@ --obj "$EX_DIR/test.mini" "$EX_OUT/test.o" || return 1
    build_step "20.link" -- "$LLVM_BIN/clang" "${SDK_ARGS[@]}" "$EX_OUT/test.o" -o "$EX_OUT/test" || return 1
    local e
    for e in '610\.0+' '125250\.0+' '-55\.0+'; do
        run_step "20.run" --regex "$e" -- "$EX_OUT/test" || return 1
    done
}

# 21：FileCheck 回归（复用 20 章构建的 minilang 产 IR）
ex_21_filecheck() {
    local ml20="$BUILD_DIR/20_minilang_native/minilang.shared"
    if [ ! -x "$ml20" ]; then
        echo "        先跑 20 章（-All 顺序保证 ${ml20} 已就位）"
        return 1
    fi
    run_step "21.ir" -- "$ml20" --ir "$EX_DIR/fib.mini" "$EX_OUT/fib.ll" || return 1
    run_step "21.raw" -- "$FILECHECK" "$EX_DIR/checks/fib-raw.checks" --input-file "$EX_OUT/fib.ll" || return 1
    run_step "21.opt" -- "$LLVM_BIN/opt" -O2 "$EX_OUT/fib.ll" -S -o "$EX_OUT/fib.O2.ll" || return 1
    run_step "21.optcheck" -- "$FILECHECK" "$EX_DIR/checks/fib-opt.checks" --input-file "$EX_OUT/fib.O2.ll" || return 1
}

# 22/23：示例自带脚本（PowerShell 侧是 run.ps1，本侧是 run.sh）
ex_22_clang_tools() {
    [ -f "$EX_DIR/run.sh" ] || { echo "        缺少 ${EX_DIR}/run.sh"; return 1; }
    run_step "22.script" --marker "==== 22 ok ====" -- bash "$EX_DIR/run.sh"
}
ex_23_source_tour() {
    [ -f "$EX_DIR/run.sh" ] || { echo "        缺少 ${EX_DIR}/run.sh"; return 1; }
    run_step "23.script" --marker "==== 23 ok ====" -- bash "$EX_DIR/run.sh"
}

# 24：v1.0 回归（regr.sh）
ex_24_minilang_full() {
    ml_build 24 "${ML_NATIVE[@]}" || return 1
    [ -f "$EX_DIR/regr.sh" ] || { echo "        缺少 ${EX_DIR}/regr.sh"; return 1; }
    run_step "24.regr" --marker "==== 24 ok ====" -- bash "$EX_DIR/regr.sh"
}

# ------------------------------------------------------------
# 主循环
# ------------------------------------------------------------
for dir in "$EXAMPLES_DIR"/*/; do
    [ -d "$dir" ] || continue
    name=$(basename "$dir")
    num=${name%%_*}

    if [ ${#SELECT[@]} -gt 0 ]; then
        hit=0
        for s in "${SELECT[@]}"; do
            if [ "$s" = "$num" ] || [ "$s" = "$name" ]; then hit=1; fi
        done
        [ "$hit" -eq 1 ] || continue
    fi

    echo "==== $name ===="
    EX_DIR="$dir"
    EX_OUT="$BUILD_DIR/$name"
    mkdir -p "$EX_OUT"

    # 第 23 章要一份 LLVM 源码检出（Windows 侧是 G:\github\lang\llvm-project）。
    # 本机没有就是环境缺口 → 记 SKIP，不去改断言迁就环境。
    if [ "$name" = "23_source_tour" ] && [ -z "${LLVM_SRC:-}" ]; then
        echo "  [SKIP] 需要 LLVM 源码检出：用 LLVM_SRC=/path/to/llvm-project $0 指定"
        SKIP=$((SKIP + 1))
        SKIPPED_LIST+=("${name}（缺 LLVM_SRC）")
        continue
    fi

    if "ex_$name"; then
        PASS=$((PASS + 1))
        echo "  [OK] $name"
    else
        FAIL=$((FAIL + 1))
        FAILED_LIST+=("$name")
        echo "  [FAIL] $name"
    fi
done

echo
echo "通过 $PASS   失败 $FAIL   跳过 $SKIP"
if [ ${#FAILED_LIST[@]} -gt 0 ]; then
    echo "失败项："
    for t in "${FAILED_LIST[@]}"; do echo "  - $t"; done
fi
if [ ${#SKIPPED_LIST[@]} -gt 0 ]; then
    echo "跳过项："
    for t in "${SKIPPED_LIST[@]}"; do echo "  - $t"; done
fi
[ "$FAIL" -eq 0 ] && exit 0
exit 1
