import UIKit
// 问的问题：那条「线」连到了空气上（destination 指向一个 XML 里不存在的 id）。
final class HostMT: UIViewController {
    @IBOutlet var titleLabel: UILabel?
}
let sb = UIStoryboard(name: "b06_outlet_missing_target", bundle: nil)
let host = sb.instantiateInitialViewController() as! HostMT
host.loadViewIfNeeded()
print("视图照样加载：subviews = \(host.view.subviews.count)")
print("titleLabel = \(String(describing: host.titleLabel)) —— 这就是「拖了个半截线」的运行时样子")
