#!/bin/bash
# 本书 5.1 的那条排版规则：「使用操作符的时候，例如 =、+、-、/ 或 * 号，
# 你必须让它两边都有一个空格的间隔……Swift 编译器将会报错」。
#
# 这条规则没法用主线示例断言（凡是不合规的写法都编译不过），所以按本书 §2 的
# 表格逐条现编现跑：每次把一条写法拼进一个临时 main.swift，只抄 swiftc 的原话。
# 用法：./w01_whitespace.sh
set -u
HERE="$(cd "$(dirname "$0")" && pwd)"
XCODE_XT="$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr"
SDK="$(xcrun -sdk iphonesimulator --show-sdk-path)"
TMP="${TMPDIR:-/tmp}/iosdev30ws"
mkdir -p "$TMP"

try() {   # $1 = 一条写法
    printf '%s\n' 'import Foundation' 'var h = 19' "$1" > "$TMP/main.swift"
    out="$("$XCODE_XT/bin/swiftc" -Onone -sdk "$SDK" -target x86_64-apple-ios15.0-simulator \
        -module-name probe "$TMP/main.swift" -o "$TMP/probe" -framework Foundation 2>&1 \
        | grep -E '(error|warning): ' | sed -e 's/^/      /')"
    if [ -z "$out" ]; then
        printf '%-24s 通过（零诊断）\n' "$1"
    else
        printf '%-24s 有诊断：\n%s\n' "$1" "$out"
    fi
}

printf '== 赋值号 = 的四种空格组合 ==\n'
try 'h = 20'
try 'h=20'
try 'h =20'
try 'h= 20'
printf '\n== 中缀 + 的四种写法 ==\n'
try 'h = h + 1'
try 'h = h+1'
try 'h = h +1'
try 'h = h+ 1'
try 'h = h+1+2'
printf '\n== 其他 ==\n'
try 'h += 1'
try 'print(h)'
try $'let a = 3/2\nprint(a)'
try $'let b = 7/2.0\nprint(b)'
rm -rf "$TMP"
