import UIKit
// 问的问题：同一个 XIB，owner 传一个「不是那个类」的对象（NSObject()）。
// 异常与 r11 同族，但那句键名与措辞要各抄一份。
final class CardOwnerXX: NSObject {
    @IBOutlet var rootView: UIView!
    @IBOutlet var titleLabel: UILabel!
}
let nib = UINib(nibName: "r12_owner_wrong_type", bundle: nil)
print("owner = NSObject()：")
let bad = nib.instantiate(withOwner: NSObject(), options: nil)
print("永远走不到这里：\(bad)")
