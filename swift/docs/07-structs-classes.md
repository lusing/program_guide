# 07 · 结构体与类

> 对应示例：`examples/07_structs_classes/`

## 7.1 一句话分家：值语义 vs 引用语义

```swift
var a = Size(width: 3, height: 4)
let b = a          // struct：整份拷贝，b 是独立副本
a.scale(by: 2)     // 改 a，b 毫发无损

let west = TicketCounter(location: "西门", remaining: 2)
refill(west, to: 5)   // class：传的是引用，函数内改的就是 west 本尊
```

| 维度 | struct | class |
|---|---|---|
| 语义 | 值（赋值即拷贝） | 引用（赋值拷"地址"） |
| 拷贝成本 | 看成员（COW 优化，13 章） | 恒为一次引用计数 +1 |
| 继承 | 无（协议模拟，09 章） | 有（单继承） |
| deinit | 无 | 有（ARC 归零时调用） |
| 多态 | 无（协议动态分发除外） | 有（方法重写） |
| 线程安全 | 值隔离，天然安全 | 共享可变，靠并发原语（18 章） |

**Swift 的默认选择是 struct**——与 C++/Java 相反。标准库里 `Array`/`String`/`Dictionary`
全是 struct。选型决策树：

1. 只是"装几个值"（坐标、配置、模型）→ **struct**
2. 需要身份与生命周期（文件句柄、网络连接、GUI 控件）→ **class**
3. 要继承 → class（但先想想协议能不能替代，09 章）
4. 会跨线程共享可变状态 → 想清楚再说（18 章 actor 才是答案）

## 7.2 结构体：成员式初始化器与 mutating

```swift
struct Size: Equatable {
    var width: Double
    var height: Double

    var area: Double { width * height }      // 计算属性

    mutating func scale(by factor: Double) { // 改 self 必须 mutating
        width *= factor
        height *= factor
    }
}
let rect = Rect(origin: (x: 0, y: 0), size: Size(width: 10, height: 6))  // 免写 init
```

三件事：

- **成员式初始化器免费送**：所有存储属性自动生成 `Size(width:height:)`——class 没有
  这待遇，必须手写 init。
- **`mutating` 是显式契约**：struct 方法默认不能改 self（self 是 let 拷贝）；
  加 mutating 才能改，且**只能对 var 实例调用**——`let b` 调 `b.scale(...)` 编译错误。
  对比 C++ 的 const 成员函数：Swift 把"可变性"标记在调用链两头。
- **计算属性**：`var area: Double { ... }` 无存储、每次访问现算；`get`/`set` 都能写
  （set 里 `newValue` 是传入值）。

## 7.3 属性观察者：willSet / didSet

```swift
class TicketCounter {
    var remaining: Int {
        willSet { print("  willSet：剩余 \(remaining) → \(newValue)") }  // 改之前（旧值还能读）
        didSet { print("  didSet：剩余由 \(oldValue) 变为 \(remaining)") } // 改之后
    }
    // ...
}
```

属性被赋值时自动触发的一对钩子（newValue/oldValue 是内建名，可自定义：
`willSet(new) {...}`）。典型用途：联动 UI、触发缓存失效、记审计日志。注意：

- **init 内的首次赋值不触发**观察者（属性"从无到有"不算变更）；
- 计算属性没有观察者（它的 getter/setter 本来就是你写的）；
- 父类的观察者先于子类的 didSet 触发（继承场景）。

## 7.4 类：deinit 与静态成员

```swift
class TicketCounter {
    static let price = 30              // 类型属性：所有实例共享一份
    let location: String
    var sold = 0

    init(location: String, remaining: Int) {   // 类必须显式 init
        self.location = location
        self.remaining = remaining
    }

    deinit { print("  deinit：\(location) 窗口关闭") }   // ARC 引用计数归零时调用

    func sellOne() -> Bool {
        guard remaining > 0 else { return false }
        remaining -= 1
        sold += 1
        return true
    }
}
```

- **deinit 是 class 专属**：struct 何时析构编译器说了算，不给钩子。示例里
  `westGate = nil` 断开最后一个引用 → deinit 立即执行——这就是 ARC 的确定性回收
  （对比 GC 语言的 finalizer 时机玄学）。16 章用它做泄漏探针。
- **static let** 是延迟初始化的、线程安全的类型常量；`static var` 是全局共享可变
  状态——并发场景下慎重（18 章）。
- 类实例**可以传 nil**：`var westGate: TicketCounter? = ...`——引用类型天然可选。

## 7.5 为什么 struct 拷贝"没那么贵"：COW 一瞥

`let b = a` 对 struct 是逐成员拷贝？容器类（Array/String/Dictionary）内置**写时复制**
（Copy-On-Write）：拷贝时只共享底层缓冲 + 引用计数，**第一次被修改**才真正复制。
所以 `let copy = bigArray` 是 O(1)，`copy.append(x)` 才触发 O(n) 复制。自定义 struct
没有自动 COW（16 章手搓一个）。

## 7.6 坑位清单（含实测）

1. **`==` 不是白送的**：struct 声明 `Equatable` 才有合成的 `==`（07 示例实测——忘写
   conformance，测试里的 `#expect(size == ...)` 直接编译错误）。class 的 `==` 默认是
   **身份比较**（同一个对象才相等），值比较要自己实现。
2. **`let` 的 struct 不能调 mutating 方法**——"b 是常量所以不能 scale"是编译期契约，
   与"值不变"的语义自洽。
3. **结构体嵌结构体，观察者只看直接属性**：`rect.size.width = 5` 若 size 是 let，
   报错的是"不能给嵌套属性赋值"，而不是"rect 是常量"——错误信息绕一层。
4. **属性观察者在 init 首赋值时不触发**：想拦"构造后的所有变化"没问题，但别指望
   拦构造本身。
5. **class 的 `var` 属性默认观察者代价**：每次赋值多两次函数调用——热路径上用计算
   属性或直接方法替代。
6. **deinit 里别用self 引用逃逸**：deinit 执行时对象已在拆解，捕获 self 的闭包存活
   会导致"复活"未定义——16 章弱引用一并讲。

上一章：[06 · 可选类型](06-optionals.md) ｜ 下一章：[08 · 枚举](08-enums.md) ｜ 返回：[README](../README.md)
