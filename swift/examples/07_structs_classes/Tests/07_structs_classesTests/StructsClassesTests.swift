// 07_structs_classes 的 swift-testing 测试
import Testing

@testable import Ch07StructsClasses

@Test func 计算属性() {
    let size = Size(width: 3, height: 4)
    #expect(size.area == 12)
    #expect(Rect(origin: (x: 0, y: 0), size: Size(width: 10, height: 6)).center.x == 5)
    #expect(Rect(origin: (x: 1, y: 2), size: Size(width: 4, height: 8)).center == (x: 3, y: 6))
}

@Test func mutating修改自身() {
    var size = Size(width: 3, height: 4)
    size.scale(by: 2)
    #expect(size == Size(width: 6, height: 8))
}

@Test func 值语义拷贝互不影响() {
    var a = Size(width: 3, height: 4)
    let b = a
    a.scale(by: 3)
    #expect(b == Size(width: 3, height: 4))
    #expect(a.area == 108)  // 9 × 12（面积 = 面积 × 9，长宽各放大 3 倍）
    #expect(widenCopy(a).area == 1308)  // 宽 +100：(109)×12，原 a 不受影响
    #expect(a.area == 108)  // 原值未被函数篡改
}

@Test func 引用语义共享对象() {
    let counter = TicketCounter(location: "东门", remaining: 1)
    refill(counter, to: 5)
    #expect(counter.remaining == 5)
    #expect(counter.sold == 0)
}

@Test func 售票逻辑() {
    let counter = TicketCounter(location: "北门", remaining: 2)
    #expect(counter.sellOne())
    #expect(counter.sellOne())
    #expect(!counter.sellOne())  // 售罄
    #expect(counter.sold == 2)
}

@Test func 类型属性共享() {
    #expect(TicketCounter.price == 30)
}
