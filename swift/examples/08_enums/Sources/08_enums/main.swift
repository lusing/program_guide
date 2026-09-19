// 08 · 枚举——关联值、raw value、indirect、模式匹配、代数数据类型思维

import Foundation

// ═══ 8.1 纯函数区（供测试）
// 关联值：枚举成员可携带载荷——Swift 枚举是"代数数据类型"
enum Shape {
    case circle(radius: Double)
    case rect(width: Double, height: Double)
    case point
}

func area(of shape: Shape) -> Double {
    switch shape {
    case .circle(let r): return .pi * r * r
    case .rect(let w, let h): return w * h
    case .point: return 0
    }
}

// raw value：成员绑定底层值（Int/String/Character 自动递增）
enum Planet: Int {
    case mercury = 1
    case venus, earth, mars
    var moonCount: Int {
        switch self {
        case .mercury, .venus: return 0
        case .earth: return 1
        case .mars: return 2
        }
    }
}

// String raw value 自动取成员名；CaseIterable 提供遍历能力
enum LogLevel: String, CaseIterable {
    case debug, info, warning, error

    var emoji: String {
        switch self {
        case .debug: return "🌱"
        case .info: return "ℹ️"
        case .warning: return "⚠️"
        case .error: return "❌"
        }
    }
}

// indirect：递归枚举（成员类型引用自身）
indirect enum Expr {
    case number(Double)
    case add(Expr, Expr)
    case multiply(Expr, Expr)
}

func evaluate(_ expr: Expr) -> Double {
    switch expr {
    case .number(let v): return v
    case .add(let l, let r): return evaluate(l) + evaluate(r)
    case .multiply(let l, let r): return evaluate(l) * evaluate(r)
    }
}

// CaseIterable：自动获得 allCases
func levelNames() -> [String] {
    LogLevel.allCases.map(\.rawValue)
}

// 关联值 + where 的组合匹配
enum NetworkEvent {
    case connected
    case received(bytes: Int)
    case failed(code: Int)
}

func describeEvent(_ event: NetworkEvent) -> String {
    switch event {
    case .connected: return "已连接"
    case .received(let bytes) where bytes > 1024: return "大块数据 \(bytes)B"
    case .received(let bytes): return "小数据 \(bytes)B"
    case .failed(let code) where code == 404: return "资源不存在"
    case .failed(let code): return "错误码 \(code)"
    }
}

// ═══ 8.2 关联值：一份数据多种形态
let shapes: [Shape] = [.circle(radius: 1), .rect(width: 3, height: 4), .point]
for shape in shapes {
    print("面积 \(area(of: shape))")
}
precondition(area(of: shapes[0]) == .pi)

// ═══ 8.3 raw value：底层值与自动递增
print("地球是第 \(Planet.earth.rawValue) 颗行星，卫星 \(Planet.earth.moonCount) 颗")
if let mars = Planet(rawValue: 4) { print("rawValue 4 = \(mars)") }
precondition(Planet(rawValue: 99) == nil)
print("日志级别：\(levelNames())")
for level in LogLevel.allCases {
    print("  \(level.emoji) \(level.rawValue)", terminator: "")
}
print("")

// ═══ 8.4 indirect：用枚举写表达式树并求值
// (1 + 2) × (3 + 4) = 21
let expr = Expr.multiply(.add(.number(1), .number(2)), .add(.number(3), .number(4)))
print("(1+2)×(3+4) = \(evaluate(expr))")
precondition(evaluate(expr) == 21)

// ═══ 8.5 关联值 + where
print(describeEvent(NetworkEvent.connected))
print(describeEvent(NetworkEvent.received(bytes: 2048)))
print(describeEvent(NetworkEvent.received(bytes: 128)))
print(describeEvent(NetworkEvent.failed(code: 404)))
print(describeEvent(NetworkEvent.failed(code: 500)))

print("==== 08 结束 ====")
