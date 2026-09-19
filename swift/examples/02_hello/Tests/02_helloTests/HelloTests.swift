// 02_hello 的 swift-testing 测试
import Testing

@testable import Ch02Hello

@Test func add两个整数() {
    #expect(add(2, 3) == 5)
    #expect(add(-1, 1) == 0)
    #expect(add(0, 0) == 0)
}

@Test func greet包含名字() {
    let message = greet("世界")
    #expect(message == "你好，世界！")
    #expect(message.contains("世界"))
}

@Test func farewell是多行字符串() {
    let text = farewell("世界")
    #expect(text.hasPrefix("再见，世界。"))
    #expect(text.hasSuffix("欢迎回来。"))
    #expect(text.contains("\n"))
}
