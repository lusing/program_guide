import Foundation
let s: String? = nil
let t: String? = "hi"
print("s=\(String(describing: s)) t=\(String(describing: t))")
print("直接插值 s=\(s.debugDescription)")
print("?? 默认：\(s ?? "无")")
print("字典取值：\(["a": 1]["b"] as Any)")
print("Int(\"abc\") = \(String(describing: Int("abc")))")
print("Int(\"42\") = \(String(describing: Int("42")))")
let arr: [Int]? = [1,2,3]
print("可选链 count = \(String(describing: arr?.count))")
var none: [Int]? = nil
none?.append(1)
print("nil 上调用方法之后 = \(String(describing: none))")
