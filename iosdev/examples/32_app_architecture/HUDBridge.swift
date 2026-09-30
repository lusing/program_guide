// ============================================================
// Swift 侧的「收单人」—— 书 7.12 只走了 Swift → OC 那一个方向，这个文件是反方向。
//
// ProgressHUD.m 里的 `[[HUDSink shared] note:]` 能不能编过，取决于
// swiftc -emit-objc-header-path 生成的那份 <Module>-Swift.h 里有没有这个类，
// 而「有没有」的条件是：它是 NSObject 的子类、并且带 @objc。
// （纯 Swift 的 struct / 泛型 / 带默认参数的方法不会出现在那份头里 —— 第 27 章量过
//  这条边界，§30 只是用它。）
// ============================================================

import Foundation

@objc final class HUDSink: NSObject {

    private static let instance = HUDSink()
    private var storage: [String] = []

    /// OC 侧看到的是 `+ (HUDSink *)shared`：Swift 的 `static func` 在生成头里是类方法。
    @objc class func shared() -> HUDSink { instance }

    /// OC 侧看到的是 `- (void)note:(NSString *)text`：Swift 的 `note(_:)` 去掉下划线。
    @objc func note(_ text: String) { storage.append(text) }

    @objc func allNotes() -> [String] { storage }
    @objc func clear() { storage.removeAll() }
}
