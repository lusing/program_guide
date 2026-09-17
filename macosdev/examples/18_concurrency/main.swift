// ============================================================
// 18 - 并发：GCD、OperationQueue、主线程规则
//
// 编译：
//   swiftc -O -sdk $(xcrun --show-sdk-path) -target x86_64-apple-macos12.0 \
//          -module-name concurrency main.swift -o 18_concurrency \
//          -framework Foundation -framework AppKit
// 运行：
//   ./18_concurrency
//
// Cocoa 的第一条并发规则：**界面只能在主线程上动**。
// 后台线程改 NSView / NSTextStorage / 数组控制器，症状是随机崩溃或者画不出来，
// 而且崩的地方往往离真正的出错点很远。
//
// 本示例不启动 run loop，所以凡是「回到主线程」都用**同步等待**完成：
// 用信号量等后台任务结束，再在主线程上汇总结果 —— 这样输出是可复现的。
// ============================================================

import AppKit
import Foundation

var failures = 0
func expect(_ condition: Bool, _ description: String) {
    if condition {
        print("  ok   \(description)")
    } else {
        print("  FAIL \(description)")
        failures += 1
    }
}

// MARK: - 1) 线程基础

print("== 线程 ==")
expect(Thread.isMainThread, "程序开头就在主线程上")
expect(Thread.main == Thread.current, "Thread.main 就是当前线程")
print("  主线程 name = \(Thread.main.name ?? "未命名")")
expect(Thread.current.stackSize > 0, "线程有栈（实际 \(Thread.current.stackSize) 字节）")

var onBackground = false
let semaphore = DispatchSemaphore(value: 0)
DispatchQueue.global(qos: .userInitiated).async {
    onBackground = Thread.isMainThread
    semaphore.signal()
}
_ = semaphore.wait(timeout: .now() + 5)
expect(onBackground == false, "派发到全局队列后就不在主线程了")

// 主线程上跑的活儿：Thread.perform(onMainThread:) 需要 run loop，
// 自测里没有，所以这里只用 DispatchQueue.main 的**描述信息**做验证
expect(DispatchQueue.main.label == "com.apple.main-thread", "主队列有固定的 label")

// MARK: - 2) 串行队列保证顺序

print("")
print("== 串行队列 ==")
let serial = DispatchQueue(label: "dev.macosdev.serial")
var order: [Int] = []
for i in 0..<5 {
    serial.async { order.append(i) }
}
// 等所有任务跑完：往同一个串行队列里塞一个同步任务，
// 它执行时说明前面排队的都已经结束了
serial.sync {}
expect(order == [0, 1, 2, 3, 4], "串行队列按入队顺序执行（实际 \(order)）")

// MARK: - 3) 并行：concurrentPerform

print("")
print("== 并行循环 ==")
let iterations = 8
var slots = [Int](repeating: -1, count: iterations)
DispatchQueue.concurrentPerform(iterations: iterations) { index in
    // 每个下标只被一个迭代写，不需要加锁 —— 这是并行循环的常见写法
    slots[index] = index * index
}
print("  slots = \(slots)")
expect(slots == [0, 1, 4, 9, 16, 25, 36, 49], "八次迭代都跑到了（实际 \(slots)）")
expect(slots.allSatisfy { $0 >= 0 }, "没有遗漏")

// MARK: - 4) 共享计数要加锁

print("")
print("== 共享状态 ==")
// 多线程同时改一个变量，不加保护就会丢更新。用 NSLock 是最朴素的解法。
let lock = NSLock()
var unsafe = 0
var safe = 0
let rounds = 2000
DispatchQueue.concurrentPerform(iterations: rounds) { _ in
    unsafe += 1
    lock.lock()
    safe += 1
    lock.unlock()
}
// 坑：无保护那个计数**一个字节都不能打出来** —— 它每次运行都不一样
// （本机实测：1987、1966，甚至偶尔正好 2000）。
// 一开始我改打印「是否丢了更新」这个布尔值，结果它同样不稳定
// （两条通道跑出来一个是 true 一个是 false），照样挂。
// 结论：任何依赖竞态的结果都别进输出，只留在断言里。
print("  加锁 = \(safe)（应等于 \(rounds)）")
expect(safe == rounds, "加锁的计数一次没丢")
// 无保护的那个通常小于 rounds，但也可能偶然等于 —— 只断言「不大于」
expect(unsafe <= rounds, "无保护的计数不会超过总次数")
// 顺带说明：这就是「偶发 bug」的来源 —— 同样的代码跑十次结果可能不一样。
// 想证明并发真的在跑，数**线程 id** 而不是比墙钟时间。

