import Foundation

/// 被 OC 调用的 Swift 类。只有 @objc + NSObject 子类才会出现在生成的
/// <Module>-Swift.h 里，OC 才看得见它。
@objc final class SwiftCounter: NSObject {
    @objc private(set) var count: Int = 0
    /// Swift 的 increment(by:) → OC 的 selector incrementBy:
    @objc func increment(by delta: Int) { count += delta }
    @objc func describe() -> String { return "count=\(count)" }
}

/// @objc enum 必须是整型 rawValue，在 OC 里变成 NS_ENUM（ThemeLight/ThemeDark）。
@objc enum Theme: Int {
    case light = 0
    case dark = 1
}
