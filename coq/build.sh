#!/usr/bin/env bash
# build.sh —— macOS / Linux 下的示例编译脚本（与 build.ps1 用法一致）
set -euo pipefail

projectRoot="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$projectRoot"

examplesDir="$projectRoot/examples"
buildDir="$projectRoot/build"
buildExamplesDir="$buildDir/examples"

ALL=0
CLEAN=0
FILE=""

usage() {
    echo "用法:"
    echo "  ./build.sh -All          编译 examples 下全部示例"
    echo "  ./build.sh -File <name>  编译单个示例（如 01_intro.v）"
    echo "  ./build.sh -Clean        清理 build 目录"
}

while [ $# -gt 0 ]; do
    case "$1" in
        -All)   ALL=1 ;;
        -Clean) CLEAN=1 ;;
        -File)
            shift
            FILE="${1:-}"
            if [ -z "$FILE" ]; then
                echo "-File 需要一个文件名参数。" >&2
                exit 1
            fi
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "未知参数: $1" >&2
            usage >&2
            exit 1
            ;;
    esac
    shift
done

if [ "$CLEAN" -eq 1 ]; then
    if [ -d "$buildDir" ]; then
        rm -rf "$buildDir"
        echo "[Clean] 已清理 build 目录。"
    else
        echo "[Clean] build 目录不存在，无需清理。"
    fi
    exit 0
fi

if [ "$ALL" -eq 0 ] && [ -z "$FILE" ]; then
    usage
    exit 0
fi

if ! command -v rocq >/dev/null 2>&1; then
    echo "未找到 rocq，请检查 Rocq 安装与 PATH 配置。" >&2
    exit 1
fi

if [ ! -d "$examplesDir" ]; then
    echo "找不到 examples 目录: $examplesDir" >&2
    exit 1
fi

mkdir -p "$buildExamplesDir"

