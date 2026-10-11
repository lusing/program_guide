// 27_initializers_methods 的 swift-testing 测试
import Foundation
import Testing

@testable import Ch27InitializersMethods

@Test func 可失败构造器() {
    let ok = Fraction(numerator: 3, denominator: 4)
    #expect(ok?.decimal == 0.75)

    let zero = Fraction(numerator: 1, denominator: 0)
    #expect(zero == nil)

    let negative = Fraction(numerator: -1, denominator: 2)
    #expect(negative?.decimal == -0.5)
}

@Test func 必要构造器继承链() {
    let btn = IconButton(frame: (0, 0, 100, 40))
    #expect(btn.frame.w == 100)
    #expect(btn.label == "按钮")
    #expect(btn.icon == "star")
}

@Test func classFunc可重写staticFunc不可() {
    #expect(Shape.describe() == "一个形状")
    #expect(Circle.describe() == "一个圆")
    #expect(Shape.category == "几何")
    #expect(Circle.category == "圆形")
    #expect(Shape.unit() == "单位形状")
}

@Test func 构造器安全检查() {
    let safe = SafeChild(value: 10, extra: 5)
    #expect(safe.value == 20)   // super.init 之后被 ×2
    #expect(safe.extra == 5)

    let conv = SafeChild(defaultExtra: 5)
    #expect(conv.value == 20)
    #expect(conv.extra == 105)  // self.init 之后 +100
}

@Test func defer清理临时文件() {
    let path = NSTemporaryDirectory() + "swift-guide-27-test-check.txt"
    let url = URL(fileURLWithPath: path)
    try? "test".write(to: url, atomically: true, encoding: .utf8)
    #expect(FileManager.default.fileExists(atPath: path))

    // 模拟 defer 模式：读取后删除
    defer { try? FileManager.default.removeItem(at: url) }
    let content = try? String(contentsOf: url, encoding: .utf8)
    #expect(content == "test")
}

@Test func 闭包构造属性() {
    let proc = DataProcessor()
    #expect(proc.lookupTable.count == 4)
    #expect(proc.lookupTable["alpha"] == 10)
    #expect(proc.lookupTable["delta"] == 40)
    #expect(proc.factors == [2.0, 1.0, 0.5])
    #expect(proc.name == "处理器")
}
