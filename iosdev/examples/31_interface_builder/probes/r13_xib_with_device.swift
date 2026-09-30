import UIKit
// 探针 r13（有 <device>）：XIB 顶层视图交回来时的 frame，取决于这份 XIB 里有没有 <device> 那一行。
// 两份文件的唯一差别就是那一个元素；XML 里顶层视图自己那格写的是 600×600。
final class CardOwnerR13: NSObject {
    @IBOutlet var rootView: UIView!
    @IBOutlet var titleLabel: UILabel!
}
let nib = UINib(nibName: "r13_xib_with_device", bundle: nil)
let owner = CardOwnerR13()
let top = nib.instantiate(withOwner: owner, options: nil)
print("顶层对象 = \(top.map { NSStringFromClass(type(of: $0 as AnyObject)) })")
print("顶层视图的 frame = \(owner.rootView.frame)")
print("XML 里那一格写的是 600.0×600.0；UIScreen.main.bounds = \(UIScreen.main.bounds)")
print("titleLabel.text = \(owner.titleLabel?.text ?? "nil")，它的 frame = \(String(describing: owner.titleLabel?.frame))")
