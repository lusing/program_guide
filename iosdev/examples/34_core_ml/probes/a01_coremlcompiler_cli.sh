#!/bin/bash
# 探针 a01：xcrun coremlcompiler 在本机上的原话（主机侧，不进模拟器）
#
# 为什么不进主线：coremlcompiler 是 **macOS 上的主机程序**，而主线示例是在模拟器里跑的，
# 拿不到它；书本 15.2.2 那句「拖进 Xcode 就自动出现一个 Model Class」其实就是它的
# generate 子命令。这里把它跑一遍，抄三样东西：
#   1) 命令原文与退出码（包括写错时的拒答原话 —— 主线 §18 的「墙三」就是这几句）；
#   2) compile 的产物目录结构（主线 §2 在设备上看到的那两样东西，这里是主机上的同一份）；
#   3) generate 的产物字节数 —— 主线 §5 里那句「46 字节的规格换来 10 961 字节的 Swift」
#      的唯一取证处（那个源码文件本体会提交进 ../tiny_scaler.swift，一行没改）。
#
# 跑法：bash probes/a01_coremlcompiler_cli.sh
set -u

HERE="$(cd "$(dirname "$0")" && pwd)"
TMP="${TMPDIR:-/tmp}/iosdev34a01"
rm -rf "$TMP"; mkdir -p "$TMP"

# 主线 §1 那份规格：从它自己的 hex 表示还原，a01 不需要任何编码器
HEX='080112150a070a01781a02120052070a01791a0212005a0179e22512090000000000002440110000000000000040'
MODEL="$TMP/tiny_scaler.mlmodel"
printf '%s' "$HEX" | xxd -r -p > "$MODEL"

# 命令 + 退出码 + 两份输出，一起打出来；stdout 走管道，所以不会被终端宽度改写
show() { # $1 = 标签 $2 = 文件
    if [ -s "$2" ]; then printf -- '--- %s ---\n%s\n' "$1" "$(cat "$2")"; else printf -- '--- %s ---（空）\n' "$1"; fi
}
run() {
    local desc="$1"; shift
    printf '\n$ %s\n' "$*"
    ( "$@" ) > "$TMP/out.txt" 2> "$TMP/err.txt"
    printf '退出码 = %s   （%s）\n' "$?" "$desc"
    show stdout "$TMP/out.txt"
    show stderr "$TMP/err.txt"
}

echo "== coremlcompiler 是哪个程序 =="
run "找到可执行文件" xcrun -f coremlcompiler

echo
echo "== 主线 §1 那份 46 字节的规格落在磁盘上 =="
printf '$ 由 hex 还原：%s\n' "$HEX"
printf '文件 %s = %s 个字节\n' "$MODEL" "$(wc -c < "$MODEL" | tr -d ' ')"

# ------------------------------------------------------------------ compile --
echo
echo "== compile：书本 15.2.2 里 Xcode 点 Build 时偷偷做的那一步 =="
run "把 .mlmodel 编成 .mlmodelc" xcrun coremlcompiler compile "$MODEL" "$TMP/compiled"
printf -- '--- 产物 ---\n'
( cd "$TMP/compiled" 2>/dev/null && find . -mindepth 1 -maxdepth 3 | sort | sed 's/^/  /' )
printf '  各文件字节数：\n'
( cd "$TMP/compiled" 2>/dev/null && find . -type f -exec wc -c {} \; | sort -k2 | sed 's/^/  /' )

# ----------------------------------------------------------------- generate --
echo
echo "== generate：书本说的那个 Model Class 就是这么来的 =="
# 目标目录必须**先存在**：coremlcompiler 不会替你创建它，写不进去就报
# 「unable to open output file」。这也是本机工具链的一条边界。
mkdir -p "$TMP/gen" "$TMP/refuse"
run "生成 Swift 模型类" xcrun coremlcompiler generate --language Swift "$MODEL" "$TMP/gen"
GEN="$TMP/gen/tiny_scaler.swift"
if [ -f "$GEN" ]; then
    printf -- '--- 生成物 ---\n  路径 %s\n  字节数 %s\n  行数 %s\n' "$GEN" "$(wc -c < "$GEN" | tr -d ' ')" "$(wc -l < "$GEN" | tr -d ' ')"
    printf -- '--- 生成物里的类与属性（grep 原文）---\n'
    grep -n "class \|var x: \|var y: \|let model: \|func prediction\|func predictions" "$GEN" | sed 's/^/  /'
    printf -- '--- 头 6 行（自动生成的那句免责声明就在里面）---\n'
    head -6 "$GEN" | sed 's/^/  /'
    printf -- '--- 与提交进仓库的那份（../tiny_scaler.swift）是否逐字节一致 ---\n'
    if cmp -s "$GEN" "$HERE/../tiny_scaler.swift"; then
        echo "  一致 —— 仓库里那份就是这条命令的产物，一行没改"
    else
        echo "  不一致（本机 SDK 与生成时不同？下面列出差异）"
        diff "$GEN" "$HERE/../tiny_scaler.swift" | head -20 | sed 's/^/  /'
    fi
fi

# ------------------------------------------------------------------- 拒答集 --
echo
echo "== 写错时的原话（主线 §18「墙三」的取证处）=="
run "没有子命令" xcrun coremlcompiler
run "语言名小写" xcrun coremlcompiler generate --language swift "$MODEL" "$TMP/refuse"
run "用 --output-path 而不是位置参数" xcrun coremlcompiler generate --language Swift --output-path "$TMP/refuse" "$MODEL"
run "缺目标目录" xcrun coremlcompiler compile "$MODEL"
run "喂一份不是 protobuf 的文件" xcrun coremlcompiler compile "$HERE/run.sh" "$TMP/refuse"
