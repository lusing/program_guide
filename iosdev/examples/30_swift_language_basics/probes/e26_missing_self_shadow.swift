import Foundation

// 书 9.6 的注释：「因为参数名称与类中属性名称一样，所以这里使用 self.属性名称」。
// 忘了写 self. 会怎样？三种写法各跑一遍，看编译器抓到几种。
class ShadowedCar {
    var colour = "Black"
    func setA(colour: String) { colour = colour }        // 忘了 self.：改的是参数自己
    func setB(seats: Int) { var local = 0; local = local + seats; _ = local }
    func setC(colour2: String) { colour = colour2 }      // 名字不冲突，不带 self 也正确
    func report() -> String { return colour }
}
let c = ShadowedCar()
c.setA(colour: "Red")
print("setA 之后属性 = \(c.report())")
c.setC(colour2: "Blue")
print("setC 之后属性 = \(c.report())")
