# 06 · 类与属性 ⭐

> 对应示例：`examples/06_classes/`（源码 `src/Main.kt`，测试 `test/Tests.kt`，输出快照 `expected.txt`）
>
> Kotlin 的 class 和 Java 最深的两条分歧：**属性（property）是语言级概念**，
> 以及 **data class 一行拿走 equals/hashCode/toString/copy/解构**。
> 另外运算符重载靠 operator 约定，不靠魔法。
>
> 本章代码在 Kotlin 2.4.21（K2 编译器）+ JDK 21 下经过四层验证：kotlinc `-Werror` 零告警编译 →
> kotlin.test 单元测试全过 → 程序运行 exit 0 → 输出与 `expected.txt` 快照逐字节一致。
> 正文中所有输出块都逐字引自该快照。

## 6.1 为什么 Kotlin 要把"属性"做成语言概念

先看 Java 里一个最普通的类长什么样：一个私有字段、一个 getter、一个 setter，
三个成员只为表达"我有一个可读写的 int"。十个字段就是三十段样板，
于是 Java 社区发明了 IDE 生成、Lombok、record 来轮番补救。

Kotlin 的判断是：这不是工具问题，是语言缺了一个概念。字段（field）是**存储**，
getter/setter 是**访问通道**，而调用方真正关心的只是"这个对象对外暴露了哪些值"——
这个"对外暴露的值"就是**属性（property）**。Kotlin 把属性提为一等概念之后：

- `var x: Int = 0` 一行同时给出存储和读写通道，编译器在字节码里自动生成私有字段和访问器；
- 想把"存起来的"换成"现算的"（比如把字段改成 `get() = width * height`），
  调用方代码一个字不用改——这就是"统一访问原则"：访问语法不暴露实现是字段还是计算；
- 读写规则从命名约定（`getX`/`setX` 谁写错一个字母就静默失效）变成编译器检查的语法。

C# 早就有同款设计，Java 至今没有——所以这一章是 Java 程序员体感最强的一章。

## 6.2 主构造：声明即属性

类的头部可以直接挂一个"主构造函数"，参数前写上 `val`/`var`，参数就同时成为类的属性：

```kotlin
class Rect(val width: Double, val height: Double) {
    val area: Double                       // 无 backing field：每次现算
        get() = width * height

    val isSquare: Boolean get() = width == height
}
```

逐行看这段真实源码：

- `class Rect(val width: Double, val height: Double)`——主构造跟在类名后面。
  `val width` 的意思是"构造时接收一个 Double，存为只读属性 width"。
  不写 `val`/`var` 的参数只是普通构造参数，构造完就消失。
- `val area: Double get() = width * height`——这个属性**没有 backing field**
  （背后没有真正的存储槽），每次访问都现场执行 `width * height`。
  它不是"缓存的结果"，而是"以属性语法暴露的计算"。
- `isSquare` 同理，`get()` 可以写成单行。

调用侧感受一下统一访问——`area` 是现算的，但看起来和普通字段一模一样：

```kotlin
val r = Rect(3.0, 4.0)
println("Rect(3,4): area=${r.area}, isSquare=${r.isSquare}")
val sq = Rect(5.0, 5.0)
println("Rect(5,5): area=${sq.area}, isSquare=${sq.isSquare}")
```

输出（引自 expected.txt）：

```text
Rect(3,4): area=12.0, isSquare=false
Rect(5,5): area=25.0, isSquare=true
```

`r.area` 读出来是 `12.0`（3×4 现算），`sq.isSquare` 是 `true`（5.0 == 5.0）。
对调用方来说，`width`（有字段）和 `area`（无字段）访问方式完全无差别——
这正是 6.1 说的"实现自由"：哪天需求变了要给 area 加缓存，改成带字段的普通属性即可，
所有调用点不受影响。

测试里也固定了这个行为（`test/Tests.kt` 的 `testRect`）：

```kotlin
assertEquals(12.0, Rect(3.0, 4.0).area)
assertTrue(Rect(5.0, 5.0).isSquare)
assertFalse(Rect(1.0, 2.0).isSquare)
```

## 6.3 init 块与参数校验

主构造是"声明"不是"函数"，里面写不了语句。那构造时的校验逻辑放哪？
答案是 `init {}` 块——它就是主构造的"函数体"：

```kotlin
class Price(var value: Int) {
    init {
        require(value >= 0) { "价格不能为负: $value" }
    }
    ...
}
```

[require](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/require.html) 是标准库的
参数校验函数：条件为假时抛 `IllegalArgumentException`，后面的 lambda 只在失败时执行，
拼出错误消息。和它同族的还有 `check`（校验对象状态，抛 `IllegalStateException`）和
`error`（无条件抛），16 章会细讲这一套。

