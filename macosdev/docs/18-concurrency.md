# 18 · 并发：GCD、OperationQueue 与主线程规则

> 示例：`examples/18_concurrency/main.swift`
> 实测输出见 `build/18_concurrency/stdout.clt.txt`

macOS 上的并发和 iOS 一样用 GCD，但有个额外的大前提：
**所有 UI 操作必须在主线程**，而且 macOS 的窗口系统对「非主线程碰 view」
比 iOS 更不容忍。

## 1) 线程基础

```swift
Thread.isMainThread            // true
Thread.main == Thread.current
Thread.current.stackSize       // 524288
DispatchQueue.main.label       // "com.apple.main-thread"
```

实测：

```
== 线程 ==
  ok   程序开头就在主线程上
  ok   Thread.main 就是当前线程
  主线程 name = 
  ok   线程有栈（实际 524288 字节）
  ok   派发到全局队列后就不在主线程了
  ok   主队列有固定的 label
```

> **坑**：主线程默认**没有 name**。`Thread.main.name` 是 nil，
> 别拿它做断言。要设自己设。

## 2) 串行队列保证顺序

```swift
let serial = DispatchQueue(label: "dev.macosdev.serial")
for i in 0..<5 { serial.async { order.append(i) } }

// 等所有任务跑完：往同一个串行队列里塞一个同步任务
serial.sync {}
```

`serial.sync {}` 执行时说明前面排队的都已经结束 ——
这是**不引入额外同步原语**就能等一个串行队列排空的技巧。

实测：

```
== 串行队列 ==
  ok   串行队列按入队顺序执行（实际 [0, 1, 2, 3, 4]）
```

> **坑**：`DispatchQueue(label:)` 默认是**串行**的。
> 想要并发要显式给 `.concurrent`：
> `DispatchQueue(label: "x", attributes: .concurrent)`。
> iOS/macOS 上「我建了个队列但它不并发」几乎都是忘了这个。

## 3) 并行循环：concurrentPerform

```swift
var slots = [Int](repeating: -1, count: 8)
DispatchQueue.concurrentPerform(iterations: 8) { index in
    slots[index] = index * index      // 每个下标只被一个迭代写 → 不用加锁
}
```

实测：

```
== 并行循环 ==
  slots = [0, 1, 4, 9, 16, 25, 36, 49]
  ok   八次迭代都跑到了（实际 [0, 1, 4, 9, 16, 25, 36, 49]）
  ok   没有遗漏
```

`concurrentPerform` 是**同步**的（会阻塞当前线程直到全部完成），
系统按 CPU 核数自己决定开多少线程。适合「CPU 密集 + 可以按下标切分」的活。

并行循环的正确写法是**按下标写不同的位置**（不共享），
实在要汇总就加锁或用 `DispatchQueue.concurrentPerform` 之外的方案。

## 4) 共享状态：加锁

```swift
let lock = NSLock()
var unsafe = 0
var safe = 0
DispatchQueue.concurrentPerform(iterations: 2000) { _ in
    unsafe += 1
    lock.lock(); safe += 1; lock.unlock()
}
```

实测：

```
== 共享状态 ==
  加锁 = 2000（应等于 2000）
  ok   加锁的计数一次没丢
  ok   无保护的计数不会超过总次数
```

> **坑**：无保护那个计数**一个字节都不能打出来**。
> 它每次运行都不一样（本机实测：1987、1966，偶尔还正好 2000）。
>
> **坑（更隐蔽）**：改成打印「是否丢了更新」这个**布尔值**也不行 ——
> 它同样依赖竞态，实测两条工具链跑出来一个是 `true` 一个是 `false`，
> 「逐字节一致」照样挂。最后示例只打印加锁那个确定等于 2000 的值。
>
> 结论：**任何依赖竞态的结果都别进输出**，只留在断言里（断言也不依赖它的具体值）。

其他锁的选择：

| 场景 | 用什么 |
| --- | --- |
| 普通临界区 | `NSLock` |
| 递归调用 | `NSRecursiveLock` |
| 读多写少 | `pthread_rwlock` 或 `DispatchQueue` + `.barrier` |
| 只想做原子计数 | `OSAtomic`（已废弃）→ 用 `DispatchQueue` 或 `os_unfair_lock` |
| Swift 5.5+ | `actor` |

## 5) DispatchGroup

等一组异步任务全部完成：

