import Foundation
struct Box { var n: Int }
print("用之前 x=\(x) box=\(bb.n)")
let x = 41
let bb = Box(n: 99)
print("用之后 x=\(x) box=\(bb.n)")
func calc(a: Int) -> Int { return a * 2 }
print("函数在定义之前调用 = \(calcBefore())")
func calcBefore() -> Int { return calc(a: 21) }
