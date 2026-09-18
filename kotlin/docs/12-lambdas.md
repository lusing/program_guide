# 12 · 高阶函数与 Lambda ⭐

> 对应示例：`examples/12_lambdas/`
>
> 函数类型、`it`、函数引用、真闭包、带接收者的函数类型、
> 作用域函数五件套、inline 与非局部返回——Kotlin 表达力的发动机。

## 12.1 函数类型：函数是一等值

```kotlin
val square: (Int) -> Int = { x -> x * x }        // 类型 (Int) -> Int
val cube = { x: Int -> x * x * x }               // 类型写在参数上
val sum2: (Int, Int) -> Int = { a, b -> a + b }
val log: (String) -> Unit = { println(it) }      // 无返回值
val maybe: (() -> Int)? = null                   // 函数类型本身可空（括号别忘了）
```

高阶函数 = 参数或返回值是函数的函数：

```kotlin
fun operate(a: Int, b: Int, op: (Int, Int) -> Int): Int = op(a, b)
fun multiplier(k: Int): (Int) -> Int = { it * k }        // 返回函数
operate(6, 3) { a, b -> a - b }          // 尾随 lambda
multiplier(3)(7)                          // 21
```

## 12.2 lambda 语法与 `it`

```kotlin
listOf(1, 2).map { it * 2 }              // 单参数隐式名 it
listOf(1, 2).map { x -> x * 2 }          // 显式命名（可读性优先时用）
listOf("a", "b").map { (_, _) -> }       // 用不到的参数（Pair 解构）叫 _
```

**尾随 lambda**：函数最后一个参数是函数类型时，lambda 提到括号外——`list.filter { ... }.map { ... }` 的链式手感全靠它。

## 12.3 函数引用 `::`

```kotlin
operate(6, 3, ::maxOf)                       // 现有函数当值传
val ops: List<(Int, Int) -> Int> = listOf(::minOf, ::maxOf)   // 重载多时需类型标注
listOf("a", "b").map(String::uppercase)      // 构造器/成员引用
::require                                    // 顶层函数引用
```

lambda 和 `::` 的选择：逻辑现成（已有函数）用引用；就地一两行用 lambda。

## 12.4 真闭包：能捕获 var

```kotlin
var calls = 0
val counted = { calls++; calls * 10 }        // 修改外部变量
counted(); counted(); counted()              // 10, 20, 30 —— calls 变成 3
```

Java lambda 只能捕获 effectively final；Kotlin 是真闭包，var 也能捕——**能力越强越要小心**：捕获 var 的 lambda 传给异步代码 = 共享可变状态（15 章竞态的根源之一）。

## 12.5 带接收者的函数类型：`T.() -> R`

```kotlin
fun <T> T.printlned(tag: String, block: T.() -> String): String = "[$tag] ${block()}"

10.printlned("平方") { (this * this).toString() }              // this = 10
"kotlin".printlned("长度") { "$length（this=$this）" }         // this = "kotlin"
```

lambda 里 `this` 就是接收者——可以省略前缀直接调成员（`length`）。这是 **DSL 的地基**（23 章 HTML builder 全靠它），标准库的 `apply/run/with/buildString` 也是它。

## 12.6 作用域函数五件套

| 函数 | 接收者 | 返回 | 引用方式 | 一句话场景 |
|---|---|---|---|---|
| `let` | it（参数） | lambda 结果 | `it` | 可空链：`x?.let { ... }`；临时转换 |
| `run` | this | lambda 结果 | `this` | 对象上算个值 |
| `with` | this（参数传入） | lambda 结果 | `this` | 对同一对象连做多步（不是扩展） |
| `apply` | this | **对象本身** | `this` | 配置/初始化后返回自身 |
| `also` | it | **对象本身** | `it` | 顺路副作用（打日志、校验）后返回自身 |

```kotlin
p?.let { println("${it.name} ${it.score}") }            // 非空才执行
val bonus = ada.run { score * 2 }                       // this = ada
with(ada) { score += 5 }                                // 一串成员操作
val p2 = Player("Bob", 0).apply { score = 50 }          // 配置完返回对象
val p3 = Player("Carol", 60).also { log(it) }           // 副作用完返回对象
```

选型口诀：**改对象拿对象 → apply；拿值 → run/let；带副作用拿对象 → also；it/this 二选一：嵌套作用域时选 it 避免歧义**。

## 12.7 inline 与非局部返回

标准库的 `forEach/map/firstOrNull` 都是 **inline**——函数体在编译期内联进调用处，两个直接后果：

```kotlin
// 1. 零调用开销（lambda 不再是对象）
// 2. lambda 里的 return 直接退出【外层函数】——非局部返回
fun firstNegative(xs: List<Int>): Int? {
    xs.forEach { if (it < 0) return it }      // return 的是 firstNegative！
    return null
}
```

inline 前提下 lambda 里的裸 `return` 不只是退出 lambda。反过来：**非 inline** 的高阶函数（自己写的、或标了 noinline）里 lambda 不能非局部返回，`return@forEach` 这种**带标签返回**才合法（只退出该 lambda）。

自己写高阶函数时的三个修饰：

- `inline`：整体内联（性能 + 允许非局部返回 + 唯一能用 reified 的地方）；
- `noinline`：某个函数参数不想被内联（要把它存起来/传出去时必须）；
- `crossinline`：内联但禁止非局部返回（lambda 会在别的执行上下文跑，比如线程里）。

## 12.8 坑位清单

1. **裸 return 在 inline lambda 里穿透**——`forEach { return }` 退的是外层函数。只想退出当轮用 `return@forEach`。
2. `it` 嵌套（lambda 里再写 lambda）立刻显式命名，否则 `it` 指最内层。
3. `apply` 里 `this` 指接收者——**同名局部变量会被遮蔽**，必要时写全 `this.x`。
4. 五件套返回值方向不同：`apply/also` 返回对象、`let/run/with` 返回 lambda 值——接错变量类型会立刻暴露，但写 `val x = p.apply { ... }.let { ... }` 链时要清楚每环在传什么。
5. 函数类型可空要括号：`() -> Int` 可空写成 `(() -> Int)?`，`() -> Int?` 是"返回可空"。
6. 捕获 var 的 lambda 在并发/异步里 = 隐形共享状态——传出去之前想想值拷贝（`it`）是不是更稳。
