import Foundation

// 书 11.3 叮嘱「calculator(n1:n2:operation:add) 一定要放到两个函数定义的后面」。
// 对 func 名字这条不必要（探针 e04：定义在后面照样调得动）；对存在 let 里的闭包这条必要：
// 下面第一行调用发生在 let doubler 初始化之前，读到的是没填过的内存。
func applyTwice(_ n: Int) -> Int { return doubler(n) }
print("在 let doubler 之前调用 applyTwice(5) = \(applyTwice(5))")
let doubler = { (n: Int) in n * 2 }
print("之后再调 = \(applyTwice(5))")
