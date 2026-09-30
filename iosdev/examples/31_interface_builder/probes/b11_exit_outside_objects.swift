import UIKit
// 问的问题：§20 那条 unwind 线之所以在运行时能查出来，靠的是场景 <objects> 里那一个
// <exit id="…" sceneMemberID="exit"/>（画布上那个 Exit 圆点）。按钮的 segue 用
// destination="EXIT-…" 指着它。那么把这个 <exit> 元素错放到 </objects> 外面（还留在
// <scene> 里面，XML 完全合法）会怎样？
// 探针 r10 用的就是这份文件的「修正版」：同样的结构，只是 <exit> 挪进了 <objects>，
// 于是那条线照常连出来。两支探针的 XML 只差这一处缩进级别的位置。
final class HostEX: UIViewController {
    @objc func unwindToHost(_ segue: UIStoryboardSegue) { print("unwindToHost 被调了") }
}
final class BetaEX: UIViewController {
    @IBOutlet var unwindButton: UIButton!
}
let sb = UIStoryboard(name: "b11_exit_outside_objects", bundle: nil)
let beta = sb.instantiateViewController(withIdentifier: "TheBeta") as! BetaEX
beta.loadViewIfNeeded()
print("按钮对象本身是好的：\(String(describing: beta.unwindButton.map { NSStringFromClass(type(of: $0)) }))")
let ts = beta.unwindButton.allTargets.map { ($0 as AnyHashable).base }
print("可它的 target 列表 = \(ts.map { NSStringFromClass(type(of: $0 as AnyObject)) }) —— 一条动作都没有")
print("对照：把同一个 <exit> 写进 <objects>（探针 r10），这里读出来就是 [\"UIStoryboardUnwindSegueTemplate\"] + [\"perform:\"]")
let sup = beta.unwindButton.superview.map { NSStringFromClass(type(of: $0)) } ?? "nil"
print("按钮本身还在层级里（superview = \(sup)），outlet 也连上了 —— 丢的只是那一条 segue 连接")
