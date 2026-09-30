import UIKit
// 问的问题：§6 说的「instantiateInitialViewController() 的静态类型是 UIView
// Controller?」在写代码时挡不挡得住直接点成员。
final class EntryLike: UIViewController {
    @IBOutlet var titleLabel: UILabel!
    var badge: Double = 0
}
let sb = UIStoryboard(name: "b01_ghost_class", bundle: nil)
let vc = sb.instantiateInitialViewController()
print(vc?.titleLabel)
print(vc?.badge ?? -1)
