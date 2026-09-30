#!/bin/bash
# s04：没声明资源的 target 里用 `Bundle.module` —— 那个成员是**生成**出来的。
#
# `Bundle.module` 不是 SDK 里的 API，它是 SwiftPM 看见 resources: 之后往 target 里
# **塞一个源文件**塞出来的（那个文件在构建目录里，见 s13）。所以少写 resources 的
# 报错不是「找不到资源」，而是「Bundle 这个类型没有 member 'module'」——
# 一句话就把「谁生成了什么」这件事暴露了。
#
# 顺带量另一半：resources 声明了、但没人用它，bundle 照样生成（主线 §16~§18 那一族用得到）。
set -u

mk_pkg() { # $1 = 目录名, $2 = 要不要 resources 那一行
    local p="$TMP/$1"
    mkdir -p "$p/Sources/Lib/Resources"
    printf 'import Foundation\npublic let v = 1\n' > "$p/Sources/Lib/Lib.swift"
    echo 'x' > "$p/Sources/Lib/Resources/city.json"
    cat > "$p/Package.swift" <<EOF
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "NoResDemo",
    targets: [
        .target(name: "Lib"${2})
    ]
)
EOF
    printf '%s' "$p"
}

echo '=== 不写 resources，源码里用 Bundle.module'
A="$(mk_pkg withmodule '')"
printf 'import Foundation\npublic func where_() -> String { Bundle.module.bundlePath }\n' >> "$A/Sources/Lib/Lib.swift"
env -u SDKROOT "$SWIFT" build --package-path "$A" --scratch-path "$TMP/a.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/a.log" 2>&1
echo "swift build 退出码 = $?"
grep -vE '^\[' "$TMP/a.log" | sed 's/^/    /'

echo
echo '=== 同一份源码，只在 Package.swift 里补一行 resources（源码一个字没改）'
B="$(mk_pkg withresources ', resources: [.copy("Resources/city.json")]')"
printf 'import Foundation\npublic func where_() -> String { Bundle.module.bundlePath }\n' >> "$B/Sources/Lib/Lib.swift"
env -u SDKROOT "$SWIFT" build --package-path "$B" --scratch-path "$TMP/b.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/b.log" 2>&1
echo "swift build 退出码 = $?"
tail -1 "$TMP/b.log"
echo '--- 这一次多出来的那个源文件：'
find "$TMP/b.spm" -name 'resource_bundle_accessor.swift' | sed 's/^/    /'
