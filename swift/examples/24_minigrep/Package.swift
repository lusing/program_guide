// swift-tools-version:6.0
// 24 章实战：迷你 grep——库（MinigrepCore，可测）+ CLI（minigrep，薄壳）+ 测试
import PackageDescription

let package = Package(
    name: "minigrep",
    products: [
        .library(name: "MinigrepCore", targets: ["MinigrepCore"]),
        .executable(name: "minigrep", targets: ["minigrep"]),
    ],
    targets: [
        .target(
            name: "MinigrepCore",
            path: "Sources/MinigrepCore"),
        .executableTarget(
            name: "minigrep",
            dependencies: ["MinigrepCore"],
            path: "Sources/minigrep"),
        .testTarget(
            name: "MinigrepCoreTests",
            dependencies: ["MinigrepCore"],
            path: "Tests/MinigrepCoreTests"),
    ]
)
