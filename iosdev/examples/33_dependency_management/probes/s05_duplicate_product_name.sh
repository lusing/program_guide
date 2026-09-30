#!/bin/bash
# s05：同一个字符串在 SwiftPM 里撞两次车，一次硬失败、一次**一句话都没有**。
#
# CocoaPods 里两个 pod 撞名要在 Podfile 里点名（`pod 'X', :podspec => …`），因为名字
# 就是身份。SwiftPM 这里要分清两件容易混成一件事的撞法 —— 本支探针一次量完：
#   撞 **product 名**（`.product(name:package:)` 里那第一个名字，跨包查找的句柄）：
#     本机 SwiftPM 6.0 一声不响，退出码 0，日志里只有 “Build complete!”；
#   撞 **target 名**（= module 名，`import X` 的那个词）：
#     硬失败，而且失败在依赖图检查阶段 —— 连编译都没开始。
# 前者最危险的地方在于它躲得过本仓库的判定 1（编译日志为空）；后者给的那条 error
# 里还捎带了一个解法名字（`moduleAliases`），照抄在这里。
#
# 读数按这个次序排：
#   1) 撞 product 名那趟 `swift build` 的退出码与日志原文；
#   2) `describe`：这个包对外列出几个 product、那个叫 Shared 的指向谁的 target；
#   3) 构建目录里两份实现各落在哪一个 .o，`strings` 从目标文件里挑出各自的常量；
#   4) 运行期读数：Run 里那句 `import Shared` + `print(who)` 打出来的是谁的实现；
#   5) 撞 target 名那趟的 error 原文；
#   6) 顺手量 manifest 是一等 Swift 代码的另一格：`Package(...)` 的**参数顺序**也是编译期
#      规定好的（products 必须排在 dependencies 前面），写反了不是风格问题。
#      第一版本仓库的这份 fixture 就是这么写的，原文留在这里当凭据。
set -u

CORE="$TMP/core"; APPA="$TMP/app-products"; APPB="$TMP/app-targets"
mkdir -p "$CORE/Sources/Shared"
printf 'import Foundation\npublic let who = "from-core-target-Shared"\n' > "$CORE/Sources/Shared/Shared.swift"
cat > "$CORE/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Core",
    products: [.library(name: "Shared", targets: ["Shared"])],
    targets: [.target(name: "Shared")]
)
EOF

# ---------------------------------------------------------- fixture A：撞 product 名 --
# app 自己把 target App 包装成一个**也叫 Shared** 的 product；本地 target 名一个都不撞。
# 两份 `who` 都写成纯 ASCII：`strings` 只认 ASCII 连续段，中文常量会被它切开、挑不出来。
mkdir -p "$APPA/Sources/App" "$APPA/Sources/Run"
printf 'import Foundation\npublic let who = "from-app-target-App"\n' > "$APPA/Sources/App/App.swift"
printf 'import Foundation\nimport Shared\n\nprint("Run 里 import Shared 之后看到的 who = \\(who)")\n' \
    > "$APPA/Sources/Run/main.swift"
cat > "$APPA/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "App",
    products: [
        .library(name: "Shared", targets: ["App"]),
        .library(name: "AppOnly", targets: ["App"])
    ],
    dependencies: [.package(path: "../core")],
    targets: [
        .target(name: "App", dependencies: [.product(name: "Shared", package: "core")]),
        .executableTarget(name: "Run", dependencies: [.product(name: "Shared", package: "core")])
    ]
)
EOF
printf 'core/：product "Shared" <- target Shared（module 名也是 Shared）\napp/ ：product "Shared" <- target App（module 名 App）—— 撞的只有 product 名\n' \
    | sed 's/^/    /'

