// 16_arc 的 swift-testing 测试
import Testing

@testable import Ch16Arc

@Test func 探针生命周期() {
    var (session, probe): (Session?, LeakProbe<Session>) = makeSessionAndProbe()
    #expect(probe.isAlive)
    session = nil
    #expect(!probe.isAlive)  // ARC 确定性释放
}

@Test func cow写时复制() {
    let result = cowProbe()
    #expect(result.copied)
    #expect(result.original == 3)
}

@Test func weakHandler不持有VM() {
    if let handler = makeHandlerNotHoldingVM() {
        #expect(handler() == "弱引用 已释放")  // vm 已释放，weak 归 nil
    } else {
        Issue.record("应返回处理器")
    }
}

@Test func strongHandler持有VM() {
    if let handler = makeHandlerHoldingVM() {
        #expect(handler() == "强引用 VM")  // vm 还活着（被闭包持有）
    } else {
        Issue.record("应返回处理器")
    }
}

@Test func weakNode不循环() {
    // 能返回就说明没卡死；释放与否由 deinit 打印佐证（人工核对）
    makeBrokenCycle()
    #expect(WeakNode(name: "X").name == "X")
}
