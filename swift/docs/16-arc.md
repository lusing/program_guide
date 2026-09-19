# 16 · ARC 与内存

> 对应示例：`examples/16_arc/`

## 16.1 ARC：编译期插入的引用计数

Swift 的 class 实例靠 **ARC**（Automatic Reference Counting）管理生命周期：每次强
引用 +1、断开 -1，**归零立即析构**（deinit 同步执行）。与 GC（垃圾回收）的根本差异：

| | ARC（Swift/Rust rc） | GC（Java/C#/Go） |
|---|---|---|
| 回收时机 | 引用计数归零，**确定性** | 某次 GC 轮到它，**非确定** |
| 开销位置 | 每次引用赋值插计数指令 | 后台线程停顿/并发扫描 |
| 循环引用 | **会泄漏**（计数不归零） | 可回收（ tracing 从根可达性判） |
| 析构钩子 | deinit，时机精确 | finalizer，时机玄学，别用 |

```swift
var (session, probe): (Session?, LeakProbe<Session>) = makeSessionAndProbe()
probe.isAlive        // true
session = nil        // 断开最后一个强引用
probe.isAlive        // false —— ARC 立即回收（weak 引用自动归 nil）
```

示例的 `LeakProbe` 是"泄漏探针"：持 weak 引用观察对象——deinit 没跑 = 泄漏，
这是排查 Swift 内存问题的第一工具（Instruments/堆快照之外的代码级手法）。

**ARC 只管 class**：struct/enum 值语义无引用计数（内嵌的 class 成员照常计数）。

## 16.2 循环引用：ARC 的阿喀琉斯之踵

```swift
class Node {
    var next: Node?
    deinit { print("  [deinit] \(name) 释放") }
}

func makeCycle() {
    let a = Node(name: "A")
    let b = Node(name: "B")
    a.next = b     // A → B：b 计数 2
    b.next = a     // B → A：a 计数 2
}   // 局部变量断开，但 a↔b 互数 +1 —— 计数永不为零 → deinit 不跑（泄漏！）
```

示例实测：`makeCycle()` 执行后控制台**没有**任何 `[deinit]`——两个对象泄漏了。
循环的三种高发形态：

1. **对象互指**：双向链表、父子（parent ↔ child）；
2. **闭包捕获 self**：`self.handlers.append { ... self ... }`——闭包持有 self、self 持有
   闭包数组（示例 ViewModel）；
3. **NotificationCenter / KVO / delegate** 时代的强引用回调。

## 16.3 weak 与 unowned：打破循环的两把钥匙

```swift
class WeakNode {
    weak var next: WeakNode?   // weak：不增加计数，对象释放时自动归 nil
}

handlers.append { [weak self] in "弱引用 \(self?.title ?? "已释放")" }  // 捕获列表
```

- **weak**：引用不计数；对象释放后引用自动变 nil——所以 **weak 必须是 Optional**。
  生命周期错开的场景（delegate、闭包捕获 self）的默认选择。
- **unowned**：引用不计数但**非可选**——访问已释放对象 = 崩溃。只用于"保证同生共死"
  的场景（闭包与 self 生命周期一致、credit card ↔ customer）。拿不准就用 weak。

**捕获列表** `[weak self]` 是 11 章捕获语法的续集：把"引用捕获"改写为"弱引用捕获 +
Optional self"。闭包体内 `self?.xxx` 或先 `guard let self`（5.7 起支持解包 self）。

## 16.4 COW：值类型的"伪拷贝"

```swift
var box = [1, 2, 3]
let alias = box       // O(1)：只共享缓冲 + 计数
box.append(4)         // 写操作发现计数 > 1 → 此刻才复制（copy-on-write）
alias                 // [1, 2, 3] —— 仍是旧缓冲
```

容器（Array/String/Dictionary/Set）的赋值是 O(1) 的缓冲共享，**写时才复制**——
07 章说过结论，这里的机制是 `isKnownUniquelyReferenced`：写操作前查缓冲计数，>1 就
先复制再写。两个推论：

- "inout 传大数组 + 只读"很便宜；真要修改也是单次 O(n) 而非处处 O(n)；
- 自定义 struct **没有**自动 COW——想让"大缓冲 struct"享受同样待遇，手写
  `isKnownUniquelyReferenced` 检查（进阶话题，知道思路即可）。

## 16.5 内存独占（Exclusivity）：并发的序曲

Swift 保证：**同一变量的读改写互斥**——`a += 1` 执行期间不允许另一处访问 `a`
（编译器在 -Onone 下插入动态检查，越界即 trap）。两个实战体现：

- inout 参数独占：`f(&a, &a)` 编译错误（05 章）；
- actor 出场前的最后一课：**共享可变状态是万恶之源**——下一章把状态锁进隔离域。

## 16.6 坑位清单（含实测）

1. **`precondition` 不吃 `try` / `await`**（16/17/20 章连环实测）：precondition 的
   条件是 @autoclosure（非抛错非异步）——先 `let x = try/await ...` 求值，再
   `precondition(x == ...)` 断言。
2. **元组解构赋 nil 要显式可选类型**（实测）：`var (s, p) = makePair()` 得到非可选
   `s`；`s = nil` 编译错误——`var (s, p): (Session?, Probe)` 写明。
3. **guard 之后不是单表达式体**：隐式返回只对"整个函数体一个表达式"生效，
   guard + 表达式的组合必须写 `return`（18 章 average 实测报 missing return）。
4. **deinit 是"是否泄漏"的探针**：测试里建 weak 探针断言 `isAlive == false`，
   比肉眼盯控制台可靠（示例 LeakProbe 的存在意义）。
5. **unowned 崩溃没商量**：访问已释放对象 = 未定义行为级崩溃且栈信息少——
   能 weak 就 weak，unowned 只在能证明同生共死时用。
6. **闭包捕获 self 的两种写法取舍**：`[weak self]` + `guard let self`（需要早期退出）
   vs `self?.xxx`（一行调用）。大闭包用前者，可读性完胜。

上一章：[15 · 扩展与下标](15-extensions.md) ｜ 下一章：[17 · 并发 I](17-concurrency.md) ｜ 返回：[README](../README.md)
