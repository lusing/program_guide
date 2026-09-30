import UIKit
// 问的问题：§9 说 storyboardIdentifier 与 XML 的 id 是两回事。用 id 去取会怎样？
// （这个场景是**可达**的，nib 在产物里，所以崩的原因不是「没编进来」，是「查不到键」。）
final class HostOI: UIViewController {}
final class HostOI2: UIViewController {}
let sb = UIStoryboard(name: "r02_objectid_lookup", bundle: nil)
let map = ((NSDictionary(contentsOf: Bundle.main.url(forResource: "r02_objectid_lookup", withExtension: "storyboardc")!.appendingPathComponent("Info.plist")) as? [String: Any])?["UIViewControllerIdentifiersToNibNames"] as? [String: String]) ?? [:]
print("查找表键 = \(map.keys.sorted())")
let ok = sb.instantiateViewController(withIdentifier: "NamedScreen")
print("用 storyboardIdentifier 取得到 = \(NSStringFromClass(type(of: ok)))")
print("再把 XML 里那个 id=\"OI-02-020\" 当标识符用：")
let bad = sb.instantiateViewController(withIdentifier: "OI-02-020")
print("永远走不到这里：\(String(describing: bad))")
