import UIKit
// 问的问题：customClass 写了一个本模块里根本不存在的类名，ibtool 拦不拦？
// 上面的 ibtool 输出是答一半（拦没拦），这个文件答另一半（运行时给了什么）。
let sb = UIStoryboard(name: "b01_ghost_class", bundle: nil)
let vc = sb.instantiateInitialViewController()!
print("取到的对象运行时类名 = \(NSStringFromClass(type(of: vc)))")
print("NSClassFromString(\"interface_builder.GhostVC\") = \(String(describing: NSClassFromString("interface_builder.GhostVC")))")
print("as? NSObject 之外的成员一律读不到：这个对象身上没有 badge 这个键 → setValue 的现场见 r03/r04")
