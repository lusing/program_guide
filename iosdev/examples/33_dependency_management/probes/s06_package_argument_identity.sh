#!/bin/bash
# s06：`.product(name:package:)` 的两个参数各写错一次 —— 报错顺手把合法值打出来。
#
# 书 10.3 的 Podfile 写 `pod 'Alamofire'`，只有一个名字。SwiftPM 的 target 依赖
# 有两个坐标：product 名 + 提供它的那个包的 identity。这一支把两个坐标各写错一次，
# 再各写对一次，抄四次原文：
#   a) package 凭记忆写成 "Climate"      → unknown package，并把合法值列出来
#   b) package 写 Package 里那个 name     → 在本章的 fixture 上**照样通过**
#      （目录名恰好就是 ClimateCore —— 这一问要到 s07 才能答清楚）
#   c) name 写成 target 名以外的东西      → product not found，并把可买的 product 列出来
#   d) 两个都写对                        → Build complete
#
# b) 那一格是全章最容易骗人的一次「配好了」：它过了，但不是因为写对了。
set -u

WEATHER="$TMP/WeatherKit"
cp -R "$PKG_ROOT/ClimateCore" "$TMP/ClimateCore"
cp -R "$PKG_ROOT/WeatherKit" "$WEATHER"

try() { # $1 = 标签, $2 = sed 表达式（改 Package.swift 里那一行）
    printf '=== %s\n' "$1"
    if [ -n "$2" ]; then sed -i '' "$2" "$WEATHER/Package.swift"; fi
    sed -n 's/^ *//;/\.product(p/!s/^\( *\)\("ClimateCore"\|.product(name: "ClimateCore".*\)$/    \1\2/p' \
        "$WEATHER/Package.swift" | head -3
    env -u SDKROOT "$SWIFT" build --package-path "$WEATHER" --scratch-path "$TMP/s6.spm" \
        --triple "$TARGET" --sdk "$SDK" > "$TMP/s6.log" 2>&1
    echo "swift build 退出码 = $?"
    grep -E 'error:|warning:|Build complete' "$TMP/s6.log" | sed 's/^/    /'
    echo
}

try 'a) package 填一个凭记忆写的名字 "Climate"' \
    's|"ClimateCore",|.product(name: "ClimateCore", package: "Climate"),|'
# 上一行改完的样子留作下一轮的基准：把 package 换成 Package 里的 name（= 目录名）
try 'b) package 填 "ClimateCore"（Package.swift 里的 name，也是目录名）' \
    's|package: "Climate"|package: "ClimateCore"|'
try 'c) product 名写错（ClimateCore 没有叫 Core 的 product）' \
    's|name: "ClimateCore", package|name: "Core", package|'
try 'd) 退回主线那种写法：只给一个字符串 "ClimateCore"' \
    's|.product(name: "Core", package: "ClimateCore"),|"ClimateCore",|'
