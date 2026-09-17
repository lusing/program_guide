// SwiftCounter.swift —— 反过来：一个要被 Objective-C 使用的 Swift 类
//
// 能被 OC 看见的条件：
//   1. 类本身标 @objc（或 @objcMembers），并且继承自 NSObject
//   2. 成员类型必须是「OC 能表示」的：类、Int/Bool/Double、String、@objc enum、
//      以及它们的数组/字典。Swift 的 struct、泛型、带关联值的 enum 都过不去。

import Foundation

@objc final class SwiftCounter: NSObject {
    private var value = 0

    @objc var count: Int { value }

    @objc func increment(by amount: Int) {
        value += amount
    }

    @objc func describe() -> String {
        "SwiftCounter(\(value))"
    }
}

/// @objc enum 必须是整型 raw value；到 OC 那边就变成 NS_ENUM(NSInteger, DisplayTheme)
@objc enum DisplayTheme: Int {
    case light
    case dark
}

/// 这两个成员 OC 看不见 —— 一个是 struct，一个是泛型。
/// 想让它们也能被调用，就得自己写一层包装（返回一个 OC 能表示的字典之类）。
struct NotVisibleFromObjC {
    var tag: String
}
