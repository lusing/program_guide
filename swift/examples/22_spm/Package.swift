// swift-tools-version:6.0
// 22 章示例：嵌套独立包（不在根包内——根包显式 path 不含本目录，互不干扰）
// 演示：库目标 + 可执行目标 + 产品导出 + 测试目标，一个包的完整形态。
import PackageDescription

let package = Package(
    name: "spm-demo",
    products: [
        // 产品 = 对外（其他包）可见的交付物
        .library(name: "MiniLib", targets: ["MiniLib"]),
        .executable(name: "spmdemo", targets: ["spmdemo"]),
    ],
    targets: [
        // 库目标：被 spmdemo 和测试两方依赖
        .target(
            name: "MiniLib",
            path: "Sources/MiniLib"),
        // 可执行目标：依赖库，组装成 CLI
        .executableTarget(
            name: "spmdemo",
            dependencies: ["MiniLib"],
            path: "Sources/spmdemo"),
        // 测试目标：只测库（可执行目标的逻辑应下沉到库里——可测试性设计）
        .testTarget(
            name: "MiniLibTests",
            dependencies: ["MiniLib"],
            path: "Tests/MiniLibTests"),
    ]
)
