import UIKit
// 问的问题：书 4.3 那句「this class is not key value coding-compliant」的第一种现场——
// <outlet property="..."> 里那个名字在类里找不到。
final class HostNP: UIViewController {
    var reallyThere = "我在这儿"
}
let sb = UIStoryboard(name: "r03_outlet_no_property", bundle: nil)
let host = sb.instantiateInitialViewController() as! HostNP
print("instantiate 过去了（控制器 nib 解完，连接还没开始）")
host.loadViewIfNeeded()
print("永远走不到这里：视图 nib 的连接这一步就是 §12 说的那次 KVC 赋值")
