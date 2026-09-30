import UIKit
// 问的问题：把 @IBOutlet var titleLabel: UILabel!（隐式解包）写成 UILabel? 会怎样？
final class HostOP: UIViewController {
    @IBOutlet var titleLabel: UILabel?
}
let sb = UIStoryboard(name: "r05_optional_iboutlet", bundle: nil)
let host = sb.instantiateInitialViewController() as! HostOP
print("instantiate 之后 titleLabel = \(String(describing: host.titleLabel))")
host.loadViewIfNeeded()
print("loadView 之后 titleLabel?.text = \(host.titleLabel?.text ?? "nil")")
let child = Mirror(reflecting: host).children.first { $0.label == "titleLabel" }
print("Mirror 里这一项的类型 = \(String(describing: child.map { String(reflecting: Swift.type(of: $0.value)) }))")
