// 15 · 扩展与下标——万物可扩、retroactive 风险、subscript、泛型约束 extension、属性进阶

import Foundation

// ═══ 15.1 纯函数区（供测试）
// extension 给既有类型加方法/计算属性（标准库类型也照加不误）
extension Int {
    var isEven: Bool { self % 2 == 0 }
    func times(_ action: (Int) -> Void) {
        for i in 1...self { action(i) }
    }
    var squared: Int { self * self }
}

extension String {
    /// 首字母大写（单词级）
    var titleCased: String {
        split(separator: " ").map { $0.prefix(1).uppercased() + $0.dropFirst() }.joined(
            separator: " ")
    }

    /// 下标安全访问：越界返回 nil 而不是崩溃
    subscript(safe index: Int) -> Character? {
        guard index >= 0, index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
}

// 泛型约束 extension：只有 Comparable 元素的数组才有 median
extension Array where Element: Comparable {
    var median: Element? {
        guard !isEmpty else { return nil }
        let sorted = self.sorted()
        return sorted[count / 2]
    }
}

// property wrapper：把"属性 + 存取逻辑"打包复用
@propertyWrapper
struct Clamped {
    var wrappedValue: Int {
        didSet { wrappedValue = min(max(wrappedValue, low), high) }
    }
    let low: Int
    let high: Int

    init(wrappedValue: Int, low: Int, high: Int) {
        self.low = low
        self.high = high
        self.wrappedValue = min(max(wrappedValue, low), high)
    }
}

struct GameSettings {
    @Clamped(low: 1, high: 10) var volume: Int = 5
    @Clamped(low: 0, high: 100) var brightness: Int = 80
}

func makeSettings(volume: Int, brightness: Int) -> GameSettings {
    var s = GameSettings()
    s.volume = volume
    s.brightness = brightness
    return s
}

// ═══ 15.2 给 Int 加的能力
precondition(4.isEven && !7.isEven)
precondition(9.squared == 81)
var collected: [Int] = []
5.times { collected.append($0 * 10) }
precondition(collected == [10, 20, 30, 40, 50])
print("5.times 收集：\(collected)")

// ═══ 15.3 String 的 titleCased 与安全下标
let title = "the swift programming language"
print("titleCased：\(title.titleCased)")
precondition(title.titleCased == "The Swift Programming Language")
precondition(title[safe: 0] == "t")
precondition(title[safe: 100] == nil)  // 越界给 nil，不崩
print("安全下标：[0]=\(String(title[safe: 0]!))，[100]=nil")

// ═══ 15.4 泛型约束 extension：median 只对可排序数组生效
precondition([3, 1, 2].median == 2)
precondition([Int]().median == nil)
precondition(["b", "c", "a", "d"].median == "c")  // 排序后 a b c d，取 count/2=2 → c
print("median([3,1,2]) = \([3, 1, 2].median!)")

// ═══ 15.5 property wrapper：一行声明拿到"自动夹取"属性
let settings = makeSettings(volume: 42, brightness: -5)
precondition(settings.volume == 10)  // 夹到上限
precondition(settings.brightness == 0)  // 夹到下限
print("音量 42→\(settings.volume)，亮度 -5→\(settings.brightness)")

// ═══ 15.6 retroactive conformance：给不属于自己的类型补协议（谨慎区）
struct Meter {
    let value: Double
}
// String 是标准库的——给它补 CustomStringConvertible？标准库已有。
// 换个我们自己的老类型补新协议的正例：
extension Meter: CustomStringConvertible {
    var description: String { "\(value)m" }
}
precondition(Meter(value: 3.5).description == "3.5m")
print("retroactive 补 description：\(Meter(value: 3.5))")

print("==== 15 结束 ====")
