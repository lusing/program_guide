#!/bin/bash
# s01：`swift build` 默认给**谁**编 —— 本章所有「本机适配」的起点。
#
# SwiftPM 不认识 Xcode 的 scheme，它只认 destination：不给 --triple/--sdk 时，
# 它按**当前这台机器的 macOS** 编。书 10.3 那套 CocoaPods 是「装进这个 iOS 工程」，
# 目标平台由工程替它决定；换成命令行，这一半要自己说。
#
# 三个读数：
#   1. 中间目录名 —— 主机一趟与设备一趟落在**不同**的目录里（这就是缓存不串台的原因）；
#   2. 同一个源文件、同一个架构（这台机器是 x86_64），两份二进制的 Mach-O 平台字段不同；
#   3. 把主机那份丢进模拟器跑，看它答不答应。
#
# fixture 全写在 $TMP 里，不碰仓库。
set -u

FIX="$TMP/fix"
mkdir -p "$FIX/Sources/HostDemo"
cat > "$FIX/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "HostDemo",
    targets: [
        .executableTarget(name: "HostDemo")
    ]
)
EOF
cat > "$FIX/Sources/HostDemo/main.swift" <<'EOF'
import Foundation
print("HostDemo 跑起来了：\(ProcessInfo.processInfo.operatingSystemVersion)")
EOF

echo '$ ls <scratch>/            # 先看默认（不给 --triple/--sdk）落在哪个目录名里'
env -u SDKROOT "$SWIFT" build --package-path "$FIX" --scratch-path "$TMP/host" -c debug \
    > "$TMP/host.log" 2>&1
echo "swift build 退出码 = $?"
tail -2 "$TMP/host.log"
find "$TMP/host" -maxdepth 1 -type d | sed "s|$TMP/host/||" | grep -v "^$TMP/host$" | sort

HOST_BIN="$TMP/host/HostDemo/debug/HostDemo"
if [ ! -x "$HOST_BIN" ]; then
    # 主机与设备共用一个 scratch 根目录，中间层是 dest triple，找一遍更省事
    HOST_BIN="$(find "$TMP/host" -type f -name HostDemo -perm +111 | head -1)"
fi
echo
echo "--- 主机产物"
printf '%s\n' "$HOST_BIN"
file "$HOST_BIN"
otool -l "$HOST_BIN" | sed -n '/LC_BUILD_VERSION/,/ntools/p' | head -6

echo
echo '$ swift build --package-path fix --triple '"$TARGET"' --sdk <iphonesimulator> -c debug'
env -u SDKROOT "$SWIFT" build --package-path "$FIX" --scratch-path "$TMP/sim" -c debug \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/sim.log" 2>&1
echo "swift build 退出码 = $?"
tail -2 "$TMP/sim.log"
find "$TMP/sim" -maxdepth 1 -type d | sed "s|$TMP/sim/||" | grep -v "^$TMP/sim$" | sort

SIM_BIN="$(find "$TMP/sim" -type f -name HostDemo -perm +111 | head -1)"
echo
echo "--- 设备（模拟器）产物"
printf '%s\n' "$SIM_BIN"
file "$SIM_BIN"
otool -l "$SIM_BIN" | awk '/LC_BUILD_VERSION/{f=1} f{print} /sdk$/{if(f)exit}' | head -6

echo
echo '$ swift build --triple x86_64-apple-ios15.0-simulator --sdk <sim> -c debug -v   # 只留 -target 那一段'
env -u SDKROOT "$SWIFT" build --package-path "$FIX" --scratch-path "$TMP/verbose" -c debug \
    --triple "$TARGET" --sdk "$SDK" -v > "$TMP/verbose.log" 2>&1
echo "swift build 退出码 = $?"
grep -oE '\-target [a-z0-9_.-]+' "$TMP/verbose.log" | sort | uniq -c

echo
echo '$ xcrun simctl spawn <sim> <主机那份二进制>'
xcrun simctl spawn "$SIM_UDID" "$HOST_BIN" > "$TMP/host.run.out" 2> "$TMP/host.run.err"
echo "退出码 = $?"
show() { if [ -s "$1" ]; then printf -- '--- %s ---\n%s\n' "$2" "$(cat "$1")"; else printf -- '--- %s ---（空）\n' "$2"; fi; }
show "$TMP/host.run.out" stdout
show "$TMP/host.run.err" stderr

echo
echo '$ xcrun simctl spawn <sim> <设备那份二进制>'
xcrun simctl spawn "$SIM_UDID" "$SIM_BIN" > "$TMP/sim.run.out" 2> "$TMP/sim.run.err"
echo "退出码 = $?"
show "$TMP/sim.run.out" stdout
show "$TMP/sim.run.err" stderr
