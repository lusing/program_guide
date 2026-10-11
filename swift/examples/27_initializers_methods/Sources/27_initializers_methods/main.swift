// 27 · 构造器高级主题——可失败构造器、必要构造器、class func vs static func、
//    defer、构造器安全性检查、闭包属性构造

import Foundation

// ═══ 27.1 可失败构造器 init?：参数不合法就返回 nil
// 场景：用字符串构造 URL / 用数字构造分数——输入可能不合法，构造可能失败
struct Fraction {
    let numerator: Int
    let denominator: Int

    // 分母为 0 → 构造失败
    init?(numerator: Int, denominator: Int) {
        guard denominator != 0 else { return nil }
        self.numerator = numerator
        self.denominator = denominator
    }

    var decimal: Double {
        Double(numerator) / Double(denominator)
    }
}

if let half = Fraction(numerator: 1, denominator: 2) {
    print("1/2 = \(half.decimal)")
} else {
    print("构造失败")
}
precondition(Fraction(numerator: 1, denominator: 2)?.decimal == 0.5)

// 分母为 0 → nil
let bad = Fraction(numerator: 1, denominator: 0)
print("分母为 0 → \(String(describing: bad))（nil）")
precondition(bad == nil)

// init!（隐式解包可失败构造器）：构造成功是非可选值，失败则崩溃——新代码少用
struct ImplicitID {
    let raw: String
    init!(raw: String) {
        guard !raw.isEmpty else { return nil }
        self.raw = raw
    }
}
let okID = ImplicitID(raw: "ABC123")   // ImplicitID!（隐式解包可选）
print("init! 成功：\(okID!.raw)")         // 实际仍带 !，失败即崩——新代码用 init? 更稳
// let badID = ImplicitID(raw: "")     // ❌ 运行期崩溃

// ═══ 27.2 必要构造器 required init：子类必须实现（继承或重写）
class BaseView {
    let frame: (x: Double, y: Double, w: Double, h: Double)

    required init(frame: (x: Double, y: Double, w: Double, h: Double)) {
        self.frame = frame
    }
}

class Button: BaseView {
    var label: String

    // 子类必须实现 required init（继承或重写均可）
    required init(frame: (x: Double, y: Double, w: Double, h: Double)) {
        self.label = "按钮"
        super.init(frame: frame)
    }
}

class IconButton: Button {
    var icon: String

    // 再子类也要实现——required 是"每一级子类都必须可见"的契约
    required init(frame: (x: Double, y: Double, w: Double, h: Double)) {
        self.icon = "star"
        super.init(frame: frame)
    }
}

let btn = IconButton(frame: (0, 0, 100, 40))
print("IconButton frame=\(btn.frame) label=\(btn.label) icon=\(btn.icon)")
precondition(btn.frame.w == 100 && btn.icon == "star")

// ═══ 27.3 class func vs static func：能否被子类重写
class Shape {
    var name: String

    init(name: String) { self.name = name }

    // class func：子类可以 override
    class func describe() -> String {
        "一个形状"
    }

    // static func：子类不能 override（等价 final class func）
    static func unit() -> String {
        "单位形状"
    }

    // class 计算属性同理：子类可 override
    class var category: String { "几何" }

    // static 计算属性：子类不可 override
    static var version: String { "1.0" }
}

class Circle: Shape {
    var radius: Double = 1.0

    // ✅ 可以重写 class func
    override class func describe() -> String {
        "一个圆"
    }

    // ✅ 可以重写 class 计算属性
    override class var category: String { "圆形" }

    // ❌ 编译错误：static 方法不能重写
    // override static func unit() -> String { "单位圆" }
}

print("Shape.describe() = \(Shape.describe())")
print("Circle.describe() = \(Circle.describe())")
print("Shape.category = \(Shape.category)，Circle.category = \(Circle.category)")
print("Shape.unit() = \(Shape.unit())（static，不可重写）")
precondition(Shape.describe() == "一个形状")
precondition(Circle.describe() == "一个圆")
precondition(Circle.category == "圆形")

// 结构体没有继承，static 就是 static——没有 class func 一说
struct Point {
    var x = 0.0, y = 0.0
    static func origin() -> Point { Point(x: 0, y: 0) }
}
print("Point.origin() = (\(Point.origin().x), \(Point.origin().y))")

