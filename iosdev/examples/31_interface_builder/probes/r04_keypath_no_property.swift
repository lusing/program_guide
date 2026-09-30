import UIKit
// 问的问题：Inspector 里那格填了个类里没有的 keyPath。和 r03 的区别要用退出码来说：
// 一个把进程带走，一个只在 stderr 留一行字。
final class HostKP: UIViewController {}
let sb = UIStoryboard(name: "r04_keypath_no_property", bundle: nil)
let host = sb.instantiateInitialViewController() as! HostKP
print("instantiate 回来了，类型 = \(NSStringFromClass(type(of: host)))")
host.loadViewIfNeeded()
print("视图照常加载：subviews = \(host.view.subviews.count)")
print("这一支是跑完的（对照上面的运行退出码）—— 软失败与硬失败的分界就在这儿")
