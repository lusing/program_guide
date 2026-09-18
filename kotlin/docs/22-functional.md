# 22 · 函数式编程

> 对应示例：`examples/22_functional/`（惰性 Sequence、组合/柯里化、Either、依赖注入时间、不可变更新）
>
> Kotlin 不是纯函数式语言，但"值不可变 + 函数组合 + 显式错误传递"
> 这些手法在日常代码里立刻兑现可测性和可读性。

## 22.1 List vs Sequence：急切 vs 惰性

```kotlin
(1..5).toList().map { log("map $it"); it * 10 }.filter { log("filter $it"); it > 20 }.take(2)
// 输出：map 1..5 全跑完 → filter 1..5 全跑完 → 取 2 个。中间物化 3 个列表。

(1..5).asSequence().map { log("map $it"); it * 10 }.filter { log("filter $it"); it > 20 }.take(2).toList()
// 输出：map 1 → filter 10 → map 2 → filter 20 → map 3 → filter 30(过) → map 4 → filter 40(过) → 停。
```

**元素逐个流过全管道**，take 攒够就停（示例实测：集合版算 5 个元素、序列版算 4 个）。

选型：**小集合（<1000）用 List 管道**（简单直接、无 Sequence 开销）；**大集合 / 无限序列 / 提前终止 / 多步链**用 Sequence。`generateSequence(1) { it * 2 }.takeWhile { it < 1000 }` 这种"无限生产 + 条件截断"只有 Sequence 能写。

## 22.2 纯函数：把不确定性注射进来

```kotlin
interface Clock { fun nowMs(): Long }
class FakeClock(private var t: Long) : Clock {
    override fun nowMs(): Long = t
    fun advance(ms: Long) { t += ms }
}

fun isExpired(createdAt: Long, ttl: Long, clock: Clock): Boolean =   // 纯函数：时间从参数进
    clock.nowMs() - createdAt > ttl
```

副作用（时钟、随机、IO）**不消灭而是注入**（20 章随机种子同思路）。测试不再"真等 6 秒"——`clock.advance(6000)` 一步到位。给"当前时间/随机数/文件系统"包一个小接口，是业务代码可测化的最短路径。

## 22.3 组合与柯里化

```kotlin
// 组合：compose(f, g)(x) = f(g(x))
fun <A, B, C> compose(f: (B) -> C, g: (A) -> B): (A) -> C = { f(g(it)) }
val f = compose(String::uppercase, String::trim)
f("  hi ")        // "HI"

// 柯里化：多元 → 一元链
fun curry3(f: (Int, Int, Int) -> Int): (Int) -> (Int) -> (Int) -> Int =
    { a -> { b -> { c -> f(a, b, c) } } }
curry3(::add3)(1)(2)(3)          // 6

// 部分应用：固定前几个参数
fun <A, B, C> partial2(f: (A, B) -> C, a: A): (B) -> C = { b -> f(a, b) }
val add10 = partial2(::add2, 10); add10(5)    // 15
```

标准库没有内置 compose/curry（Kotlin 有默认参数和接收者，需求弱）——手写 3 行就够，理解价值大于使用价值：**函数是值，值的变换规则适用于函数本身**。

## 22.4 Either：用类型表达"成功或失败"

```kotlin
sealed interface Either<L, R> {
    data class Left<L, R>(val value: L) : Either<L, R>
    data class Right<L, R>(val value: R) : Either<L, R>
}

inline fun <L, R, R2> Either<L, R>.map(f: (R) -> R2): Either<L, R2> = when (this) {
    is Either.Left -> Either.Left(value)      // 重建而非 this——类型才对得上
    is Either.Right -> Either.Right(f(value))
}

inline fun <L, R, R2> Either<L, R>.flatMap(f: (R) -> Either<L, R2>): Either<L, R2> = ...
```

铁路式编排（railway-oriented programming）：

```kotlin
fun pipeline(s: String): Either<String, String> =
    parseAge2(s).flatMap(::checkAdult).flatMap(::ticketPrice)

pipeline("70")   // Right("半价 ¥50")
pipeline("15")   // Left("未成年: 15")   —— 失败短路，后面不再执行
pipeline("x")    // Left("'x' 不是数字")
```

与 16 章的关系：**Either ≈ 二值版 Result（错误类型泛型化）**。Result 是 stdlib 内置（函数式管线方便），Either 是社区习惯（错误类型自定义、语义明确）。标准库的 `Result` 就够用时别自己造——这里手写是为了讲透 map/flatMap 的形状。

## 22.5 不可变数据 + copy 更新

```kotlin
data class Config(val host: String, val port: Int, val debug: Boolean)
val prod = Config("api.x.io", 443, false)
val debug = prod.copy(debug = true, port = 8443)   // 新值；prod 原封不动
```

不可变的红利：**值可以随便共享**（跨线程、跨协程、放进缓存）而不用担心被谁改。配合 10 章的"只读集合 + toList 落地"，Kotlin 的默认姿势就是"造新值而不是改旧值"。

## 22.6 尾递归与递归思维

```kotlin
tailrec fun sumTo(n: Int, acc: Int = 0): Int = if (n == 0) acc else sumTo(n - 1, acc + n)
sumTo(100_000)     // ✓ 不爆栈（05 章 tailrec 编译成循环）
```

递归处理"自相似数据"（树、JSON、表达式——08 章的 eval、19 章的 toJson、24 章的 JSON parser 全是递归下降）时是本能选择；深度不可控时换迭代或 Sequence。

## 22.7 函数式三板斧总结

1. **让副作用显形**：时间/随机/IO 走参数（接口注入）。
2. **让错误显形**：null / Result / Either / sealed，代替"抛着试试"。
3. **让数据不可变**：val + data class copy + 只读集合；改 = 造新值。

## 22.8 坑位清单

1. **Sequence 忘了终端操作就不执行**（toList/first/sum/forEach）——"管道写了没输出"九成是这个。
2. `asSequence()` 里放重副作用（打日志/发请求）= 每个 collect 重放一遍（15 章 Flow 冷流同理）。
3. Either 的 `map` 分支里返回 `this` 会类型对不上——多态 this 是 `Either<L, R>`，不是 `Either<L, R2>`；**重建**（`Either.Left(value)`）才是类型正确的写法（22.4 实测）。
4. 柯里化/组合的读性成本真实存在——三个参数以内的直接调用往往更好；这些工具的甜区是"高阶库/配置生成器"。
5. copy 是浅拷贝：嵌套可变对象仍共享（06 章坑 3 的函数式视角重申）。
6. 无限 Sequence 必须 `take/takeWhile` 截断——直接 toList() 会跑到 OOM。
