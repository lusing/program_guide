// 02_hello 的 swift-testing 冒烟测试（正文 Task 2 完善）
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
