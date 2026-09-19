# 04 · 控制流

> 对应示例：`examples/04_control/`

## 4.1 if：条件必须穷尽成 Bool

```swift
let score = 85
if score >= 90 {
    print("优秀")
} else if score >= 60 {
    print("及格")
} else {
    print("不及格")
}
```

语法与 C 家族的差别只有三处，处处致命：**条件不加括号、大括号必须、条件必须是 Bool**。
`if score {}`（缺比较）或 `if (score) {}`（多余括号警告）都过不了编译。赋值表达式
不返回值（`if x = foo() {}` 是编译错误）——C 时代 `=` 误写当 `==` 的经典 bug 被
语法层消灭。

## 4.2 guard：提前退出的正统写法

```swift
func describeTraffic(light: String?) -> String {
    guard let light, !light.isEmpty else { return "没有信号" }
    return "信号灯是\(light)"   // ← light 在这里持续可用
}
```

`guard` 与 `if let` 解包同一个可选值，语义相反：**guard 的 else 分支必须离开当前
作用域**（return/throw/break/continue），正因如此，解包成功的值在**函数余下部分**
持续可用——`if let` 的解包值只活在自己的大括号里。

使用准则（Swift 社区共识，也是编译器某些检查的偏好）：

- 校验前置条件、失败就退 → `guard`
- 两种结果都要处理、各自一段逻辑 → `if else`
- 解包出的值后续到处用 → `guard let`（对比 `if let` 的"金字塔噩梦"）

`guard let light, !light.isEmpty` 一行多条件（逗号分隔），是 Swift 5.7 的解包简写
（老写法 `guard let light = light` 仍然合法）。

## 4.3 switch：穷尽性是强制项

```swift
func diceName(_ pips: Int) -> String {
    switch pips {
    case 1: return "一点"
    case 2: return "二点"
    case 3: return "三点"
    case 4: return "四点"
    case 5: return "五点"
    case 6: return "六点"
    default: return "不是骰子"
    }
}
```

Swift 的 switch 与 C 的三点本质差异：

1. **必须穷尽**：漏了分支编译不过（枚举场景连 default 都不建议加——新加枚举值时
   编译器替你找出漏网之处）。
2. **默认不贯穿**：每个 case 隐式 break，想贯穿要显式 `fallthrough`（罕见）。
3. **模式匹配引擎**：case 里能写的东西远超常量——区间、元组、值绑定、where、
   类型模式（09 章协议与 16 章并发里还会回来）。

### 区间模式

```swift
func scoreLevel(_ score: Int) -> String {
    switch score {
    case ..<60: return "不及格"
    case 60..<80: return "及格"
    case 80..<90: return "良好"
    case 90...: return "优秀"
    default: return fatalError("unreachable")  // 教学演示；区间已穷尽
    }
}
```

`..<` 半开区间、`...` 闭区间、`..<60` 无左界、`90...` 无右界——四件套覆盖所有
整数分段。注意 `case` 里的区间**没有重叠检查**，命中第一个即返回。

### 元组模式 + 值绑定 + where

```swift
func fizzBuzz(_ n: Int) -> String {
    switch (n % 3, n % 5) {
    case (0, 0): return "FizzBuzz"
    case (0, _): return "Fizz"
    case (_, 0): return "Buzz"
    default: return "\(n)"
    }
}

func quadrant(x: Double, y: Double) -> String {
    switch (x, y) {
    case (0, 0): return "原点"
    case (let px, 0) where px != 0: return "x 轴"
    case (0, _): return "y 轴"
    case (let px, let py) where px > 0 && py > 0: return "第一象限"
    // …
    default: return "第四象限"
    }
}
```

- 元组直接当被匹配值，`(0, _)` 的 `_` 是通配。
- `let px` 在模式内**绑定值**，供 where 与分支体使用。
- `where` 追加布尔条件——把"模式 + 谓词"的组合全放进 case，分支体只剩一句 return，
  这是消灭嵌套 if 的主力手段。

