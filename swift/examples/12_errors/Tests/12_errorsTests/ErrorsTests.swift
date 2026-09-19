// 12_errors 的 swift-testing 测试
import Testing

@testable import Ch12Errors

@Test func 正常购买找零() throws {
    var machine = VendingMachine()
    let change = try machine.vend("可乐", with: 5)
    #expect(change == 2)
    #expect(machine.stock["可乐"] == 1)
}

@Test func 缺货与钱不够() {
    var machine = VendingMachine()
    #expect(throws: VendingError.outOfStock(item: "薯片")) {
        try machine.vend("薯片", with: 10)
    }
    #expect(throws: VendingError.insufficientFunds(needed: 3, given: 1)) {
        try machine.vend("可乐", with: 1)
    }
}

@Test func result描述() {
    var machine = VendingMachine()
    #expect(describe(vending: vendResult(&machine, item: "可乐", money: 5)) == "成功，找零 2 元")
    #expect(describe(vending: vendResult(&machine, item: "可乐", money: 1)) == "钱不够：要 3 有 1")
}

@Test func typedThrows() throws {
    #expect(try parseScore("88") == 88)
    #expect(try parseScore("100") == 100)
    #expect(throws: ScoreError.invalid(text: "abc")) { try parseScore("abc") }
    #expect(throws: ScoreError.invalid(text: "101")) { try parseScore("101") }
}

@Test func try可选化() {
    #expect(safeScore("42") == 42)
    #expect(safeScore("-1") == nil)
    #expect(safeScore("abc") == nil)
}

@Test func rethrows透传() throws {
    #expect(try transformAll(["1", "2"], { try parseScore($0) }) == [1, 2])
    #expect((try? transformAll(["1", "x"], { try parseScore($0) })) == nil)  // try? 要括号再比 nil
    #expect(transformAll(["3"], { Int($0)! }) == [3])  // 不抛错的闭包 → 调用不带 try
}

@Test func 错误分层() {
    #expect(mustBePositive(5) == 5)
}
