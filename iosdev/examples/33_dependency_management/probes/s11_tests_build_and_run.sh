#!/bin/bash
# s11：包里那个 test target 什么时候真被编、在哪里跑 —— 主线拿不到它的原因。
#
# 本章的包放了一个真的 XCTest target（Tests/WeatherKitTests/ForecastTests.swift，
# 里面用 @testable 拿 internal 的 internalTag()）。三件事一起量：
#   1. `swift build`（默认）到底编不编它 —— 加 --build-tests 才发射，主线那两个 .o 里没有它；
#   2. `swift test` 在**主机**上跑：XCTest 是 macOS SDK 里的东西，跑得起；
#   3. `swift test` 换成模拟器的 triple：同一句命令在这里失败，原文就是第 33 章
#      为什么「包里的单元测试」和「本教程的模拟器二进制」是两条路。
#
# 顺带抄 swift build 打在 stdout 上的进度行 —— run-all.sh 把这类文本挡在判定之外，
# 理由（它们是进度、不是诊断）在这里最直观。
set -u

echo '=== 1) swift build（不给 --build-tests）：WeatherKitTests.build 里有 .o 吗'
env -u SDKROOT "$SWIFT" build --package-path "$PKG_ROOT/WeatherKit" --scratch-path "$TMP/t1.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/t1.log" 2>&1
echo "swift build 退出码 = $?"
printf '  这些是 stdout 上的进度行（不是诊断）：\n'
head -3 "$TMP/t1.log" | sed 's/^/    /'
find "$TMP/t1.spm" -name '*.o' -path '*Tests*' | sed "s|$TMP/t1.spm/||" | sed 's/^/    测试相关 .o: /'
[ -d "$TMP/t1.spm/x86_64-apple-ios-simulator/debug/WeatherKitTests.build" ] \
    && printf '    但目录确实存在：%s\n' "$(ls "$TMP/t1.spm/x86_64-apple-ios-simulator/debug/WeatherKitTests.build" | tr '\n' ' ')"

echo
echo '=== 2) 加 --build-tests 再问一次'
env -u SDKROOT "$SWIFT" build --package-path "$PKG_ROOT/WeatherKit" --scratch-path "$TMP/t2.spm" \
    --triple "$TARGET" --sdk "$SDK" --build-tests > "$TMP/t2.log" 2>&1
echo "swift build --build-tests 退出码 = $?"
grep -E 'error:|Build complete' "$TMP/t2.log" | sed 's/^/    /'
find "$TMP/t2.spm" -name '*.o' -path '*Tests*' | sed -e "s|$TMP/t2.spm/||" -e 's|.*/||' | sort | sed 's/^/    /'

echo
echo '=== 3) swift test（主机：不带 --triple/--sdk）'
env -u SDKROOT "$SWIFT" test --package-path "$PKG_ROOT/WeatherKit" \
    --scratch-path "$TMP/t3.spm" > "$TMP/t3.log" 2>&1
echo "swift test 退出码 = $?"
grep -E 'Test Suite|Executed|error:' "$TMP/t3.log" | head -6 | sed 's/^/    /'
find "$TMP/t3.spm" -maxdepth 1 -type d | sed -e "s|$TMP/t3.spm/||" -e 's/^/    中间目录: /'

echo
echo '=== 4) swift test 换成模拟器的 triple（本章的构建目标）'
env -u SDKROOT "$SWIFT" test --package-path "$PKG_ROOT/WeatherKit" --scratch-path "$TMP/t4.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/t4.log" 2>&1
echo "swift test 退出码 = $?"
grep -vE '^\[|Building' "$TMP/t4.log" | head -8 | sed 's/^/    /'