// MARK: - 5) DispatchGroup

print("")
print("== DispatchGroup ==")
let group = DispatchGroup()
let groupQueue = DispatchQueue(label: "dev.macosdev.group", attributes: .concurrent)
var results = [Int](repeating: 0, count: 3)
for i in 0..<3 {
    group.enter()
    groupQueue.async {
        results[i] = (i + 1) * 10
        group.leave()
    }
}
let waited = group.wait(timeout: .now() + 5)
print("  wait = \(waited), results = \(results)")
expect(waited == .success, "等待在超时前完成")
expect(results == [10, 20, 30], "三个任务的结果都到位了（实际 \(results)）")

// MARK: - 6) OperationQueue 与依赖

print("")
print("== OperationQueue ==")
let opQueue = OperationQueue()
opQueue.maxConcurrentOperationCount = 2
expect(opQueue.maxConcurrentOperationCount == 2, "最多两个并发")

var trace: [String] = []
let traceLock = NSLock()
let first = BlockOperation {
    traceLock.lock(); trace.append("下载"); traceLock.unlock()
}
let second = BlockOperation {
    traceLock.lock(); trace.append("解析"); traceLock.unlock()
}
let third = BlockOperation {
    traceLock.lock(); trace.append("入库"); traceLock.unlock()
}
// 依赖决定顺序：解析要等下载，入库要等解析
second.addDependency(first)
third.addDependency(second)
opQueue.addOperations([third, first, second], waitUntilFinished: true)
print("  执行顺序 = \(trace.joined(separator: " → "))")
expect(trace == ["下载", "解析", "入库"], "依赖保证了顺序（实际 \(trace)）")

// 取消：已经开始的取消不了，没开始的会被跳过
let cancelQueue = OperationQueue()
cancelQueue.isSuspended = true
let cancelled = BlockOperation { }
cancelQueue.addOperation(cancelled)
cancelled.cancel()
expect(cancelled.isCancelled, "操作可以被取消")
cancelQueue.isSuspended = false
cancelQueue.waitUntilAllOperationsAreFinished()

// MARK: - 7) 主线程规则

print("")
print("== 主线程规则 ==")
// 后台算完，回到主线程更新界面 —— 这是 Cocoa 里最常见的并发结构：
//
//   DispatchQueue.global().async {
//       let result = heavyWork()
//       DispatchQueue.main.async { self.label.stringValue = result }
//   }
//
// 自测里没有 run loop，DispatchQueue.main.async 不会被执行，
// 所以这里只验证「工作确实发生在后台、结果确实被带回来」，
// 真正的 UI 更新交给第 02 章那种 run loop 示例。
let workSemaphore = DispatchSemaphore(value: 0)
var computed = 0
DispatchQueue.global().async {
    computed = (1...100).reduce(0, +)
    workSemaphore.signal()
}
_ = workSemaphore.wait(timeout: .now() + 5)
expect(computed == 5050, "后台算完的结果正确（实际 \(computed)）")
expect(Thread.isMainThread, "等完之后回到主线程了")

// Timer 需要 run loop，自测里不能用；用 DispatchQueue.asyncAfter 做延时
let delaySemaphore = DispatchSemaphore(value: 0)
var fired = false
DispatchQueue.global().asyncAfter(deadline: .now() + 0.05) {
    fired = true
    delaySemaphore.signal()
}
_ = delaySemaphore.wait(timeout: .now() + 5)
expect(fired, "asyncAfter 的延时任务会执行")

print("==== 18 结束 ====")
exit(failures == 0 ? 0 : 1)
