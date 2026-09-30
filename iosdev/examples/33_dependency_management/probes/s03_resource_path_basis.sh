#!/bin/bash
# s03：Package.swift 里那行资源路径，基准是 **target 目录**，不是包根目录。
#
# 书 10.3 之后那一整节讲的是「库怎么用」，而资源这一类依赖是 CocoaPods 里最容易
# 配错的一半（.xcassets、plist、nib 都要在 resource_bundles 里点名）。SwiftPM 换了
# 规矩：resources 里写的相对路径，是**从 Sources/<target>/ 开始数**的。
# 这一支把同一个文件分别放在两个基准上，各编一次 —— 错的那次的原文就是本节要抄的。
#
# 另外两种写法也一起量：`.copy`（原样进 bundle，保留目录层级）与
# `.process`（交给规则处理器；目录会被**摊平**，这是主线 §16 那条 entries 清单的来源）。
#
# 第四格量「末级名撞车」：两种写法往 bundle 里放的都只是**文件名**，路径写得再开也
# 不一样，末级名一样就是 manifest 校验期的硬错误（一个 .o 都不产生）。同一条消息里会
# 出现两个名字：报错点名的是包**身份**（这一格里等于目录名 dup），而 bundle 前缀取的是
# manifest 里的 name:（DupNames_Lib.bundle）——身份与 name 的分工见 s06/s07。
set -u

mk() { # $1 = 包目录, $2 = 资源放哪（root|target）, $3 = 声明
    local p="$TMP/$1" decl="$3"
    mkdir -p "$p/Sources/Lib"
    printf 'import Foundation\npublic let v = 1\n' > "$p/Sources/Lib/Lib.swift"
    printf '%s\n' "$decl" > "$p/Package.swift"
    # 两种基准：包根的 Resources/，与 target 目录里的 Resources/
    if [ "$2" = "root" ]; then mkdir -p "$p/Resources"; echo '{"city":"Beijing","offset":8}' > "$p/Resources/city.json"
    else mkdir -p "$p/Sources/Lib/Resources"; echo '{"city":"Beijing","offset":8}' > "$p/Sources/Lib/Resources/city.json"; fi
    printf '%s\n' "$p"
}

cat > "$TMP/decl.txt" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "ResPaths",
    targets: [
        .target(name: "Lib", resources: [.copy("Resources/city.json")])
    ]
)
EOF
DECL="$(cat "$TMP/decl.txt")"

echo '=== 基准放错：文件在**包根**的 Resources/，声明写的却是 .copy("Resources/city.json")'
A="$(mk wrong root "$DECL")"
env -u SDKROOT "$SWIFT" build --package-path "$A" --scratch-path "$TMP/wrong.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/wrong.log" 2>&1
echo "swift build 退出码 = $?"
grep -vE '^\[' "$TMP/wrong.log" | sed 's/^/    /'

echo
echo '=== 基准放对：文件在 Sources/Lib/Resources/（同一行声明，一个字没改）'
B="$(mk right target "$DECL")"
env -u SDKROOT "$SWIFT" build --package-path "$B" --scratch-path "$TMP/right.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/right.log" 2>&1
echo "swift build 退出码 = $?"
tail -1 "$TMP/right.log"

echo
echo '=== .copy 与 .process 在 bundle 里落成的形状（本章 §16 那张清单的来源）'
cat > "$TMP/decl2.txt" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "TwoShapes",
    targets: [
        .target(name: "Lib", resources: [
            .copy("Resources/flat"),
            .process("Resources/handled"),
        ])
    ]
)
EOF
C="$TMP/shapes"; mkdir -p "$C/Sources/Lib/Resources/flat" "$C/Sources/Lib/Resources/handled/inner"
printf 'import Foundation\npublic let v = 1\n' > "$C/Sources/Lib/Lib.swift"
cp "$TMP/decl2.txt" "$C/Package.swift"
echo a > "$C/Sources/Lib/Resources/flat/a.txt"
echo b > "$C/Sources/Lib/Resources/handled/b.txt"
echo c > "$C/Sources/Lib/Resources/handled/inner/c.txt"
env -u SDKROOT "$SWIFT" build --package-path "$C" --scratch-path "$TMP/shapes.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/shapes.log" 2>&1
echo "swift build 退出码 = $?"
find "$TMP/shapes.spm" -name '*.bundle' -maxdepth 6 -type d | while read -r bd; do
    printf 'bundle: %s\n' "${bd##*/}"
    ( cd "$bd" && find . -mindepth 1 | sed -e 's|^\./||' -e 's|^|    |' | sort )
done
grep -iE 'warning' "$TMP/shapes.log" | sed 's/^/    /'

echo
echo '=== 同名资源：两条路径都不一样，落进 bundle 的**末级名字**撞了（主线 §16 那句「同名就报重复」的出处）'
# bundle 内部是**扁平**的一张「文件名 → 内容」表（.process 还会摊平目录），
# 所以校验的是末级名，不是写下来的那条路径。这一条在 manifest 校验阶段就红，
# 一个 .o 都不产生；报错时点名的包名是**小写的那个身份**（见 s06/s07），不是 name: 里写的原样。
cat > "$TMP/decl3.txt" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "DupNames",
    targets: [
        .target(name: "Lib", resources: [
            .copy("Resources/one/s.txt"),
            .process("Resources/two/s.txt"),
        ])
    ]
)
EOF
D="$TMP/dup"; mkdir -p "$D/Sources/Lib/Resources/one" "$D/Sources/Lib/Resources/two"
printf 'import Foundation\npublic let v = 1\n' > "$D/Sources/Lib/Lib.swift"
cp "$TMP/decl3.txt" "$D/Package.swift"
echo one > "$D/Sources/Lib/Resources/one/s.txt"
echo two > "$D/Sources/Lib/Resources/two/s.txt"
env -u SDKROOT "$SWIFT" build --package-path "$D" --scratch-path "$TMP/dup.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/dup.log" 2>&1
echo "swift build 退出码 = $?"
grep -vE '^\[' "$TMP/dup.log" | sed 's/^/    /'
printf '中间目录里有 .o 吗：%s\n' "$(find "$TMP/dup.spm" -name '*.o' 2>/dev/null | wc -l | tr -d ' ') 个"

echo
echo '=== 把末级名改掉（两条路径照旧，一个字都不动目录层级）'
cat > "$TMP/decl4.txt" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "DupNames",
    targets: [
        .target(name: "Lib", resources: [
            .copy("Resources/one/s.txt"),
            .process("Resources/two/t.txt"),
        ])
    ]
)
EOF
cp "$TMP/decl4.txt" "$D/Package.swift"
mv "$D/Sources/Lib/Resources/two/s.txt" "$D/Sources/Lib/Resources/two/t.txt"
env -u SDKROOT "$SWIFT" build --package-path "$D" --scratch-path "$TMP/dupfix.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/dupfix.log" 2>&1
echo "swift build 退出码 = $?"
tail -1 "$TMP/dupfix.log"
find "$TMP/dupfix.spm" -name '*.bundle' -maxdepth 6 -type d | while read -r bd; do
    printf 'bundle: %s\n' "${bd##*/}"
    ( cd "$bd" && find . -mindepth 1 | sed -e 's|^\./||' -e 's|^|    |' | sort )
done
