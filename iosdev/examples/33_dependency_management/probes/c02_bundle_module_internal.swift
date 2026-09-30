// c02：主线上写 `Bundle.module` 会红 —— 因为它是**生成在包内部**的一个 internal 常量。
//
// SwiftPM 看到 target 声明了 resources，就往那个 target 里追加一个源文件
// （`<Target>.build/DerivedSources/resource_bundle_accessor.swift`，见探针 s04 / s12），
// 内容是 `extension Foundation.Bundle { static let module: Bundle = { … }() }`。
// 那一行没写访问级别，默认就是 internal —— 于是这个「所有包都有的 Bundle.module」
// 恰恰只在**它自己那个模块**里可用。
//
// 这一支要量的两个配置给的 note 不一样（s04 只看了 debug 那侧）：
//   -Onone  ⇒ note 指向那个生成出来的 .swift 源文件（编译器手上有源码）
//   -O      ⇒ note 指向 `WeatherKit.Bundle (internal)` 那段**接口**（编译器只读 .swiftmodule）
// 这两行原文合起来说明一件事：跨模块时你看到的永远是接口，不是实现。
//
// 跑法：bash probes/run.sh c02（两个配置各编一次，抄两份 note 的差别）
import Foundation
import WeatherKit

let u = Bundle.module.url(forResource: "city", withExtension: "json")
print(u == nil ? "missing" : "found")