echo
echo '=== 读数 1：撞 product 名的那趟 swift build，SwiftPM 自己说了什么'
env -u SDKROOT "$SWIFT" build --package-path "$APPA" --scratch-path "$APPA.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/a.log" 2>&1
echo "swift build 退出码 = $?"
grep -vE '^\[|Building' "$TMP/a.log" | sed 's/^/    /'
echo '    （这一屏只剩 “Build complete!” —— 它连一句警告都没给）'

echo
echo '=== 读数 2：app 对外列出的 product，那个叫 Shared 的指向谁的 target'
env -u SDKROOT "$SWIFT" package --package-path "$APPA" describe 2>&1 \
    | sed -n '/^Products:/,/^Targets:/p' | sed 's/^/    /'

echo
echo '=== 读数 3：两份实现各自落在哪一个 .o（strings 从目标文件里挑常量）'
find "$APPA.spm" -name '*.o' | sed -e "s|$APPA.spm/||" -e 's|^[^/]*/debug/||' | sort | sed 's/^/    /'
for o in $(find "$APPA.spm" -name '*.swift.o' | sort); do
    printf '    strings %-34s -> ' "$(echo "$o" | sed -e "s|$APPA.spm/||" -e 's|^[^/]*/debug/||')"
    strings "$o" | grep -E 'from-(core|app)-' | tr '\n' ' '
    printf '\n'
done

echo
echo '=== 读数 4：跑一遍，Run 里那句 import Shared 拿到的是谁的实现'
BIN="$(find "$APPA.spm" -type f -name Run -not -path '*.dSYM/*' | head -1)"
printf '    二进制 = %s\n' "${BIN:-没找到}"
if [ -n "${BIN:-}" ]; then
    xcrun simctl spawn "$SIM_UDID" "$BIN" > "$TMP/a.run.out" 2> "$TMP/a.run.err"
    echo "    运行退出码 = $?"
    sed 's/^/    stdout: /' "$TMP/a.run.out"
    [ -s "$TMP/a.run.err" ] && sed 's/^/    stderr: /' "$TMP/a.run.err"
    true
fi

# ---------------------------------------------------------- fixture B：撞 target 名 --
# 只把 app 的本地 target 也改名成 Shared —— product 名一个字没动，撞的是 module 名。
mkdir -p "$APPB/Sources/Shared"
printf 'import Foundation\npublic let who = "app 自己的 Shared"\n' > "$APPB/Sources/Shared/Shared.swift"
cat > "$APPB/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "App",
    products: [
        .library(name: "Shared", targets: ["Shared"]),
        .library(name: "AppOnly", targets: ["Shared"])
    ],
    dependencies: [.package(path: "../core")],
    targets: [
        .target(name: "Shared", dependencies: [.product(name: "Shared", package: "core")])
    ]
)
EOF
echo
echo '=== 读数 5：app 的本地 target 也叫 Shared（module 名撞车），同一趟构建的下场'
env -u SDKROOT "$SWIFT" build --package-path "$APPB" --scratch-path "$APPB.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/b.log" 2>&1
echo "swift build 退出码 = $?"
grep -vE '^\[|Building' "$TMP/b.log" | sed 's/^/    /'

echo
echo '=== 读数 6：把这份 manifest 的 products 与 dependencies 换个位置（target 改名成 Lib，免得读数 5 那条先报）'
cat > "$APPB/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "App",
    dependencies: [.package(path: "../core")],
    products: [
        .library(name: "Shared", targets: ["Lib"]),
        .library(name: "AppOnly", targets: ["Lib"])
    ],
    targets: [
        .target(name: "Lib", dependencies: [.product(name: "Shared", package: "core")])
    ]
)
EOF
env -u SDKROOT "$SWIFT" build --package-path "$APPB" --scratch-path "${APPB}b.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/c.log" 2>&1
echo "swift build 退出码 = $?"
# manifest 的整条 swiftc 命令有一千多字符，这里只留诊断本身
grep -E '^/.*error:|^  *- error:|^error:' "$TMP/c.log" | sed 's/^/    /'
