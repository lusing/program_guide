import UIKit
// 探针 b05：Inspector 那格的取值子元素写成 <integer>（主线 §14 用的是 <real>）。
// 问两句：ibtool 拦不拦（看上面那段 ibtool 输出）、值到运行时进得来得不。
final class HostIV: UIViewController {
    @IBInspectable var badge: Double = 0
}
let sb = UIStoryboard(name: "b05_integer_value", bundle: nil)
let host = sb.instantiateInitialViewController() as! HostIV
print("type=\"number\" + <integer> 编出来的产物照常可用，取到的类型 = \(NSStringFromClass(type(of: host)))")
print("badge = \(host.badge)（类里声明的默认值是 0，所以这个数只能是 XML 填进来的）")
print("这一格没崩、没告警、值也进来了 —— 与 b10 那种「type 与取值子元素对不上」正好成对照")
