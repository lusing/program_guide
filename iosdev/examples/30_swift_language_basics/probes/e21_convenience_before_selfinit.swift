import Foundation

// 书 9.6 的 convenience 初始化方法：先 self.init() 再改属性。
// 这里把两行调换顺序，看看 Swift 6.0.3 的原话（书里只说「首先要调用 Designated 初始化方法」）。
class Car {
    var colour = "Black"
    init() {}
    convenience init(customerChosenColour: String) {
        colour = customerChosenColour
        self.init()
    }
}
let c = Car(customerChosenColour: "Red")
print(c.colour)