```swift
let group = DispatchGroup()
var results: [Int] = []
for i in 1...3 {
    queue.async(group: group) {
        results.append(i * 10)
    }
}
let result = group.wait(timeout: .now() + 5)     // .success / .timedOut
```

实测：

```
== DispatchGroup ==
  wait = success, results = [10, 20, 30]
  ok   等待在超时前完成
  ok   三个任务的结果都到位了（实际 [10, 20, 30]）
```

`wait` 是**阻塞**的。不想阻塞用 `group.notify(queue:)`。

> **坑**：`results.append` 在多个线程里跑仍然是数据竞争。
> 示例里能工作是因为任务很短且串行队列；正式代码要给汇总加保护。

## 6) OperationQueue

比 GCD 高一层，有**依赖**和**取消**：

```swift
let queue = OperationQueue()
queue.maxConcurrentOperationCount = 2

let download = BlockOperation { ... }
let parse    = BlockOperation { ... }
let store    = BlockOperation { ... }
parse.addDependency(download)
store.addDependency(parse)
queue.addOperations([download, parse, store], waitUntilFinished: false)
```

实测：

```
== OperationQueue ==
  ok   最多两个并发
  执行顺序 = 下载 → 解析 → 入库
  ok   依赖保证了顺序（实际 ["下载", "解析", "入库"]）
  ok   操作可以被取消
```

**什么时候用 OperationQueue 而不是 GCD**：

- 任务之间有依赖
- 需要取消（GCD 的 block 一旦派发就取消不了）
- 需要限制并发数
- 需要 KVO 观察 `isFinished` / `isExecuting`

## 7) 主线程规则

```swift
DispatchQueue.global().async {
    let sum = (1...100).reduce(0, +)
    DispatchQueue.main.async {
        label.stringValue = "\(sum)"       // UI 只能在主线程改
    }
}
```

实测：

```
== 主线程规则 ==
  ok   后台算完的结果正确（实际 5050）
  ok   等完之后回到主线程了
  ok   asyncAfter 的延时任务会执行
```

**规则**：

- `NSView` / `NSWindow` / 任何 UIKit/AppKit 对象 → **主线程**
- 模型对象如果会被 UI 读 → 也尽量限制在主线程（或者加锁）
- 文件 IO、网络、计算 → 后台

macOS 上有一条额外的：**`NSDocument` 的读写、打印、撤销栈**
也都在主线程。Xcode 的 Main Thread Checker 能帮你抓违规
（Scheme → Diagnostics → Main Thread Checker）。

## 8) 现代并发（Swift 5.5+）

如果部署目标允许（macOS 12+ 有部分 back-deploy，macOS 13+ 完整）：

```swift
func load() async -> [Item] {
    let data = try? await URLSession.shared.data(from: url).0
    return decode(data)
}

Task { @MainActor in
    items = await load()        // 结果自动回到主线程
}
```

- `async/await` 取代回调嵌套
- `actor` 取代锁（编译期保证不数据竞争）
- `@MainActor` 标注「必须在主线程」的类型/方法

AppKit 里 `@MainActor` 还没全面铺开（不像 SwiftUI 那样强制），
所以**你自己标注**才是正确做法。

## 9) 坑清单

| 现象 | 原因 |
| --- | --- |
| 「建了个队列但不并发」 | `DispatchQueue(label:)` 默认串行，要加 `.concurrent` |
| 界面偶发错乱/崩溃 | 后台线程碰了 UI |
| 计数比预期小 | 共享变量没加锁 |
| `wait` 卡死 | group 的 enter/leave 不配对，或任务根本没派发 |
| `Thread.main.name` 是空 | 主线程默认没名字 |
| Operation 不执行 | 有依赖没满足，或 queue 被挂起（`isSuspended`） |
| 死锁 | 在主线程 `DispatchQueue.main.sync {}`（必然死锁） |

**死锁的经典写法（千万别写）**：

```swift
DispatchQueue.main.sync { ... }   // 在主线程上调用 → 立刻死锁
```

## 小结

- `DispatchQueue(label:)` 默认串行；并发要显式 `.concurrent`。
- 并行循环按下标写不同位置，避免共享。
- **环境相关的数字不要打印**（计数、时间戳、线程 id），只打印性质。
- `DispatchGroup` 用 `wait` 阻塞 / `notify` 非阻塞。
- `OperationQueue` 有依赖和取消，GCD 没有。
- UI 只在主线程；后台算完 `DispatchQueue.main.async` 回去。