执行顺序上有一条铁律：**属性初始化器和 init 块按它们在类体中出现的先后顺序交错执行**。
`Price` 的 init 块写在最前面，所以它最先跑——任何非法值在对象成形之前就被拦住。

示例里故意造了一个负价格：

```kotlin
try {
    Price(-1)
} catch (e: IllegalArgumentException) {
    println("Price(-1) 拒绝: ${e.message}")
}
```

输出：

```text
Price(-1) 拒绝: 价格不能为负: -1
```

测试 `testPriceValidation` 用 [assertFailsWith](https://kotlinlang.org/api/core/kotlin-test/kotlin.test/assert-fails-with.html)
把"必须抛"固化成契约：

```kotlin
assertFailsWith<IllegalArgumentException> { Price(-1) }
```

何时用：不变量（invariant）在构造期就能检查的，全部放 init。
"先造出非法对象、事后再修"是 Java 遗留的坏习惯，Kotlin 里没必要。

## 6.4 自定义 getter/setter 与 backing field

`Price` 的完整形态展示了属性的真正威力——读写通道里可以夹带逻辑：

```kotlin
class Price(var value: Int) {
    init {
        require(value >= 0) { "价格不能为负: $value" }
    }
    var currency: String = "CNY"           // 类体内声明的属性（带默认值）
        set(v) {                           // 自定义 setter：归一化存储
            field = v.uppercase()          // field = 真正的字段
        }
    var discount: Double = 0.0             // 0.0 ~ 1.0
        set(v) {
            field = v.coerceIn(0.0, 1.0)   // setter 里做钳制
        }
    val finalPrice: Double get() = value * (1 - discount)
}
```

三个属性，三种用法：

- `currency` 有真实存储，但赋值时经过 [uppercase()](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.text/uppercase.html)
  归一化：外部写 `"usd"`，存进去的是 `"USD"`。setter 里的 `field` 是只在访问器内可见的
  特殊标识符，指向属性背后的那个存储槽（backing field）。
  **setter 里绝不能写 `currency = ...`——那是对自己的递归调用，直接栈溢出；要存值只能写 `field = ...`。**
- `discount` 用 [coerceIn(0.0, 1.0)](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.ranges/coerce-in.html)
  把任何输入钳制到合法区间：传 1.5 存 1.0，传 -0.2 存 0.0。校验的两种风格由此清晰：
  `require` 是"不合法就炸"（硬约束），`coerceIn` 是"不合法就掰正"（软约束），按业务语义选。
- `finalPrice` 又是无字段属性：`value * (1 - discount)` 每次现算，永远和另外两个属性同步，
  不存在"缓存过期"问题。

看示例程序的实际运行：

```kotlin
val p = Price(100)
p.currency = "usd"                     // setter 归一化
p.discount = 1.5                       // setter 钳制到 1.0
println("Price: value=${p.value}, currency=${p.currency}, discount=${p.discount}, final=${p.finalPrice}")
```

输出：

```text
Price: value=100, currency=USD, discount=1.0, final=0.0
```

`"usd"` 被归一成 `USD`，`1.5` 被钳到 `1.0`，`final = 100 × (1 − 1.0) = 0.0`。
测试 `testPriceClamp` 再验证一遍（包括折扣 3.0 → 1.0、`"jpy"` → `"JPY"`）。

这一节要记住的心智模型是：**属性 ≠ 字段**。公开 API 全部是属性，
内部是直接存、归一化存、还是根本不存，属于实现细节——这是 Kotlin 与 Java 的根本差异之一。

## 6.5 次构造函数：必须委托主构造

偶尔确实需要第二种构造方式（比如兼容老调用方）。Kotlin 允许在类体里写次构造函数，
但有个硬规则：**次构造必须（直接或间接）委托主构造**，用 `: this(...)` 表示：

```kotlin
class Employee(val name: String) {
    var dept: String
    constructor(name: String, dept: String) : this(name) {   // 次构造必须委托 this(...)
        this.dept = dept
    }
    init { dept = "未分配" }               // init 在主构造后、次构造体前执行
    override fun toString() = "Employee($name @ $dept)"
}
```

这里藏着一个执行顺序的考点。`Employee("李四", "研发")` 的完整流程是：

1. 次构造先把 `name` 委托给主构造 `: this(name)`——主构造执行，属性 `name` 初始化；
2. 类体按声明顺序执行：`var dept: String`（尚无值）、init 块把 `dept` 赋成 `"未分配"`；
3. 最后才轮到次构造自己的函数体：`this.dept = dept` 覆盖为 `"研发"`。

也就是说 init 块**先于**次构造体执行。示例输出印证了两种构造路径：

```text
Employee(张三 @ 未分配)
Employee(李四 @ 研发)
```

走主构造的 `"张三"` 拿到 init 给的默认部门；走次构造的 `"李四"` 先被 init 赋默认值、
再被次构造体覆盖成 `"研发"`。测试 `testSecondaryCtor` 断言了这两个结果。

经验法则：次构造在 Kotlin 里用得比 Java 少得多——**默认参数 + 具名参数**（05 章）消灭了
大部分重载需求，**工厂函数**（09 章 companion）消灭了"不同名字、不同语义"的构造需求。
次构造主要剩两个场景：和 Java 代码互操作，以及委托链很长的视图类（Android 自定义 View 那种）。

## 6.6 data class：一行换五件套

```kotlin
data class Point(val x: Int, val y: Int) {
    fun moveBy(dx: Int, dy: Int) = copy(x = x + dx, y = y + dy)   // copy 只改部分字段
}
```

一个 `data` 修饰符，编译器基于**主构造的全部参数**生成五件东西：

| 成员 | 语义 |
|---|---|
| `equals` / `hashCode` | 按主构造属性逐一比较：`Point(1,2) == Point(1,2)` 为 true（值相等，不是引用相等） |
| `toString` | 人类可读的 `Point(x=1, y=2)`，不用再手写 |
| `copy` | 克隆并选择性改字段：`a.copy(y = 99)`，原对象不动 |
| `component1` … `componentN` | 支撑解构声明 `val (x, y) = a` |

示例程序把五件套挨个用了一遍：

```kotlin
val a = Point(1, 2)
val b = Point(1, 2)
println("a == b（值相等）: ${a == b}  —— data class 按值比较；普通 class 按引用比较")
println("a.toString(): $a")
println("a.hashCode() == b.hashCode(): ${a.hashCode() == b.hashCode()}")
val c = a.copy(y = 99)
println("a.copy(y=99): $c（原对象不动: $a）")
val (x, y) = a                          // 解构声明 = componentN()
println("解构: x=$x, y=$y")
println("moveBy(10,20): ${a.moveBy(10, 20)}")
```

输出：

```text
a == b（值相等）: true  —— data class 按值比较；普通 class 按引用比较
a.toString(): Point(x=1, y=2)
a.hashCode() == b.hashCode(): true
a.copy(y=99): Point(x=1, y=99)（原对象不动: Point(x=1, y=2)）
解构: x=1, y=2
moveBy(10,20): Point(x=11, y=22)
```

逐条对应：`a == b` 是 `equals` 的值比较（Kotlin 的 `==` 永远调 `equals`，引用比较要用 `===`）；
`copy(y = 99)` 产出新对象 `Point(x=1, y=99)` 而 `a` 原封不动——**copy 是"不可变更新"的基石**，
22 章函数式风格里大量状态演进都靠它；`val (x, y) = a` 实际是调用 `a.component1()` 和
`a.component2()`；`moveBy` 展示了 copy 的典型用法：类自己提供语义化的"改一部分"方法，
内部委托给 copy。

测试 `testDataClass` 还固定了两个容易忽略的事实：`a.copy()` 不带参数会得到一个等值新实例
（`assertEquals(a, a.copy())`），`toString()` 的确切格式是 `Point(x=1, y=2)`。

data class 的限制（编译器会强制）：主构造**至少一个参数**、参数必须全是 `val`/`var`、
类不能是 `abstract`/`open`/`sealed`/`inner`。最要命的细节是：**equals/hashCode/toString
只看主构造参数**——类体里声明的属性一律不参与，详见 6.10 坑位清单第 1 条。

## 6.7 运算符重载：operator 约定

C++ 允许给几乎任何符号写重载，自由度大到能造出不可读的"运算符汤"。
Kotlin 的取舍是：**符号固定、函数名固定、签名有约束**，只允许在约定内映射：

```kotlin
data class Vec2(val x: Double, val y: Double) {
    operator fun plus(o: Vec2) = Vec2(x + o.x, y + o.y)
    operator fun times(k: Double) = Vec2(x * k, y * k)     // 数乘
    operator fun unaryMinus() = Vec2(-x, -y)
    operator fun get(i: Int): Double = when (i) { 0 -> x; 1 -> y; else -> throw IndexOutOfBoundsException("i=$i") }
}
```

四个 `operator` 函数各自接通一个符号：`plus` → `+`，`times` → `*`，`unaryMinus` → 前置 `-`，
`get` → `[]` 下标。可用的映射表是封闭的（`plus/minus/times/div/rem/unaryMinus/get/set/
contains/compareTo/componentN/invoke/iterator` 等），写不了表外的符号——
限制换来的是：看到 `a + b` 你最多需要查一个 `plus` 函数，绝不会遇到被重载成"发网络请求"的 `+`。

示例程序的运行：

```kotlin
val v = Vec2(1.0, 2.0) + Vec2(10.0, 20.0) * 2.0
println("Vec2(1,2) + Vec2(10,20)*2 = $v")
println("-v = ${-v}")
println("v[0]=${v[0]}, v[1]=${v[1]}")
```

输出：

```text
Vec2(1,2) + Vec2(10,20)*2 = Vec2(x=21.0, y=42.0)
-v = Vec2(x=-21.0, y=-42.0)
v[0]=21.0, v[1]=42.0
```

第一行值得拆解：重载后的运算符**沿用语言原有的优先级**——`*` 先于 `+`，
所以先算 `Vec2(10,20) * 2.0 = Vec2(20,40)`，再加 `Vec2(1,2)` 得 `Vec2(21,42)`。
不能自定义优先级，这也是"约定优于自由"的一部分。

`get` 越界时抛出 [IndexOutOfBoundsException](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/-index-out-of-bounds-exception/index.html)，
测试 `testOperators` 用 `assertFailsWith<IndexOutOfBoundsException> { v[2] }` 固化了这个行为。
另外注意 `get` 的参数类型和数量其实不受限（`m["key", 1]` 这种签名也合法），Map 的
`m["k"]` 就是这套约定——但自定义类型请克制，可读性优先。

这套约定还是很多语言特性的底座：`in` 走 `contains`，`for..in` 走 `iterator`，
解构走 `componentN`，`a[i] = x` 走 `set`，区间比较走 `compareTo`。30 章会系统过一遍。

## 6.8 可见性入门

默认 **public**。四档修饰符：

| 修饰符 | 可见范围 |
|---|---|
| `public`（默认） | 任意处 |
| `internal` | 同一模块（一次 kotlinc 编译 / 一个 Gradle module） |
| `protected` | 本类 + 子类 |
| `private` | 本类；顶层声明则是本文件 |

"默认 public + 默认 final（07 章）"是 Kotlin"少惊喜"哲学的两面：
对外暴露是显式选择，被继承也是显式选择。可见性的实战细节（含 internal 的模块边界）
在 7.7 展开。

## 6.9 与 Java class 的对照表

| Java | Kotlin |
|---|---|
| `private int x;` + `getX()` + `setX(v)` | `var x: Int = 0`（一行） |
| 只读 getter | `val x: Int` |
| 字段不暴露、getter 算出来的值 | 无 backing field 属性 `val area get() = ...` |
| 重载构造器链 | 默认参数（+ 次构造兜底） |
| Lombok `@Data` / `record` | `data class` |
| `Objects.equals(a, b)` | `a == b` |
| `a == b`（引用比较） | `a === b` |
| `String.format(...)` 摆一排行 | 字符串模板 `"$name = $value"` |

## 6.10 坑位清单

1. **data class 的 equals 不看类体属性**——只看主构造参数。给 data class 在类体里加
   `var extra: String`，就会出现"`a == b` 为 true 但 `a.extra != b.extra`"的诡异对象对。
   要么把字段挪进主构造，要么接受它不参与相等性。
2. **主构造里 `val x` 与类体 `val x = ...` 撞名**：直接编译错，不是"后者覆盖前者"。
3. `copy` 是**浅拷贝**：属性若是 `MutableList`，副本和原对象共享同一个列表实例，
   改一边另一边跟着变。要深拷贝自己写（或让属性也只读不可变，配合 22 章的不可变更新）。
4. 自定义 setter 里**写自己的属性名 = 无限递归**：`set(v) { currency = v }` 编译能过、
   运行栈溢出。存值永远写 `field`。
5. **初始化顺序 = 声明顺序**（属性初始化器与 init 块交错）：在前面的初始化器里引用
   后面才声明的属性，拿到的是默认值（0/null）甚至直接编译错。有依赖关系的初始化逻辑，
   显式排好顺序，或集中放进一个 init 块。
6. `operator fun get` 参数可以任意类型/数量——合法不等于该写，运算符重载的全部价值
   在于"望文生义"，炫技签名只会制造阅读成本。

---

上一章：[05 函数](05-functions.md) · 下一章：[07 继承与接口](07-inheritance.md)
