#!/bin/bash
# s09：依赖图里那个包在不在，和你的 target 能不能 import 它 —— 本机的答案不是同一件事。
#
# 书 10.3 那份 Podfile 只有一层（`pod 'Alamofire'`），装完就全都可用；SwiftPM 写成两层：
#   外层 .package(path:) / .package(url:)  —— 这个包进不进依赖图
#   内层 target 的 dependencies            —— 这个 target「应该」能看到谁的模块
# 直觉上少写内层应当当场编译失败。**本机不是**：一趟 `swift build` 里所有 target 的
# .swiftmodule 都落在同一个 <triple>/<cfg>/Modules 目录，而 -I 指的是那个目录本身
# （第一格在打印它的清单：Client/ClimateCore/WeatherKit 三个 .swiftmodule 肩并肩躺着）。
# 于是第一格给出的是「内层没写、import 照用、swift build 退出码 0」。
#
# 这一支因此把问题往下推两格：
#   4) 编译器放行之后，**链接器**放行吗？—— 把 Client 换成 executableTarget，链接真的发生。
#      实测：放行，而且放进模拟器照常打印（tagLine() 与 climateCoreID 都取到了值）。
#      内层在本机连链接都不管，因为链接吃的是**整个依赖闭包**的 .o。
#   5) SwiftPM 有没有留强制检查的开关？—— `--explicit-target-dependency-import-check`，
#      有。默认模块构建下它抓不到这一格（第六格·a，退出码照样 0）；它要求的
#      `--experimental-explicit-module-build` 又要求 `--use-integrated-swift-driver`，
#      三档一起打开以后本机这条路不是「抓到漏写」而是连**写全了的那一层**都报
#      `Unable to find module dependency: 'ClimateCore'`（第六格·b）；
#      而把 manifest 换成漏写内层的另一份，报错一个字都不差（第六格·c）——
#      也就是说这一档在 path 依赖上根本没能区分两种 manifest。
#      ⇒ 这一族的结论：内层是构建系统的**意图声明**，在 Xcode 之外它不被强制。
#
# 反向那一格（内层写了、外层没写）倒是硬失败 —— 它失败在 manifest 校验阶段，
# 连编译都没开始，原文见第一格之后那一节；顺带留意 SwiftPM 给的建议
# 「Did you mean 'ClimateCore'?」—— 它让你写的那个名字正是它说找不到的那个。
#
# 与主线 §8 的分工别看混了：这一支量的是**构建系统**认不认你的声明，
# e05 量的是**语言**认不认 —— 后者永远硬：`import WeatherKit` 不会把 ClimateCore 的名字带进来。
set -u

mkdir -p "$TMP/client/Sources/Client"
cp -R "$PKG_ROOT/ClimateCore" "$TMP/ClimateCore"
cp -R "$PKG_ROOT/WeatherKit" "$TMP/WeatherKit"
printf 'import WeatherKit\nimport ClimateCore\n\npublic let pair = (tagLine(), climateCoreID)\n' \
    > "$TMP/client/Sources/Client/Client.swift"

build() { # $1 = 标签
    printf '=== %s\n' "$1"
    sed -n '/targets:/,/])/p' "$TMP/client/Package.swift" | sed 's/^ */    /'
    env -u SDKROOT "$SWIFT" build --package-path "$TMP/client" --scratch-path "$TMP/s9.spm" \
        --triple "$TARGET" --sdk "$SDK" > "$TMP/s9.log" 2>&1
    echo "swift build 退出码 = $?"
    grep -E 'error:|warning:|Build complete' "$TMP/s9.log" | sed 's/^/    /'
    echo
}

# ------------------------------------------------- 1) 库形态：内层没写，编译器不管
cat > "$TMP/client/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Client",
    dependencies: [.package(path: "../WeatherKit")],
    targets: [
        .target(name: "Client", dependencies: ["WeatherKit"])
    ]
)
EOF
build '外层只有 WeatherKit（ClimateCore 是它的传递依赖），内层没写 —— 源码里却 import ClimateCore'

