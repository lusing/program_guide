import Foundation

// 书 9.6 说「你还可以再定义几个不同的 Convenience 方法」，书 9.8 说「Car 中的任何事情
// 在 SelfDrivingCar 类中都可以有」。子类到底能调用父类的哪些初始化方法？
// 三个调用一起写，Swift 6.0.3 全部接受 —— 但第三个是「间接可用」，不是「继承」，
// 这一点由 e22_subclass_own_designated.swift 的反例钉住。
class Car {
    var colour = "Black"
    init() {}
    init(customerChosenColour: String) { colour = customerChosenColour }
    convenience init(colourName: String, seats: Int) { self.init(customerChosenColour: colourName) }
}
class SelfDrivingCar: Car {
    var destination: String?
}
let a = SelfDrivingCar()
let b = SelfDrivingCar(customerChosenColour: "Red")
let c = SelfDrivingCar(colourName: "Gold", seats: 4)
print("无参 = \(a.colour)")
print("父类 designated = \(b.colour)")
print("父类 convenience = \(c.colour)")
