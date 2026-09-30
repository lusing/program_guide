import Foundation

// 与 r10 成对照：子类一旦自己写了 designated 初始化方法，父类的 designated 就不再自动继承，
// 于是 Car(customerChosenColour:) 与 Car(colourName:seats:) 两个调用同时消失。
// 这一条是书 9.8「Car 中的任何事情在 SelfDrivingCar 类中都可以有」的边界。
class Car {
    var colour = "Black"
    init() {}
    init(customerChosenColour: String) { colour = customerChosenColour }
    convenience init(colourName: String, seats: Int) { self.init(customerChosenColour: colourName) }
}
class SelfDrivingCar: Car {
    var destination: String?
    init(where: String) { destination = `where` }   // 子类自己的 designated
}
let a = SelfDrivingCar()
let b = SelfDrivingCar(customerChosenColour: "Red")
print(a.colour, b.colour)
