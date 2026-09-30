#!/bin/bash
# s13：Bundle.module 的两个候选路径 —— 一个只有本机才会命中的「假绿」。
#
# SwiftPM 为有资源的 target 生成的那个文件一共十几行，找 bundle 只试**两个**位置：
#   1. 二进制所在目录里的 <Product>_<Target>.bundle（这就是随包交付时该有的形状）
#   2. **编译时写死在二进制里的绝对路径**，指向构建机器上的中间目录
# 第二个候选是本教程这类「主机建产物、模拟器跑」流程里最容易漏的一环：
# bundle 没拷过去也照样跑出正确输出，因为绝对路径在这台机器上真的存在。
# 于是同一个二进制在这台机器上绿、换台机器（或删掉构建目录）当场崩。
#
# 三次运行分别是：bundle 在二进制旁边 / 旁边没有但构建目录还在 / 连构建目录里那份也移走。
# 主线 §18/§22 用第一次的形态（run-all.sh 会把 bundle 拷过去），这里把后两种补齐。
#
# 这一支还顺手量到一条只有命令行会撞上的事：驱动里**写不了** `Bundle.module`
# （它是包内的 internal，见探针 c02），所以判断「命中哪个候选」只能靠包自己 public
# 出来的 moduleBundlePath() 把那个 Bundle 的路径原样报回来 —— 前两个候选的目录名
# 是一样的，能分辨的只有它们的父路径：一个在二进制旁边，一个在 <TMP>/s13.spm 里。
set -u

D="$SPMDBG"
WEATHER="$TMP/WeatherKit"
cp -R "$PKG_ROOT/ClimateCore" "$TMP/ClimateCore"
cp -R "$PKG_ROOT/WeatherKit" "$WEATHER"
env -u SDKROOT "$SWIFT" build --package-path "$WEATHER" --scratch-path "$TMP/s13.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/s13.build.log" 2>&1
D="$TMP/s13.spm/x86_64-apple-ios-simulator/debug"
if [ ! -d "$D" ]; then echo '（构建失败）'; cat "$TMP/s13.build.log"; exit 1; fi

echo '=== 生成的那个文件全文（十几行，两个候选路径都在里面）'
ACC="$(find "$D" -name 'resource_bundle_accessor.swift' | head -1)"
sed -e "s|$TMP|<TMP>|g" "$ACC" | sed 's/^/    /'

cat > "$TMP/main.swift" <<'EOF'
import Foundation
import WeatherKit

// 注意这里**不能**直接写 Bundle.module：它是包内的 internal（探针 c02 抄了那条原文），
// 模块外只能隔着包自己 public 出来的 moduleBundlePath() 看它解析到了哪一层。
print("Bundle.module -> \(moduleBundlePath())")
print("Bundle.main   = \(Bundle.main.bundlePath)")
let layout = bundleLayout()
print("entries=\(layout.entries.joined(separator: ",")) cityJSON=\(layout.cityJSON)")
EOF

run_in() { # $1 = 放二进制的目录, $2 = 标签
    local dir="$1" tag="$2"
    mkdir -p "$dir"
    env -u SDKROOT "$(xcode-select -p)/Toolchains/XcodeDefault.xctoolchain/usr/bin/swiftc" \
        -Onone -sdk "$SDK" -target "$TARGET" -module-name s13 \
        -I "$D/Modules" \
        -Xcc -fmodule-map-file="$D/CLIBrain.build/module.modulemap" \
        "$D"/*.build/*.o "$TMP/main.swift" -o "$dir/probe" -framework Foundation \
        > "$TMP/s13.compile.log" 2>&1
    if [ $? -ne 0 ]; then printf '=== %s：编译失败\n' "$tag"; sed 's/^/    /' "$TMP/s13.compile.log"; return; fi
    printf '=== %s\n' "$tag"
    xcrun simctl spawn "$SIM_UDID" "$dir/probe" > "$dir/out" 2> "$dir/err"
    printf '    退出码 = %s\n' "$?"
    [ -s "$dir/out" ] && sed -e "s|$TMP|<TMP>|g" -e 's/^/    stdout: /' "$dir/out"
    [ -s "$dir/err" ] && sed -e "s|$TMP|<TMP>|g" -e 's/^/    stderr: /' "$dir/err" | head -4
    echo
}

# 1) bundle 就在二进制旁边（主线那种摆法：run-all.sh 把它拷过去）
mkdir -p "$TMP/withbundle"
cp -R "$D/WeatherKit_WeatherKit.bundle" "$TMP/withbundle/"
run_in "$TMP/withbundle" '旁边有 bundle —— 第一个候选命中'

# 2) 旁边没有，但构建目录里那份还在
mkdir -p "$TMP/nobundle"
run_in "$TMP/nobundle" '旁边**没有** bundle、构建目录还在 —— 第二个候选命中，这就是假绿'

# 3) 把构建目录里那份也移走：第二个候选落空
B="$D/WeatherKit_WeatherKit.bundle"
mv "$B" "$B.off"
run_in "$TMP/nobundle" '再把构建目录里那份移走（等于换一台机器）'
run_in "$TMP/withbundle" '同样移走之后，旁边有 bundle 的那份还能跑'
mv "$B.off" "$B"