echo '    --- 为什么它能过：这一趟的 Modules 目录里躺着谁的接口'
for m in "$TMP"/s9.spm/x86_64-apple-ios-simulator/debug/Modules/*.swiftmodule; do
    [ -f "$m" ] || continue
    printf '        %s\n' "$(basename "$m")"
done
printf '        —— -I 给的是这个目录本身，不是「你的 target 声明过的那些模块」\n\n'

# ------------------------------------------------- 2) 补上内层：同样的结果
cat > "$TMP/client/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Client",
    dependencies: [.package(path: "../WeatherKit"), .package(path: "../ClimateCore")],
    targets: [
        .target(name: "Client", dependencies: ["WeatherKit", "ClimateCore"])
    ]
)
EOF
build '两个包都出现在外层，内层里也各点名一次'

# ------------------------------------------------- 3) 反向：外层没写，manifest 就拦住
echo '--- 只补内层、不补外层（target 里点名，但 .package 那层没有）'
cat > "$TMP/client/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Client",
    dependencies: [.package(path: "../WeatherKit")],
    targets: [
        .target(name: "Client", dependencies: ["WeatherKit", "ClimateCore"])
    ]
)
EOF
build '内层写了 ClimateCore，外层没有'

# ------------------------------------------------- 4) 可执行形态：链接这一步呢
# Client.swift 换成带顶层语句的 main.swift：这次 swift build 会真的连一个可执行文件。
cat > "$TMP/client/Sources/Client/main.swift" <<'EOF'
import WeatherKit
import ClimateCore

let pair = (tagLine(), climateCoreID)
print("pair = \(pair)")
print("climateCoreID = \(climateCoreID)")
EOF
rm "$TMP/client/Sources/Client/Client.swift"

link_case() { # $1 = 标签, $2 = 内层写不写
    printf '=== %s\n' "$1"
    if [ "$2" = "with" ]; then
        cat > "$TMP/client/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Client",
    dependencies: [.package(path: "../WeatherKit"), .package(path: "../ClimateCore")],
    targets: [
        .executableTarget(name: "Client", dependencies: ["WeatherKit", "ClimateCore"])
    ]
)
EOF
    else
        cat > "$TMP/client/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Client",
    dependencies: [.package(path: "../WeatherKit")],
    targets: [
        .executableTarget(name: "Client", dependencies: ["WeatherKit"])
    ]
)
EOF
    fi
    sed -n '/targets:/,/])/p' "$TMP/client/Package.swift" | sed 's/^ */    /'
    rm -rf "$TMP/s9e.spm"
    env -u SDKROOT "$SWIFT" build --package-path "$TMP/client" --scratch-path "$TMP/s9e.spm" \
        --triple "$TARGET" --sdk "$SDK" > "$TMP/s9e.log" 2>&1
    echo "swift build 退出码 = $?"
    grep -E 'error:|Build complete|undefined|Undefined' "$TMP/s9e.log" | sed 's/^/    /' | head -12
    local bin="$TMP/s9e.spm/x86_64-apple-ios-simulator/debug/Client"
    if [ -x "$bin" ]; then
        xcrun simctl spawn "$SIM_UDID" "$bin" > "$TMP/s9e.out" 2> "$TMP/s9e.err"
        printf '    模拟器里跑：退出码 = %s\n' "$?"
        [ -s "$TMP/s9e.out" ] && sed 's/^/    stdout: /' "$TMP/s9e.out"
        [ -s "$TMP/s9e.err" ] && sed 's/^/    stderr: /' "$TMP/s9e.err" | head -6
    else
        printf '    没有可执行文件产出\n'
    fi
    echo
}

link_case '可执行形态·内层没写（只有 "WeatherKit"）：编译放行之后，链接放行吗' without
link_case '可执行形态·内层补齐（"WeatherKit", "ClimateCore"）' with

# ------------------------------------------------- 6) 那个「强制检查」的开关在哪、值不值
# SwiftPM 6.0.3 确实留了一个开关：
#   $ swift build --help | grep explicit
#   --explicit-target-dependency-import-check <…>
#   --experimental-explicit-module-build
# 这一格量两件事，所以**每档各写一次 manifest**（不继承上面那格的：上一格的最后一份是
# 「写全了」那份，直接沿用就测不到「漏写」了）：
#   6a 漏写内层 + 只开这个开关（默认模块构建）—— 抓不抓得到？
#   6b 写全两层   + 三档齐开（--experimental-explicit-module-build 要求 --use-integrated-swift-driver）
#   6c 漏写两层里的那一层 + 三档齐开 —— 报错和 6b 一模一样
# 6b 与 6c 各要把整个 SDK 的模块图重编一遍（本机各约 20 秒），这是本章最慢的一支探针。
printf '\n--- swift build --help 里这两个开关的原文\n'
env -u SDKROOT "$SWIFT" build --help 2>&1 | grep -E 'explicit' | sed 's/^/    /'
echo

manifest() { # $1 = with | without（内层写不写）, $2 = 标签
    if [ "$1" = "with" ]; then
        cat > "$TMP/client/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Client",
    dependencies: [.package(path: "../WeatherKit"), .package(path: "../ClimateCore")],
    targets: [
        .executableTarget(name: "Client", dependencies: ["WeatherKit", "ClimateCore"])
    ]
)
EOF
    else
        cat > "$TMP/client/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Client",
    dependencies: [.package(path: "../WeatherKit")],
    targets: [
        .executableTarget(name: "Client", dependencies: ["WeatherKit"])
    ]
)
EOF
    fi
    printf '=== %s\n' "$2"
    sed -n '/targets:/,/])/p' "$TMP/client/Package.swift" | sed 's/^/    /'
}

check_case() { # $1 = with|without, $2 = 标签, $3… = 额外开关
    local m="$1" tag="$2"; shift 2
    manifest "$m" "$tag"
    rm -rf "$TMP/chk.spm"
    env -u SDKROOT "$SWIFT" build --package-path "$TMP/client" --scratch-path "$TMP/chk.spm" \
        --triple "$TARGET" --sdk "$SDK" "$@" > "$TMP/chk.log" 2>&1
    echo "swift build 退出码 = $?"
    grep -E '^error|error:|Build complete|real' "$TMP/chk.log" | sed 's/^/    /' | head -10
    printf '    ——「Compiling Swift module XPC / CoreFoundation / …」那类行是它在重编 SDK 模块，\n'
    printf '      本仓库的判定不吃 stdout，这里只挑 error / Build complete / 计时三类\n\n'
}

check_case without '第六格·a：漏写内层，只开 --explicit-target-dependency-import-check error（默认模块构建）' \
    --explicit-target-dependency-import-check error
check_case with '第六格·b：这一份 manifest 两层都写全了（对照用），三档齐开' \
    --use-integrated-swift-driver --experimental-explicit-module-build \
    --explicit-target-dependency-import-check error
# 同一份「漏写」的 manifest 再走一遍三档：它报的是同一个错，说明这一格的失败
# 与内层写没写无关 —— 是 path 依赖 + 显式模块构建在这套工具链上没接通。
check_case without '第六格·c：把上面那份「写全了」换成「漏写」，三档齐开，报错一个字没变' \
    --use-integrated-swift-driver --experimental-explicit-module-build \
    --explicit-target-dependency-import-check error



