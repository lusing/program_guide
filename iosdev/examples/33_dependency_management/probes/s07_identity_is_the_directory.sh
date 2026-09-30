#!/bin/bash
# s07：包的身份（identity）取的是**目录名**，不是 Package(name:)。
#
# 这一格是 CocoaPods 换成 SwiftPM 之后最容易踩的空档：Podfile 里 `pod 'X'` 的 X 和
# .podspec 的 name 是同一个字符串，而 SwiftPM 里「目录名 / Package(name:) / product 名 /
# module（target）名」是**四个各管各的**字符串，`.product(package:)` 只认第一个的
# 小写形式（= identity）。下面这份 fixture 故意让后两个仍相同（它俩都由 target 名推导）、
# 前两个都不同，于是「填哪个才过」这件事只剩一个解释。
#
# 四个读数：填错那个 name 时的 error（顺带把合法值打出来）、填对 identity 之后通过、
# describe / show-dependencies 里这几个字符串各自是什么、以及这一趟之后**没有**锁文件。
set -u

cp -R "$PKG_ROOT/ClimateCore" "$TMP/Climate-Kernel"
# 只改 Package 自己的 name，product 名与 target 名都留着（这正是「四个名字」的形状）
cat > "$TMP/Climate-Kernel/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "TotallyDifferentName",
    products: [
        .library(name: "ClimateCore", targets: ["ClimateCore"])
    ],
    targets: [
        .target(name: "ClimateCore")
    ]
)
EOF
printf '目录名 = Climate-Kernel\nPackage 里的 name = TotallyDifferentName\nproduct 名 = ClimateCore\ntarget（module）名 = ClimateCore\n' \
    | sed 's/^/    /'

mkdir -p "$TMP/client/Sources/Client"
printf 'import ClimateCore\n\npublic let pulled = climateCoreID\n' > "$TMP/client/Sources/Client/Client.swift"
cat > "$TMP/client/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Client",
    dependencies: [.package(path: "../Climate-Kernel")],
    targets: [
        .target(name: "Client", dependencies: [.product(name: "ClimateCore", package: "PKGB")])
    ]
)
EOF

echo
echo '--- .product(package:) 先填 Package 里那个 name'
sed -i '' 's|package: "PKGB"|package: "TotallyDifferentName"|' "$TMP/client/Package.swift"
env -u SDKROOT "$SWIFT" build --package-path "$TMP/client" --scratch-path "$TMP/c1.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/c1.log" 2>&1
echo "swift build 退出码 = $?"
grep -vE '^\[|Building' "$TMP/c1.log" | sed 's/^/    /'

echo
echo '--- 同一个位置改成目录名的小写形式（identity），源码一个字没改'
sed -i '' 's|package: "TotallyDifferentName"|package: "climate-kernel"|' "$TMP/client/Package.swift"
env -u SDKROOT "$SWIFT" build --package-path "$TMP/client" --scratch-path "$TMP/c2.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/c2.log" 2>&1
echo "swift build 退出码 = $?"
tail -1 "$TMP/c2.log"

echo
echo '--- describe 里被依赖方的三个字符串'
env -u SDKROOT "$SWIFT" package --package-path "$TMP/client" describe 2>&1 \
    | sed -n '/^Dependencies:/,/^Platforms:/p' | sed 's/^/    /'

echo
echo '--- show-dependencies --format json 里的 identity / name / url'
env -u SDKROOT "$SWIFT" package --package-path "$TMP/client" show-dependencies --format json 2>&1 \
    | grep -E '"(identity|name|url|version)"' | sed 's/^ *//' | sed 's/^/    /'

# path 依赖「没有版本」这件事有两个落点：根目录里**没有** Package.resolved，
# 而中间目录根上的 workspace-state.json 把这一格记成 fileSystem（s08 那份本地 git 记的是
# localSourceControl + revision + version）。这一节是主线 §20 那句断言的凭据。
echo
echo '--- 这一趟成功之后：锁文件在不在，workspace-state.json 把这一格记成什么'
for f in "$TMP/client/Package.resolved" "$TMP/c2.spm/workspace-state.json"; do
    if [ -f "$f" ]; then
        printf '    有文件：%s\n' "${f#$TMP/}"
        [ "${f##*.}" = "json" ] || continue
        grep -E '"kind"|"identity"|"path"|"version"|"revision"' "$f" | sed 's/^ *//' | sed 's/^/        /'
    else
        printf '    没有这个文件：%s\n' "${f#$TMP/}"
    fi
done

