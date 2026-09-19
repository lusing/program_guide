// swift-tools-version:6.0
// Swift 教程根包：每个示例章一个可执行目标 + 对应 swift-testing 测试目标。
// 目标名必须合法标识符（不能 02_hello 数字开头）→ ChNN 大驼峰，path 映射到数字目录。
// 22_spm / 24_minigrep 是嵌套独立包，不进根包（显式 path、无 glob，互不干扰——实测）。
import PackageDescription

let package = Package(
    name: "swift-guide",
    targets: [
        .executableTarget(
            name: "Ch02Hello",
            path: "examples/02_hello/Sources/02_hello"),
        .testTarget(
            name: "Ch02HelloTests",
            dependencies: ["Ch02Hello"],
            path: "examples/02_hello/Tests/02_helloTests"),
    ]
)
