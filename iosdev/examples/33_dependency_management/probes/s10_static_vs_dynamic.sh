#!/bin/bash
# s10：product 的 static / dynamic —— 同一个 target 交出去有两种交法，落盘完全不同。
#
# `.library(name:targets:)` 不写 type 时是 automatic；写成 .static 发一个 .a，
# 写成 .dynamic 发一个动态库。这一格在书 10.2 那段「CocoaPods 要不要 use_frameworks!」
# 上有直接对应物，而它决定的是主线这类**裸可执行文件**怎么把包链进去：
# 静态库的 .o 被吸进二进制，动态库的留在外面、运行时才找得到。
#
# 三个读数：automatic 与 .static 落的东西一样吗、.dynamic 在 iOS 模拟器这个 triple 上
# 给不给编（这是 Apple 平台的规矩，不是 SwiftPM 的偏好）、以及那份动态库的 install name。
set -u

build_one() { # $1 = 标签, $2 = products 数组里那一行
    local p="$TMP/$1"
    mkdir -p "$p/Sources/Lib"
    printf 'import Foundation\npublic let who = "%s"\n' "$1" > "$p/Sources/Lib/Lib.swift"
    cat > "$p/Package.swift" <<EOF
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "ShapeDemo",
    products: [$2],
    targets: [.target(name: "Lib")]
)
EOF
    printf '=== %s —— products 里那一行：%s\n' "$1" "$2"
    env -u SDKROOT "$SWIFT" build --package-path "$p" --scratch-path "$TMP/$1.spm" \
        --triple "$TARGET" --sdk "$SDK" > "$TMP/$1.log" 2>&1
    echo "swift build 退出码 = $?"
    grep -E 'error:|warning:|Build complete' "$TMP/$1.log" | sed 's/^/    /'
    local n
    n="$(find "$TMP/$1.spm" \( -name '*.a' -o -name '*.dylib' \) | wc -l | tr -d ' ')"
    if [ "$n" = "0" ]; then
        printf '    落盘：没有 .a / .dylib —— 只有 %s\n' \
            "$(find "$TMP/$1.spm" -name '*.o' | sed -e "s|$TMP/$1.spm/||" -e 's|.*/||' | sort | tr '\n' ' ')"
    else
        find "$TMP/$1.spm" \( -name '*.a' -o -name '*.dylib' \) \
            | sed -e "s|$TMP/$1.spm/||" -e 's/^/    落盘：/'
    fi
    echo
}

build_one automatic '.library(name: "Lib", targets: ["Lib"])'
build_one static    '.library(name: "Lib", type: .static, targets: ["Lib"])'
build_one dynamic   '.library(name: "Lib", type: .dynamic, targets: ["Lib"])'

DY="$(find "$TMP/dynamic.spm" -name '*.dylib' | head -1)"
if [ -n "$DY" ]; then
    echo '--- 动态库那份的 install name：裸可执行文件运行时靠这一串找到它'
    otool -D "$DY" | sed 's/^/    /'
    otool -l "$DY" | sed -n '/LC_ID_DYLIB/,+3p' | sed 's/^/    /'
fi

echo
echo '--- 静态库里的成员清单（ar 一眼看完：主线 §21 数的那些 .o 就是从这里进二进制的）'
SA="$(find "$TMP/static.spm" -name '*.a' | head -1)"
[ -n "$SA" ] && ar -t "$SA" | sed 's/^/    /'
