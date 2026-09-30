import Foundation

// 书 5.9 给的修补：把 for iteration in 0...n 改成 for iteration in 0...n-3。
// n >= 3 时项数正好等于 n；n < 3 时 0...(n-3) 是一个「下限大于上限」的区间。
// 编译期一声不响（构造 ClosedRange 的那一行没有任何诊断），运行期当场 fatal。
func fibonacciBookPatched(until n: Int) -> [Int] {
    var out = [0, 1]
    var num1 = 0
    var num2 = 1
    for _ in 0...(n - 3) {
        let num = num1 + num2
        out.append(num)
        num1 = num2
        num2 = num
    }
    return out
}

print("before")
print(fibonacciBookPatched(until: 2).count)
print("after")
