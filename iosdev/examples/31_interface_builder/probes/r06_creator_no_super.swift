import UIKit
// 问的问题：§13 那个 creator 闭包返回一个「没拿这台 coder 走过 super.init(coder:)」的
// 对象会怎样。合法写法是 HostCR(coder: coder)，这里故意返回 HostCR()。
final class HostCR: UIViewController {
    init() { super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { super.init(coder: coder) }
}
let sb = UIStoryboard(name: "r06_creator_no_super", bundle: nil)
print("准备让闭包返回一个 plain HostCR()……")
let made = sb.instantiateInitialViewController { (coder: NSCoder) -> HostCR? in
    print("  闭包被调用，收到的 coder = \(NSStringFromClass(type(of: coder)))")
    return HostCR()
}
print("永远走不到这里：\(String(describing: made))")
