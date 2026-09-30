import UIKit
import Foundation
// 与 b03 同一份 XML。b03 抄 ibtool 说了什么，这里数产物里还剩什么：
// 三个场景只该有 4 个 nib（入口与被指的那个各两条），孤立的那条 C-03-003 不见了。
let pkg = Bundle.main.url(forResource: "b04_unreachable_removed", withExtension: "storyboardc")!
let all = ((try? FileManager.default.contentsOfDirectory(atPath: pkg.path)) ?? []).sorted()
let nibs = all.filter { $0.hasSuffix(".nib") }.sorted()
print("包内文件 = \(all)")
print("nib 个数 = \(nibs.count)")
print("nib 名单 = \(nibs)")
let info = NSDictionary(contentsOf: pkg.appendingPathComponent("Info.plist")) as? [String: Any]
let map = (info?["UIViewControllerIdentifiersToNibNames"] as? [String: String]) ?? [:]
print("查找表键 = \(map.keys.sorted())")
print("查找表里有没有 C-03-003 = \(map.keys.contains("C-03-003"))")
