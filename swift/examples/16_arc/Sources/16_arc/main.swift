// 16 · ARC 与内存——引用计数、循环引用、weak/unowned、捕获列表、COW、独占检查

import Foundation

// ═══ 16.1 纯函数区（供测试）
class Node {
    let name: String
    var next: Node?  // 强引用——循环引用的"引线"

    init(name: String) {
        self.name = name
    }

    deinit {
        print("  [deinit] \(name) 释放")
    }
}

class WeakNode {
    let name: String
    weak var next: WeakNode?  // weak：不增加引用计数，自动归 nil

    init(name: String) {
        self.name = name
    }

    deinit {
        print("  [deinit] \(name) 释放")
    }
}

/// 侦测"对象还活着吗"的探针（weak 引用归 nil = 对象已释放）
class LeakProbe<T: AnyObject> {
    weak var target: T?
    init(_ target: T) { self.target = target }
    var isAlive: Bool { target != nil }
}

func makeCycle() {
    let a = Node(name: "A")
    let b = Node(name: "B")
    a.next = b
    b.next = a  // 循环达成：A ↔ B，引用计数永不归零
}

func makeBrokenCycle() {
    let a = WeakNode(name: "A'")
    let b = WeakNode(name: "B'")
    a.next = b
    b.next = a  // weak 循环：不持所有权，退出作用域正常释放
}

/// 闭包捕获 self 的两种姿势：强引用 vs [weak self] 快照
class ViewModel {
    let title = "VM"
    var handlers: [() -> String] = []

    deinit {
        print("  [deinit] ViewModel 释放")
    }

    func storeStrong() {
        handlers.append { "强引用 \(self.title)" }  // 闭包持有 self → 循环
    }

    func storeWeak() {
        handlers.append { [weak self] in "弱引用 \(self?.title ?? "已释放")" }
    }
}

func makeHandlerHoldingVM() -> (() -> String)? {
    let vm = ViewModel()
    vm.storeStrong()  // 闭包持有 vm
    vm.storeWeak()
    return vm.handlers.first  // 返回闭包 → vm 被 hold，deinit 不跑（循环）
}

func makeHandlerNotHoldingVM() -> (() -> String)? {
    let vm = ViewModel()
    vm.storeWeak()  // 只有 [weak self] 版本
    return vm.handlers.first  // 闭包不持有 vm → deinit 立即跑
}

/// COW：值类型的拷贝时机
func cowProbe() -> (copied: Bool, original: Int) {
    var box = [1, 2, 3]
    let alias = box  // 共享缓冲
    box.append(4)  // 触发复制（引用计数 > 1 且要写）
    return (alias.count != box.count, alias.count)
}

// ═══ 16.2 循环引用实测：deinit 不跑 = 泄漏
print("① 强引用循环（泄漏）：")
makeCycle()  // 注意控制台：没有 [deinit] A/B——两个对象都没释放！
print("  （上面没有任何 [deinit] 输出——A、B 泄漏了）")

print("② weak 打破循环：")
makeBrokenCycle()  // [deinit] A'/B' 都会出现

// ═══ 16.3 LeakProbe：确定性验证"断开强引用 → 立即释放"
final class Session {
    let id = 1
}

func makeSessionAndProbe() -> (Session, LeakProbe<Session>) {
    let session = Session()
    return (session, LeakProbe(session))
}

var (session, probe): (Session?, LeakProbe<Session>) = makeSessionAndProbe()
precondition(probe.isAlive)
print("③ 探针活着：\(probe.isAlive)")
session = nil  // 断开最后一个强引用 → ARC 立即回收
precondition(!probe.isAlive)  // weak 引用自动归 nil——释放是确定性的
print("④ session = nil 后探针存活：\(probe.isAlive)（ARC 确定性回收，非 GC）")

// ═══ 16.4 闭包捕获 self：强 vs 弱
print("⑤ 闭包持有 ViewModel：")
if let handler = makeHandlerHoldingVM() {
    print("  调用：\(handler())")
    print("  （ViewModel 的 deinit 没跑——闭包还攥着它）")
}
print("⑥ 只有 [weak self] 时：")
if let handler = makeHandlerNotHoldingVM() {
    print("  调用：\(handler())")  // "已释放"——weak 自动归 nil
}

// ═══ 16.5 COW：拷贝发生在"写"的那一刻
let cow = cowProbe()
print("⑦ COW：复制了=\(cow.copied)，alias 计数=\(cow.original)")
precondition(cow.copied && cow.original == 3)

print("==== 16 结束 ====")
