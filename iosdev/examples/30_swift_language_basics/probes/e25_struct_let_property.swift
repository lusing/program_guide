import Foundation

// class 的 let 实例可以改属性（§12 实测），struct 的 let 常量不行 —— 同一行写法，两种命运。
struct SeatPlan { var numberOfSeats: Int = 5 }
let p = SeatPlan()
p.numberOfSeats = 7
print(p.numberOfSeats)
