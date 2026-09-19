// 08_enums 的 swift-testing 测试
import Testing

@testable import Ch08Enums

@Test func 关联值面积() {
    #expect(area(of: .circle(radius: 1)) == Double.pi)
    #expect(area(of: .rect(width: 3, height: 4)) == 12)
    #expect(area(of: .point) == 0)
}

@Test func rawValue往返() {
    #expect(Planet.earth.rawValue == 3)
    #expect(Planet(rawValue: 4) == .mars)
    #expect(Planet(rawValue: 99) == nil)
    #expect(LogLevel.warning.rawValue == "warning")
}

@Test func rawValue附加属性() {
    #expect(Planet.mercury.moonCount == 0)
    #expect(Planet.earth.moonCount == 1)
    #expect(Planet.mars.moonCount == 2)
}

@Test func 递归枚举求值() {
    #expect(evaluate(.number(5)) == 5)
    #expect(evaluate(.add(.number(1), .number(2))) == 3)
    #expect(evaluate(.multiply(.add(.number(1), .number(2)), .add(.number(3), .number(4)))) == 21)
}

@Test func caseIterable遍历() {
    #expect(levelNames() == ["debug", "info", "warning", "error"])
    #expect(LogLevel.allCases.count == 4)
}

@Test func 关联值加where() {
    #expect(describeEvent(.connected) == "已连接")
    #expect(describeEvent(.received(bytes: 2048)) == "大块数据 2048B")
    #expect(describeEvent(.received(bytes: 128)) == "小数据 128B")
    #expect(describeEvent(.failed(code: 404)) == "资源不存在")
    #expect(describeEvent(.failed(code: 500)) == "错误码 500")
}
