#!/bin/bash
# s08：版本区间、锁定文件、checkouts —— 书 10.3 那份 Podfile.lock 在本机的对应物。
#
# 本机没有网络，所以「远程」用一个**本地 git 仓库**当 fixture（file:// 也算 source
# control，SwiftPM 走的还是那套 tag/semver 解析）。五步各抄一份原文：
#   1. 区间约束（from: "1.0.0"）第一次解析 → Package.resolved 长什么样、代码落在哪
#   2. 同一种「target 依赖写个字符串」的写法，在本地路径依赖那格能过（s07/主线），
#      换成带版本的 git 依赖却被要求写成 .product(name:package:) —— 报错顺手把
#      package 参数该填的那个 identity 也告诉你
#   3. 上游又打一个 tag 1.2.0 —— **不动 manifest** 再跑一次：解析结果变不变？
#      （这一问就是「为什么队友的构建和你不一样」）
#   4. `swift package update` —— 显式解开锁
#   5. 删掉锁文件后用 --disable-automatic-resolution 拦一次（CI 上的标准姿势）
#
# 这就是本章后半段的主线：包名解决「找得到」，版本约束与锁解决「每次是同一个」。
set -u

UP="$TMP/upstream"
ROOT="$TMP/root"

# ---- 造一个带 tag 的 git 仓库当上游
mkdir -p "$UP/Sources/Remote"
cat > "$UP/Package.swift" <<'EOF'
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Remote",
    products: [.library(name: "Remote", targets: ["Remote"])],
    targets: [.target(name: "Remote")]
)
EOF
printf 'public let remoteVersion = "1.0.0"\n' > "$UP/Sources/Remote/Remote.swift"
( cd "$UP" && git init -q && git add -A \
    && git -c user.email=t@t -c user.name=t commit -qm "v1.0.0" && git tag 1.0.0 )

mkdir -p "$ROOT/Sources/Root"
cat > "$ROOT/Package.swift" <<EOF
// swift-tools-version:5.9
import PackageDescription
let package = Package(
    name: "Root",
    dependencies: [.package(url: "file://$UP", from: "1.0.0")],
    targets: [.target(name: "Root", dependencies: ["Remote"])]
)
EOF
printf 'import Remote\npublic let v = remoteVersion\n' > "$ROOT/Sources/Root/Root.swift"

echo '=== 上游只有一个 tag 1.0.0；root 的 target 依赖照抄本地路径那一格的写法 ["Remote"]'
env -u SDKROOT "$SWIFT" build --package-path "$ROOT" --scratch-path "$TMP/r0.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/r0.log" 2>&1
echo "swift build 退出码 = $?"
grep -vE '^\[|Building' "$TMP/r0.log" | sed 's/^/    /'
echo '--- 但解析已经发生：Package.resolved 在依赖图检查之前就写好了'
cat "$ROOT/Package.resolved" 2>/dev/null | sed 's/^/    /' || echo '    （没有这个文件）'

echo
echo '=== 改成 .product(name:package:)，identity 用报错里提示的那个 upstream'
sed -i '' 's|dependencies: \["Remote"\]|dependencies: [.product(name: "Remote", package: "upstream")]|' \
    "$ROOT/Package.swift"
grep -n 'product(name' "$ROOT/Package.swift" | sed 's/^/    /'
env -u SDKROOT "$SWIFT" build --package-path "$ROOT" --scratch-path "$TMP/r1.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/r1.log" 2>&1
echo "swift build 退出码 = $?"
tail -1 "$TMP/r1.log"
echo '--- 中间目录里代码落在哪一层'
find "$TMP/r1.spm" -maxdepth 3 -type d | sed -e "s|$TMP/r1.spm/||" -e 's/^/    /' | sort
echo '--- 那份锁'
cat "$ROOT/Package.resolved" | sed 's/^/    /'
echo '--- workspace-state.json（在中间目录**根上**，不在 dest triple 那一层）：'
echo '    revision 与「工作副本」的对应关系写在这里，checkouts/ 里的内容由它决定'
sed -n '/"dependencies"/,/^  }/p' "$TMP/r1.spm/workspace-state.json" | sed 's/^/    /'
echo '--- checkouts 里那份工作副本现在 checkout 在哪个 tag'
( cd "$TMP/r1.spm/checkouts/upstream" && git describe --tags 2>&1 | sed 's/^/    /' )

echo
echo '=== 上游再打一个 tag 1.2.0，manifest 与锁都不改，重新 build'
printf 'public let remoteVersion = "1.2.0"\n' > "$UP/Sources/Remote/Remote.swift"
( cd "$UP" && git add -A && git -c user.email=t@t -c user.name=t commit -qm "v1.2.0" && git tag 1.2.0 )
git --git-dir="$UP/.git" tag | sort | sed 's/^/    tag: /'
env -u SDKROOT "$SWIFT" build --package-path "$ROOT" --scratch-path "$TMP/r2.spm" \
    --triple "$TARGET" --sdk "$SDK" > "$TMP/r2.log" 2>&1
echo "swift build 退出码 = $?"
grep -E 'Creating working copy|Computing|Resolved|Build complete|Working copy' "$TMP/r2.log" \
    | sed -e "s|$UP|<upstream>|g" -e 's/^/    /'
grep -E '"version"|"revision"' "$ROOT/Package.resolved" | sed 's/^ *//' | sed 's/^/    锁里还是：/'

echo
echo '=== 显式解开：swift package update'
env -u SDKROOT "$SWIFT" package --package-path "$ROOT" update > "$TMP/r3.log" 2>&1
echo "swift package update 退出码 = $?"
grep -vE '^\s*$' "$TMP/r3.log" | head -8 | sed -e "s|$UP|<upstream>|g" -e 's/^/    /'
grep -E '"version"|"revision"' "$ROOT/Package.resolved" | sed 's/^ *//' | sed 's/^/    锁现在是：/'

echo
echo '=== 删掉锁文件，用 --disable-automatic-resolution 拦一次'
rm -f "$ROOT/Package.resolved"
env -u SDKROOT "$SWIFT" build --package-path "$ROOT" --scratch-path "$TMP/r4.spm" \
    --triple "$TARGET" --sdk "$SDK" --disable-automatic-resolution > "$TMP/r4.log" 2>&1
echo "swift build 退出码 = $?"
grep -vE '^\[|Building' "$TMP/r4.log" | head -3 | sed -e "s|$ROOT|<root>|g" -e 's/^/    /'
