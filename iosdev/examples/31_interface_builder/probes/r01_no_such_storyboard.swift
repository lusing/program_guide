import UIKit
// 问的问题：UIStoryboard(name:) 里的名字在 bundle 找不到，是返回 nil 还是当场崩？
print("准备取一个 bundle 里不存在的故事板 NoSuchStoryboard……")
let sb = UIStoryboard(name: "NoSuchStoryboard", bundle: nil)
print("构造这一行过去了：\(String(reflecting: type(of: sb)))")
let vc = sb.instantiateInitialViewController()
print("永远走不到这里：\(String(describing: vc))")
