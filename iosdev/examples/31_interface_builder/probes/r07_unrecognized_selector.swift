import UIKit
// 问的问题：b09 那份表里写错的选择器，真按表派发时会是什么。
// 主线 §16/§25 量过「没有 UIApplication 就没有派发」，这里自己当派发者。
final class HostSL: UIViewController {
    @IBOutlet var tapButton: UIButton!
    var log: [String] = []
    @objc func didTap(_ sender: UIButton) { log.append("didTap 被调了") }
}
let sb = UIStoryboard(name: "r07_unrecognized_selector", bundle: nil)
let host = sb.instantiateInitialViewController() as! HostSL
host.loadViewIfNeeded()
let selName = host.tapButton.actions(forTarget: host, forControlEvent: .touchUpInside)?.first ?? "(表是空的)"
print("表里的选择器名 = \(selName)，类里实现的是 didTap:")
print("下面这一行就是 unrecognized selector 的现场：")
for target in host.tapButton.allTargets {
    _ = (target as AnyObject).perform(NSSelectorFromString(selName), with: host.tapButton)
}
print("永远走不到这里：\(host.log)")
