#!/bin/bash
# s02：Package.swift 自己也是一段要编译执行的 Swift —— 而它只能为**主机**编。
#
# manifest（就是那份 Package.swift）的处理流程是：swiftc 把它编成一个能跑的 macOS
# 程序，链接工具链里的 PackageDescription 库，然后**执行**它，执行结果才是依赖图。
# 所以「给设备编包」这件事里其实有两次编译，两种目标：
#   manifest   → x86_64-apple-macosx13.0（主机，永远）
#   target     → 你指定的 --triple
# 本仓库为了压掉 sysroot 告警把 SDKROOT 指到模拟器 SDK（run-all.sh 文件头），
# 这一支就把那个环境变量留着，看它怎么把第一次编译打死；再把 --sdk 单独留着看第二次。
#
# 三个读数：manifest 的完整 swiftc 命令行（里面就有 -target 与 -sdk）、
# 失败原文、以及 `env -u SDKROOT` 之后的成功。
set -u

BUILD_ARGS=(--package-path "$PKG_ROOT/WeatherKit" --triple "$TARGET" --sdk "$SDK" -c debug)

echo '$ SDKROOT=<模拟器 SDK> swift build --triple '"$TARGET"' --sdk <模拟器 SDK>'
echo '  （这就是 run-all.sh 里 export SDKROOT 之后的现场）'
SDKROOT="$SDK" "$SWIFT" build "${BUILD_ARGS[@]}" --scratch-path "$TMP/leak" \
    > "$TMP/leak.log" 2>&1
echo "swift build 退出码 = $?"
# manifest 的命令行整段抄下来：它是「这段 Swift 是给主机编的」的唯一书面证据
grep -m1 'Invalid manifest' "$TMP/leak.log" | sed -e 's/.*compiled with: //' | tr -d '[]"' \
    | tr ',' '\n' | sed -e 's/^ *//' | grep -E 'target|sdk|LPackageDescription|package-description' | sed 's/^/    /'
grep -E 'warning:|error:' "$TMP/leak.log" | sed 's/^/    /'

echo
echo '$ env -u SDKROOT swift build --triple '"$TARGET"' --sdk <模拟器 SDK>'
env -u SDKROOT "$SWIFT" build "${BUILD_ARGS[@]}" --scratch-path "$TMP/noleak" \
    > "$TMP/noleak.log" 2>&1
echo "swift build 退出码 = $?"
tail -2 "$TMP/noleak.log"
echo
echo '--- 只给 --triple、不给 --sdk（第二次编译没人告诉它设备 SDK 在哪）'
env -u SDKROOT "$SWIFT" build --package-path "$PKG_ROOT/WeatherKit" \
    --triple "$TARGET" -c debug --scratch-path "$TMP/nosdk" > "$TMP/nosdk.log" 2>&1
echo "swift build 退出码 = $?"
grep -E 'warning:|error:|Build complete' "$TMP/nosdk.log" | sed 's/^/    /'
