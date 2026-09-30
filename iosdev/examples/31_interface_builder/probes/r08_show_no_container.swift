import UIKit
// 问的问题：b08 那份 XML（kind="show" 但没有导航容器）在运行时 performSegue 会做什么。
final class HostKN: UIViewController {
    var seen: [String] = []
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        seen.append("prepare: \(segue.identifier ?? "无") → \(NSStringFromClass(type(of: segue.destination)))")
    }
}
final class HostKX: UIViewController {}
let sb = UIStoryboard(name: "r08_show_no_container", bundle: nil)
let host = sb.instantiateInitialViewController() as! HostKN
host.loadViewIfNeeded()
print("parent = \(String(describing: host.parent))，navigationController = \(String(describing: host.navigationController))")
print("performSegue(withIdentifier: \"goX\")（这条 segue 的 kind 是 show）：")
host.performSegue(withIdentifier: "goX", sender: nil)
print("之后：seen = \(host.seen)")
print("presentedViewController = \(String(describing: host.presentedViewController))")
