import UIKit
// 探针 b09：@IBAction 的选择器名字写错一个字母（XML 里 didTapp:，类里实现的是 didTap:）。
// 这一支只读表、不派发（真按表派发的下场见 r07）。
final class HostSL: UIViewController {
    @IBOutlet var tapButton: UIButton!
    var log: [String] = []
    @objc func didTap(_ sender: UIButton) { log.append("didTap 被调了") }
}
let sb = UIStoryboard(name: "b09_bad_selector", bundle: nil)
let host = sb.instantiateInitialViewController() as! HostSL
host.loadViewIfNeeded()
// allTargets 的元素被 AnyHashable 包了一层，要取 .base 才是真对象（主线 §15 同一个坑）。
let names = host.tapButton.allTargets.map { NSStringFromClass(type(of: ($0 as AnyHashable).base as AnyObject)) }
print("表里的 target 类名 = \(names.sorted())")
print("touchUpInside 这一格的表 = \(host.tapButton.actions(forTarget: host, forControlEvent: .touchUpInside) ?? [])")
print("类里实现的是 didTap:，两边各问一句 responds(to:)：")
print("  responds(to: \"didTapp:\") = \(host.responds(to: NSSelectorFromString("didTapp:")))")
print("  responds(to: \"didTap:\") = \(host.responds(to: NSSelectorFromString("didTap:")))")
print("写错的名字照样能进表、照样能被 SEL 构造出来 —— 这一步没人拦（上面 ibtool 输出就是「没人拦」的证据）")
