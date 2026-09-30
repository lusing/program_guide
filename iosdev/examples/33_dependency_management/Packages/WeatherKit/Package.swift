// swift-tools-version:5.9
//
// 第 33 章的「工程这一侧」——书 10.3.2 那份 Podfile 在本机的对应物。
//
// 这份文件本身是一段 Swift 程序（manifest），它不参与主线的 swiftc：
// 先由 `swift build` 单独编译执行，产出的才是下面这些 target 的 .o 与 .swiftmodule。
//
// 三处刻意留下的形状，主线各自有一节：§4（三个名字）、§5（依赖的两层）、§16（资源的路径基准）。
//   1. product 名、target 名、module 名是三个东西（这里 product 与 target 同名，拆开量在探针 s05）；
//   2. `dependencies` 有两层：包与包之间（下面的 `.package(path:)`）与 target 之间
//      （WeatherKit target 的 dependencies 里那一行）。两层的硬度不一样，而且和直觉相反：
//      少写**外层**（下面的 `.package(path:)`）当场失败在 manifest 校验，
//      少写**内层**（WeatherKit target 的 dependencies 里那一行）在本机连编译都不拦（探针 s09）；
//   3. resources 的路径基准是 **target 目录**，不是包根目录（原文见探针 s03）。
import PackageDescription

let package = Package(
    name: "WeatherKit",
    products: [
        .library(name: "WeatherKit", targets: ["WeatherKit"]),
        .library(name: "CLIBrain", targets: ["CLIBrain"])
    ],
    dependencies: [
        .package(path: "../ClimateCore")
    ],
    targets: [
        .target(
            name: "WeatherKit",
            dependencies: [
                "ClimateCore",
                "CLIBrain"
            ],
            resources: [
                .copy("Resources/city.json"),
                .process("Resources/nested")
            ]
        ),
        .target(name: "CLIBrain"),
        .testTarget(name: "WeatherKitTests", dependencies: ["WeatherKit"])
    ]
)
