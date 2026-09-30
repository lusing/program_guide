import UIKit
// 问的问题：类是**真的存在**（就是本文件里这个），只是 XML 的 customModule 写错了。
// 运行时问的全名是 "wrong_module_name.RealButWrongModuleVC" —— 一个也问不到。
final class RealButWrongModuleVC: UIViewController {
    var marker = "本不该被读到"
}
let sb = UIStoryboard(name: "b02_wrong_module", bundle: nil)
let vc = sb.instantiateInitialViewController()!
print("取到的对象运行时类名 = \(NSStringFromClass(type(of: vc)))")
print("本模块里那个类的全名 = \(NSStringFromClass(RealButWrongModuleVC.self))")
print("NSClassFromString(\"wrong_module_name.RealButWrongModuleVC\") = \(String(describing: NSClassFromString("wrong_module_name.RealButWrongModuleVC")))")
print("as? RealButWrongModuleVC = \(String(describing: vc as? RealButWrongModuleVC))")
