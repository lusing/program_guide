// swift-tools-version:5.9
//
// 第 33 章的「被依赖方」——书 10.3.2 那一行 `pod 'Alamofire'` 在本机的对应物：
// 一个真的有 Package.swift 的包。它自己又是一个包（下面这个 target 只依赖标准库），
// 被 WeatherKit 用 `.package(path:)` 拉进去，好让主线能量「传递依赖 import 不 import 得到」。
import PackageDescription

let package = Package(
    name: "ClimateCore",
    products: [
        .library(name: "ClimateCore", targets: ["ClimateCore"])
    ],
    targets: [
        .target(name: "ClimateCore")
    ]
)
