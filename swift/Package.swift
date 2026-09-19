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
        .executableTarget(
            name: "Ch03Basics",
            path: "examples/03_basics/Sources/03_basics"),
        .testTarget(
            name: "Ch03BasicsTests",
            dependencies: ["Ch03Basics"],
            path: "examples/03_basics/Tests/03_basicsTests"),
        .executableTarget(
            name: "Ch04Control",
            path: "examples/04_control/Sources/04_control"),
        .testTarget(
            name: "Ch04ControlTests",
            dependencies: ["Ch04Control"],
            path: "examples/04_control/Tests/04_controlTests"),
        .executableTarget(
            name: "Ch05Functions",
            path: "examples/05_functions/Sources/05_functions"),
        .testTarget(
            name: "Ch05FunctionsTests",
            dependencies: ["Ch05Functions"],
            path: "examples/05_functions/Tests/05_functionsTests"),
        .executableTarget(
            name: "Ch06Optionals",
            path: "examples/06_optionals/Sources/06_optionals"),
        .testTarget(
            name: "Ch06OptionalsTests",
            dependencies: ["Ch06Optionals"],
            path: "examples/06_optionals/Tests/06_optionalsTests"),
        .executableTarget(
            name: "Ch07StructsClasses",
            path: "examples/07_structs_classes/Sources/07_structs_classes"),
        .testTarget(
            name: "Ch07StructsClassesTests",
            dependencies: ["Ch07StructsClasses"],
            path: "examples/07_structs_classes/Tests/07_structs_classesTests"),
        .executableTarget(
            name: "Ch08Enums",
            path: "examples/08_enums/Sources/08_enums"),
        .testTarget(
            name: "Ch08EnumsTests",
            dependencies: ["Ch08Enums"],
            path: "examples/08_enums/Tests/08_enumsTests"),
        .executableTarget(
            name: "Ch09Protocols",
            path: "examples/09_protocols/Sources/09_protocols"),
        .testTarget(
            name: "Ch09ProtocolsTests",
            dependencies: ["Ch09Protocols"],
            path: "examples/09_protocols/Tests/09_protocolsTests"),
        .executableTarget(
            name: "Ch10Generics",
            path: "examples/10_generics/Sources/10_generics"),
        .testTarget(
            name: "Ch10GenericsTests",
            dependencies: ["Ch10Generics"],
            path: "examples/10_generics/Tests/10_genericsTests"),
        .executableTarget(
            name: "Ch11Closures",
            path: "examples/11_closures/Sources/11_closures"),
        .testTarget(
            name: "Ch11ClosuresTests",
            dependencies: ["Ch11Closures"],
            path: "examples/11_closures/Tests/11_closuresTests"),
        .executableTarget(
            name: "Ch12Errors",
            path: "examples/12_errors/Sources/12_errors"),
        .testTarget(
            name: "Ch12ErrorsTests",
            dependencies: ["Ch12Errors"],
            path: "examples/12_errors/Tests/12_errorsTests"),
        .executableTarget(
            name: "Ch13Collections",
            path: "examples/13_collections/Sources/13_collections"),
        .testTarget(
            name: "Ch13CollectionsTests",
            dependencies: ["Ch13Collections"],
            path: "examples/13_collections/Tests/13_collectionsTests"),
        .executableTarget(
            name: "Ch14Strings",
            path: "examples/14_strings/Sources/14_strings"),
        .testTarget(
            name: "Ch14StringsTests",
            dependencies: ["Ch14Strings"],
            path: "examples/14_strings/Tests/14_stringsTests"),
        .executableTarget(
            name: "Ch15Extensions",
            path: "examples/15_extensions/Sources/15_extensions"),
        .testTarget(
            name: "Ch15ExtensionsTests",
            dependencies: ["Ch15Extensions"],
            path: "examples/15_extensions/Tests/15_extensionsTests"),
    ]
)