**case 顺序即优先级**：`(0, 0)` 必须写在 `(0, _)` 前面，否则原点被 y 轴截胡——
swift 不会警告，读代码时眼睛要盯顺序。

## 4.4 for-in 与 Range 家族：没有 C 式 for

```swift
var sum = 0
for i in 1...100 { sum += i }              // 闭区间 1…100

let evens = stride(from: 0, through: 10, by: 2)   // 步进：0 2 4 6 8 10
let letters = Array("甲乙丙丁")
for (index, char) in letters.enumerated() {       // 带序号遍历
    print("第 \(index + 1) 位：\(char)", terminator: " ")
}
```

Swift **没有** `for (int i = 0; i < n; i++)`——一律 `for x in 遍历物`。需要下标时用
`enumerated()` 或 `zip`；需要步进用 `stride(from:through:by:)`（闭端）或
`stride(from:to:by:)`（开端）。倒序 `for i in (1...5).reversed()`。

区间是正经类型（`ClosedRange`/`Range`），可以存、可以传、可以 `contains(42)`——
它不是语法糖，是 13 章集合体系的成员。`1..<count` 用错成 `1...count` 的越界，
在 13 章切片处还会再敲一次警钟。

## 4.5 while 与 repeat-while

```swift
var remaining = 3
while remaining > 0 { remaining -= 1 }      // 先判后跑

var attempts = 0
repeat { attempts += 1 } while attempts < 3 // 先跑后判，至少执行一次
```

`repeat-while` 即 C 的 `do-while`，改名以贴合"条件放尾部"的读法。死循环场合
`while true { }` + 内部 `break`。

## 4.6 标签跳转：多层循环一次 break

```swift
outer: for i in 1...5 {
    for j in 1...5 {
        if i * j >= 12 {
            hit = "\(i)×\(j)"
            break outer    // 直接跳出两层
        }
    }
}
```

标签写在循环前（`outer:`），`break outer` / `continue outer` 跨层跳转——比 C 多了
`continue 标签`（直接进入外层循环下一轮）。算法题里"找到即止"的双层搜索标配。

## 4.7 三元与 ??

```swift
let name: String? = nil
print("访客：\(name ?? "匿名")")   // nil 合并——06 章主角
let sign = score >= 60 ? "过" : "挂"
```

`??` 是可选类型的默认值运算符（右结合可链：`a ?? b ?? c`）；三元表达式与 C 相同，
但 Swift 惯用 `switch`/`guard` 后三元出现率显著更低——保留给"一行内的小分叉"。

## 4.8 坑位清单

1. **switch 的 case 顺序即优先级**——`(0, 0)` 必须在 `(0, _)` 之前；无重叠检查，
   写重了静默截胡。
2. **区间匹配无重叠告警**：`case 1...50` 与 `case 25...75` 编译器不报——分段逻辑
   自己画数轴核对。
3. **`enumerated()` 的下标不是原集合索引**：数组切片（13 章）的下标不从 0 开始，
   `for (i, x) in slice.enumerated()` 的 i 仍从 0 数——需要真实索引用 `indices`。
4. **`for i in 0...array.count`** 是经典越界（`...` 含端点，正确应为 `0..<array.count`）；
   惯用法直接 `for x in array`，需要索引时 `for i in array.indices`。
5. **guard 的 else 必须退出作用域**：else 分支里不 return/throw/continue/break 是
   编译错误——这正是解包值能"外泄"到后续代码的保证。
6. **浮点数的 switch 区间匹配可用但有精度陷阱**：边界值（如 0.1）参与计算后落在
   哪一段需谨慎；整数分段才是区间模式的舒适区。

上一章：[03 · 基础类型](03-basics.md) ｜ 下一章：[05 · 函数](05-functions.md) ｜ 返回：[README](../README.md)
