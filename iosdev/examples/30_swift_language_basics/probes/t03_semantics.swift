import Foundation

// class / struct / 数组 / 字典的「赋值到底是拷贝还是共享」，一次跑完。
class CarC { var colour = "Black"; func describe() -> String { return colour } }
// struct 也不会自动有 ==：要显式写 : Equatable（编译器给的诊断见 e24_*）。
struct CarS: Equatable { var colour = "Black" }

let c1 = CarC(); let c2 = CarC(); c2.colour = "Red"
print("两个独立实例：c1=\(c1.describe()) c2=\(c2.describe()) 同一对象=\(c1 === c2)")
let alias = CarC(); let alias2 = alias; alias2.colour = "Red"
print("class 赋值给另一个常量：alias=\(alias.colour) —— 改 alias2 就是改 alias（同一对象：\(alias === alias2)）")
let cc = CarC(); cc.colour = "Gold"
print("class 的 let 实例可以改属性：describe=\(cc.describe())")
var s1 = CarS(); var s2 = s1; s2.colour = "Red"
print("struct：s1=\(s1.colour) s2=\(s2.colour) 值相等=\(s1 == s2)")
let arrA = [1, 2, 3]; var arrB = arrA; arrB.append(4)
print("数组：arrA=\(arrA) arrB=\(arrB) —— 赋值即拷贝（写时才复制）")
var dict: [String: Int] = ["a": 1]
let dictCopy = dict
dict["b"] = 2
print("字典：加一键之后 原 count=\(dict.count) 拷贝 count=\(dictCopy.count)")
let f1: (Int) -> Int = { $0 + 1 }
print("函数类型变量：f1(1)=\(f1(1))，type(of:) = \(type(of: f1))")