# SLF 库标志集：Software Foundations 第 6 卷 Separation Logic Foundations 的
# 库（章节 .flags 里写 @slf 即可引用）。首次使用时把 lib/slf/*.v 按依赖序
# 编译到 build/slf（后续复用，-Clean 后重建）。SLF_ORDER 即原书 Makefile 的库
# 文件拓扑序；-w 抑制原书 _CoqProject 声明的四类告警。
SLFSRC="$projectRoot/lib/slf"
SLF_ORDER="LibAxioms LibTactics LibEqual LibLogic LibOperation LibBool LibReflect LibProd LibSum LibRelation LibOrder LibNat LibEpsilon LibInt LibMonoid LibContainer LibOption LibWf LibList LibListExec LibListZ LibMin LibSet LibChoice LibUnit LibFun LibString LibMultiset LibCore LibSepTLCbuffer LibSepFmap LibSepVar LibSepSimpl LibSepMinimal LibSepReference"
slf_flags() {
    local out="$buildDir/slf"
    if [ ! -f "$out/LibSepReference.vo" ]; then
        mkdir -p "$out"
        cp "$SLFSRC"/*.v "$out/"
        echo "[SLF] 首次构建 SLF 库（35 个文件，一次性）..." >&2
        (cd "$out" && for f in $SLF_ORDER; do
            if [ ! -f "$f.vo" ]; then
                echo "[SLF] compile $f.v" >&2
                rocq compile -q -Q . SLF \
                  -w -implicit-core-hint-db,-ambiguous-paths,-notation-incompatible-prefix,-automatic-prop-lowering \
                  "$f.v" || exit 1
            fi
        done) >&2
    fi
    printf '%s ' -Q "$out" SLF -w -implicit-core-hint-db,-ambiguous-paths,-notation-incompatible-prefix,-automatic-prop-lowering
}

# VST 标志集：供需要 Verified Software Toolchain 的章节（.flags 里写 @vst）。
VSTDIR="${VSTDIR:-/Volumes/mac004/tutorialsrc/vst-2.16}"
vst_flags() {
    printf '%s ' \
      -Q "$VSTDIR/msl" VST.msl \
      -Q "$VSTDIR/veric" VST.veric \
      -Q "$VSTDIR/floyd" VST.floyd \
      -Q "$VSTDIR/zlist" VST.zlist \
      -Q "$VSTDIR/sepcomp" VST.sepcomp \
      -Q "$VSTDIR/compcert/lib" compcert.lib \
      -Q "$VSTDIR/compcert/common" compcert.common \
      -Q "$VSTDIR/compcert/x86_64" compcert.x86_64 \
      -Q "$VSTDIR/compcert/x86" compcert.x86 \
      -Q "$VSTDIR/compcert/cfrontend" compcert.cfrontend \
      -Q "$VSTDIR/compcert/export" compcert.export \
      -R "$VSTDIR/compcert/flocq" Flocq
}

# 读取 examples/NN_xxx.v.flags：额外 rocq 参数；首 token 可为 @vst 展开为 VST 标志集。
extra_flags() {
    local flags_file="$1"
    [ -f "$flags_file" ] || return 0
    local toks=()
    while IFS= read -r line; do
        [ -z "$line" ] && continue
        case "$line" in
            @slf) toks+=($(slf_flags)) ;;
        @vst) toks+=($(vst_flags)) ;;
            *)    toks+=($line) ;;
        esac
    done < "$flags_file"
    printf '%s ' "${toks[@]}"
}

# 预编译 examples/vc/ 下的依赖（如 Clight AST）：.deps 每行一个相对 examples/ 的路径，
# 编到 build/vc/<path>.vo。用 mkdir 锁防并行代理同时编同一文件。
compile_deps() {
    local deps_file="$1" xflags="$2" dep dest vo
    [ -f "$deps_file" ] || return 0
    while IFS= read -r dep; do
        [ -z "$dep" ] && continue
        dest="$buildDir/$(dirname "$dep")"
        vo="$dest/$(basename "${dep%.v}").vo"
        mkdir -p "$dest"
        if [ ! -f "$vo" ]; then
            while ! mkdir "$buildDir/.dep_lock" 2>/dev/null; do sleep 1; done
            if [ ! -f "$vo" ]; then
                echo "[Dep] $dep"
                cp "$examplesDir/$dep" "$dest/"
                (cd "$dest" && rocq compile -q $xflags "$(basename "$dep")") || { rmdir "$buildDir/.dep_lock"; exit 1; }
            fi
            rmdir "$buildDir/.dep_lock"
        fi
    done < "$deps_file"
}

compile_one() {
    local src="$1"
    local name
    name="$(basename "$src")"
    local target="$buildExamplesDir/ex_$name"
    local xflags
    xflags="$(extra_flags "${src}.flags")"
    if [ -f "${src}.deps" ]; then
        mkdir -p "$buildDir/vc"
        xflags="$xflags -Q $buildDir/vc VC"
    fi
    compile_deps "${src}.deps" "$xflags"
    cp "$src" "$target"
    echo "[Compile] ex_$name"
    (cd "$buildExamplesDir" && rocq compile -q $xflags "ex_$name")
}

if [ "$ALL" -eq 1 ]; then
    found=0
    for src in "$examplesDir"/*.v; do
        [ -e "$src" ] || continue
        found=1
        compile_one "$src"
    done
    if [ "$found" -eq 0 ]; then
        echo "examples 目录下没有 .v 示例文件。" >&2
        exit 1
    fi
    echo "[Done] examples 目录全部编译通过。"
    exit 0
fi

if [ -n "$FILE" ]; then
    if [ ! -f "$examplesDir/$FILE" ]; then
        echo "找不到示例文件: $FILE" >&2
        exit 1
    fi
    compile_one "$examplesDir/$FILE"
    echo "[Done] 编译通过: $FILE"
    exit 0
fi
