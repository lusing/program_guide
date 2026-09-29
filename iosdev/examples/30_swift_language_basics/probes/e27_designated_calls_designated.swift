import Foundation

// 书 9.6 只教了 convenience 里写 self.init()。designated 里写 self.init() 行不行？
class Car2 {
    var colour = "Black"
    init() {
        self.init(colour: "Red")
    }
    init(colour: String) { self.colour = colour }
}
print(Car2().colour)
