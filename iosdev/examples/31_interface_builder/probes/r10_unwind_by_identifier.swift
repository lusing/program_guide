import UIKit
// 问的问题：§20 读到那条 unwind 线挂在按钮的表里（target 是 UIStoryboardUnwindSegueTemplate，
// 动作是 perform:）。最直觉的那一句是「拿 identifier 去控制器的 performSegue(withIdentifier:)」——
// 它查得到吗？如果查得到，弹栈这一步在 headless 里会发生吗？
// 这份 XML 的 <exit> 是正规写法（在场景的 <objects> 里面，见探针 b11 的对照）。
final class AlphaUN: UIViewController {
    @objc func unwindToAlpha(_ segue: UIStoryboardSegue) {
        print("  unwindToAlpha 被调了：source=\(NSStringFromClass(type(of: segue.source)))"
            + " destination=\(NSStringFromClass(type(of: segue.destination)))"
            + " identifier=\(segue.identifier ?? "nil")")
    }
}
final class BetaUN: UIViewController {
    @IBOutlet var unwindButton: UIButton!
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        print("  Beta 的 prepare 也跑了：segue=\(segue.identifier ?? "nil") 类名=\(NSStringFromClass(type(of: segue)))")
    }
}
let sb = UIStoryboard(name: "r10_unwind_by_identifier", bundle: nil)
let nav = sb.instantiateInitialViewController() as! UINavigationController
let alpha = nav.viewControllers[0] as! AlphaUN
alpha.loadViewIfNeeded()
alpha.performSegue(withIdentifier: "showB", sender: nil)
let beta = nav.viewControllers[1] as! BetaUN
// beta 只是被压进栈里，没有窗口摆它的视图，所以 outlet 还没连上；加载一次，排除
// 「其实是 outlet 没连上」这一种误解。
beta.loadViewIfNeeded()
print("第一步 入栈：栈深 = \(nav.viewControllers.count)，unwindButton = \(NSStringFromClass(type(of: beta.unwindButton!)))")
let ts = beta.unwindButton.allTargets.map { ($0 as AnyHashable).base }
print("那张表里的 target：\(ts.map { NSStringFromClass(type(of: $0 as AnyObject)) })")
for t in ts {
    print("  touchUpInside 上的动作：\(beta.unwindButton.actions(forTarget: t, forControlEvent: .touchUpInside) ?? [])")
}
print("第二步 拿那条线的 identifier 去控制器的 performSegue：")
beta.performSegue(withIdentifier: "backToAlpha", sender: beta.unwindButton)
print("没有抛异常，走到了这一行。")
print("之后：栈深 = \(nav.viewControllers.count) 栈顶 = \(NSStringFromClass(type(of: nav.topViewController!)))")
print("     beta.navigationController = \(String(describing: beta.navigationController.map { _ in "还在容器里" }))")
print("     beta.view.superview = \(String(describing: beta.view.superview.map { NSStringFromClass(type(of: $0)) }))")
print("第三步 再点一次同一个 identifier（此时 beta 已经在栈外，如果它被弹掉了的话）：")
beta.performSegue(withIdentifier: "backToAlpha", sender: beta.unwindButton)
print("也还没抛？栈深 = \(nav.viewControllers.count)")
