import Foundation

// 书 9.8 只教了「子类什么都能有」，没讲对象相等的判法。
// Swift 里 == 走 Equatable（struct 也不自动有，要显式声明），class 实例默认只有 ===。
class CarC { var colour = "Black" }
struct CarS { var colour = "Black" }
let c1 = CarC(); let c2 = CarC()
print(c1 == c2)
let s1 = CarS(); let s2 = CarS()
print(s1 == s2)
