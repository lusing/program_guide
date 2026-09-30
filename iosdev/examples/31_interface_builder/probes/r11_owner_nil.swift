import UIKit
// 问的问题：§21/§22 的 withOwner 参数传 nil（「File's Owner 还没定」听起来合理）会怎样。
final class CardOwnerXX: NSObject {
    @IBOutlet var rootView: UIView!
    @IBOutlet var titleLabel: UILabel!
}
let nib = UINib(nibName: "r11_owner_nil", bundle: nil)
let owner = CardOwnerXX()
let ok = nib.instantiate(withOwner: owner, options: nil)
print("先按正规用法跑一次：顶层对象 = \(ok.map { NSStringFromClass(type(of: $0 as AnyObject)) })，owner.rootView = \(String(describing: owner.rootView))")
print("再把 owner 换成 nil：")
let bad = nib.instantiate(withOwner: nil, options: nil)
print("永远走不到这里：\(bad)")
