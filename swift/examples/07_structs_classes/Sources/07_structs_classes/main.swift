// 07 · 结构体与类——值/引用语义、属性种类、mutating、deinit、静态成员

import Foundation

// ═══ 7.1 纯函数区（供测试）
struct Size: Equatable {
    var width: Double
    var height: Double

    // 存储属性 + 计算属性
    var area: Double { width * height }

    // mutating：结构体方法要改 self，必须显式声明
    mutating func scale(by factor: Double) {
        width *= factor
        height *= factor
    }
}

struct Rect {
    var origin: (x: Double, y: Double)
    var size: Size

    var center: (x: Double, y: Double) {
        (origin.x + size.width / 2, origin.y + size.height / 2)
    }
}

class TicketCounter {
    // 属性观察者：willSet/didSet
    var remaining: Int {
        willSet { print("  willSet：剩余 \(remaining) → \(newValue)") }
        didSet { print("  didSet：剩余由 \(oldValue) 变为 \(remaining)") }
    }

    // static：类型属性（全体实例共享）
    static let price = 30

    var sold: Int = 0
    let location: String

    init(location: String, remaining: Int) {
        self.location = location
        self.remaining = remaining
    }

    deinit {
        print("  deinit：\(location) 窗口关闭")  // 类专属：引用计数归零时调用
    }

    func sellOne() -> Bool {
        guard remaining > 0 else { return false }
        remaining -= 1
        sold += 1
        return true
    }
}

/// 值语义 vs 引用语义的对照实验：拷贝结构体是独立副本
func widenCopy(_ s: Size) -> Size {
    var copy = s  // 值拷贝
    copy.width += 100
    return copy
}

func refill(_ counter: TicketCounter, to amount: Int) {
    counter.remaining = amount  // 引用传递：改的就是调用方的对象
}

// ═══ 7.2 值语义：struct 拷贝后互不影响
var a = Size(width: 3, height: 4)
precondition(a.area == 12, "面积断言失败")
let b = a  // 拷贝
a.scale(by: 2)
print("a 缩放后 \(a)，b 不受影响 \(b)")  // b 仍是 3×4
precondition(b.area == 12)
let widened = widenCopy(a)
print("函数内改副本：widened=\(widened.area)，原 a=\(a.area)")
precondition(a.area == 48 && widened.area == 848)  // 宽 +100：(6+100)×8

// ═══ 7.3 结构体的成员式初始化器（免写 init）
let rect = Rect(origin: (x: 0, y: 0), size: Size(width: 10, height: 6))
print("矩形中心 = \(rect.center)")
precondition(rect.center.x == 5)

// ═══ 7.4 引用语义 + 属性观察者 + deinit
print("开两个窗口：")
var westGate: TicketCounter? = TicketCounter(location: "西门", remaining: 2)
let eastGate = TicketCounter(location: "东门", remaining: 0)
_ = westGate?.sellOne()  // 命中 willSet/didSet 打印
precondition(westGate!.sold == 1)
precondition(eastGate.sellOne() == false, "东门没票了")
refill(eastGate, to: 5)  // 引用语义：函数内修改直接生效
precondition(eastGate.remaining == 5)
print("票价（类型属性）：\(TicketCounter.price)")
westGate = nil  // 断开最后一个强引用 → 触发 deinit 打印
print("两个窗口状态：东门 remaining=\(eastGate.remaining) sold=\(eastGate.sold)")

print("==== 07 结束 ====")