// ═══ 27.4 构造器的四项安全检查（编译器强制，不是建议）
// 检查1：指定构造器必须先初始化本类所有存储属性，才能调 super.init
// 检查2：子类要改继承来的属性，必须在 super.init 之后
// 检查3：便利构造器要改属性，必须在 self.init 之后
// 检查4：super.init / self.init 之前不能用 self 调属性或方法

class SafeBase {
    var value: Int

    init(value: Int) {
        // 检查1：value 先初始化
        self.value = value
        // 现在才能安全使用 self.value
        print("SafeBase 构造完成：value=\(self.value)")
    }
}

class SafeChild: SafeBase {
    var extra: Int

    init(value: Int, extra: Int) {
        // 检查1：先初始化本类属性
        self.extra = extra
        // 检查2：super.init 之后才能改继承来的属性
        super.init(value: value)
        self.value = value * 2   // ✅ super.init 之后了
    }

    // 检查3：便利构造器必须在 self.init 之后改属性
    convenience init(defaultExtra: Int) {
        self.init(value: 10, extra: defaultExtra)
        self.extra = defaultExtra + 100   // ✅ self.init 之后了
    }

    // 检查4：super.init 之前不能调 self 的方法
    // init(bad: Int) {
    //     self.doSomething()          // ❌ 编译错误：self 还没构造完
    //     super.init(value: bad)
    //     self.extra = 0
    // }

    func doSomething() { print("extra=\(extra)") }
}

let safe = SafeChild(defaultExtra: 5)
print("SafeChild: value=\(safe.value) extra=\(safe.extra)")
precondition(safe.value == 20 && safe.extra == 105)

// ═══ 27.5 defer：函数退出前必执行的清理块
// 无论 return / break / throw / 正常结束，defer 块都会执行
func demoDefer(flag: Bool) -> String {
    defer { print("  defer：清理资源（总会执行）") }
    if flag {
        print("  提前 return")
        return "提前返回"
    }
    print("  正常走完")
    return "正常结束"
}
print("demoDefer(flag: true):")
_ = demoDefer(flag: true)
print("demoDefer(flag: false):")
_ = demoDefer(flag: false)

// 多个 defer：后写的先执行（栈式）
func multiDefer() {
    defer { print("  defer 1（先写）") }
    defer { print("  defer 2（后写，先执行）") }
    print("  函数体")
}
print("multiDefer():")
multiDefer()

// 实用场景：文件/锁/临时资源的清理
func readTempFile() -> String {
    let path = NSTemporaryDirectory() + "swift-guide-27-demo.txt"
    let url = URL(fileURLWithPath: path)
    try? "hello defer".write(to: url, atomically: true, encoding: .utf8)

    guard let data = try? Data(contentsOf: url) else { return "" }
    // defer 保证无论后面怎么走，临时文件都会被删掉
    defer { try? FileManager.default.removeItem(at: url) }
    return String(data: data, encoding: .utf8) ?? ""
}
print("readTempFile → \(readTempFile())")
precondition(readTempFile() == "hello defer")

// ═══ 27.6 闭包构造属性：复杂初始化的"一次性函数"
// 属性 = 闭包() —— 闭包执行一次，结果存进属性；漏掉 () 就变成计算属性了
class DataProcessor {
    // 简单默认值
    var name = "处理器"

    // 复杂初始化：多行逻辑 → 用闭包包起来，末尾的 () 立即执行
    let lookupTable: [String: Int] = {
        var table: [String: Int] = [:]
        for (i, key) in ["alpha", "beta", "gamma", "delta"].enumerated() {
            table[key] = (i + 1) * 10
        }
        print("  闭包构造 lookupTable：\(table.count) 项")
        return table
    }()  // ← 这个小括号是关键：没有它就是个只读计算属性

    // 带参数标签的闭包构造（显式标注类型，闭包参数可省）
    let factors: [Double] = [1.0, 0.5, 0.25].map { $0 * 2 }
}

let proc = DataProcessor()
print("lookupTable = \(proc.lookupTable)")
print("factors = \(proc.factors)")
precondition(proc.lookupTable["beta"] == 20)
precondition(proc.factors == [2.0, 1.0, 0.5])

print("==== 27 结束 ====")
