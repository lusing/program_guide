import UIKit
// 问的问题：两条 segue 共用一个 identifier（b07 量过 ibtool 对此说什么），
// performSegue(withIdentifier: "dup") 到底走哪一条？两个目标的类不同，所以看得出来。
final class HostNU: UIViewController {
    var seen: [String] = []
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        seen.append("prepare: \(segue.identifier ?? "无") → \(NSStringFromClass(type(of: segue.destination)))")
    }
}
final class HostZ1: UIViewController {}
final class HostZ2: UIViewController {}
let sb = UIStoryboard(name: "r09_dup_identifier_runtime", bundle: nil)
let nav = sb.instantiateInitialViewController() as! UINavigationController
let root = nav.viewControllers[0] as! HostNU
root.loadViewIfNeeded()
root.performSegue(withIdentifier: "dup", sender: nil)
print("prepare 记账 = \(root.seen)")
print("栈里现在 = \(nav.viewControllers.map { NSStringFromClass(type(of: $0)) })")
print("XML 里两条 segue 的 id 分别是 sgDupA（→ HostZ1）与 sgDupB（→ HostZ2）")
