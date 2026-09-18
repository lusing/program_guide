# Kotlin 速查表（2.4.20）

> 配合 [README 章节索引](README.md) 使用；每条后面的 `→ N 章` 指向详解章节。

## 变量与类型

```kotlin
val x = 1              // 只读引用（默认）           → 03
var y = 1              // 可重新赋值                 → 03
val l = 1_000_000_000_000L   // Long；Int→Long 必须 a.toLong()（无隐式加宽）→ 03
val s: String? = null  // 可空是另一个类型           → 04
val any: Any = x       // 万物之祖 Any（非空）        → 07
```

## 空安全五件套

```kotlin
u?.name                // 安全调用：null 短路整个链   → 04
v ?: "默认"             // Elvis：null 时取右侧（可 return/throw）→ 04
x!!                    // 断言非空：null 就 NPE      → 04
x as? String           // 安全转换：错类型 → null     → 04
lateinit var cfg: String   // 延迟初始化（::cfg.isInitialized）→ 04
```

## 函数

```kotlin
fun f(a: Int, b: Int = 1, vararg c: Int): Int = a + b   // 默认/vararg → 05
connect(host, port = 5432)          // 具名参数随意跳序        → 05
infix fun Int.pow(n: Int): Int; 2 pow 10                   // 中缀 → 05/23
tailrec fun fac(n: Long, acc: Long = 1): Long              // 尾递归 → 05
fun <T : Comparable<T>> max3(a: T, b: T, c: T): T          // 泛型约束 → 11
inline fun <reified T> List<Any>.pick() = filterIsInstance<T>()   // reified → 11
```

## 类与对象

```kotlin
class Rect(val w: Double, val h: Double)          // 主构造即属性 → 06
val area get() = w * h                            // 无字段属性 → 06
var v: Int = 0; set(x) { field = x.coerceIn(0, 9) }   // field → 06
data class P(val x: Int, val y: Int)              // ==/hashCode/toString/copy/解构 → 06
val (a, b) = point; p.copy(y = 9)                 // 解构 + 不可变更新 → 06/22
operator fun Vec2.plus(o: Vec2) = ...; v1 + v2    // 运算符约定 → 06
object Single { ... }                             // 单例 → 09
companion object { fun of(...) }                  // 工厂/静态侧 → 09
class Box<T>(l: List<T>) : List<T> by l           // 类委托 → 09
val conf by lazy { load() }                       // 委托属性 → 09
var t by Delegates.observable(0) { _, o, n -> }   // → 09
```

## 继承与密封

```kotlin
open class A { open fun f() }                     // 默认 final → 07
class B : A() { override fun f() }                // 显式 override → 07
interface Named { fun label() = "[$name]" }       // 接口默认实现 → 07
inner class I { fun t() = this@Outer.x }          // inner 持外部引用；嵌套默认不持 → 07
enum class E(val g: Double) { A(1.0), B(2.0); }   // entries（别用 values）→ 08
sealed interface Expr { data class Num(v): Expr } // ADT → 08
```

## when 与控制流

```kotlin
when (x) { 0 -> ..; 1,2 -> ..; in 3..9 -> ..; else -> .. }   // → 03
when { x > 0 -> ..; else -> .. }                              // 无主体 → 03
when (n) { in 1..9 if n % 2 == 0 -> "偶" }                     // 守卫（2.1+）→ 08
when (e) { is Num -> e.v; Zero -> 0.0 }                        // 穷尽，别写 else → 08
for (i in 0 until n step 2) {}                                 // 半开区间 → 03
outer@ for (...) { break@outer }                               // 标签 → 03
```

## 集合

```kotlin
listOf(1,2); mutableListOf(1); buildList { add(1) }            // → 10
xs.filter{}.map{}.first{}/firstOrNull{}                        // 管道 → 10
xs.groupBy{}.associateBy{}; groupingBy{it}.eachCount()         // → 10
xs.fold(0){a,b->a+b}                    // reduce 空列表会炸 → 10
xs.sorted() / xs.sort()                 // 新列表 / 原地 → 10
chunked(2) / windowed(2) / zip / flatMap                       // → 10
m.getOrPut(k){v}                                               // → 10
seq: xs.asSequence().map{}.take(2).toList()                    // 惰性 → 22
```

## Lambda 与作用域函数

```kotlin
val f: (Int) -> Int = { it * 2 }                               // → 12
xs.forEach { if (...) return@forEach }                         // 标签返回 → 12
operate(1, 2) { a, b -> a + b }                                // 尾随 lambda → 12
::maxOf; String::uppercase                                     // 函数引用 → 12
fun <T> T.run2(b: T.() -> Unit)                                // 接收者 lambda → 12/23
x?.let{} · x.run{} · with(x){} · x.apply{} · x.also{}          // 五件套 → 12
```

## 扩展

```kotlin
fun String.slug() = ...                    // 静态解析（非虚）→ 13
fun String?.or(d: String) = this ?: d      // 可空接收者 → 13
val List<Int>.sq get() = ...               // 扩展属性（无字段）→ 13
fun C.Companion.extFun()                   // 伴生扩展 → 13
```

## 协程

```kotlin
runBlocking { }                    // 阻塞桥（仅 main/测试）→ 14
val job = launch { }; job.join()   // 触发型 → 14
val d = async { 42 }; d.await()    // 并行收账 → 14
coroutineScope { }                 // 等全部子完成 → 14
delay(100)                         // 挂起等待（不占线程）→ 14
withTimeoutOrNull(50){}            // 超时 → 14
withContext(Dispatchers.IO){}      // 切线程 → 14/21
cancel()/ensureActive()            // 协作式取消 → 14
val ch = Channel<Int>(); send/recv/close/for(x in ch)   // → 15
val f = flow { emit(1) }; f.map{}.collect{}             // 冷流 → 15
MutableSharedFlow(e)/MutableStateFlow(0)                // 热流 → 15
Mutex().withLock { }                // 协程锁（不可重入）→ 15
```

## 错误处理

```kotlin
val v = try { "1".toInt() } catch(e: NumberFormatException) { null }   // 表达式 → 16
require(x > 0) { "参数" }; check(ok) { "状态" }; error("x")             // 三件套 → 16
fun boom(): Nothing = throw E()                  // Nothing → 16
runCatching{}.map{}.getOrElse{-1}.fold({}, {})   // Result → 16
res.use { }                                       // 自动关闭 → 16
```

## 互操作（Java）

```kotlin
@JvmStatic @JvmField @JvmOverloads @JvmName("x") @file:JvmName("X") @Throws(...)  // → 18
Lib.runOp(5){it*2}        // SAM 转换（Java 接口）→ 18
Lib.getBase2()            // 静态 get/set 不合成属性 → 18
```

## 测试

```kotlin
assertEquals(want, got, "msg"); assertTrue/Null/Contains; assertFailsWith<E>{ }  // → 20
Random(42)                       // 可复现随机 → 20
表驱动 for ((input, want) in table)         // → 20
```

## DSL

```kotlin
@DslMarker annotation class MyDsl          // 封锁外层 this → 23
fun html(b: Tag.() -> Unit): Tag = Tag().apply(b)   // 入口模式 → 23
operator fun invoke(...); router("/a")     // 可调用对象 → 23
infix fun T.should(t: T); 1 should 1       // 中缀 DSL → 23
```

## 坑位索引（实战翻车 TOP）

| 症状 | 原因 | 章 |
|---|---|---|
| `Int + Long` 编译不过 | 无隐式加宽，`.toLong()` | 03 |
| NPE 从 Java 边界漏进来 | 平台类型；边界当 `T?` + 注解 | 04/18 |
| 子类扩展没被调到 | 扩展静态解析，非虚 | 13 |
| 新增枚举/密封分支后行为不对 | when 写了 else 失去穷尽检查 | 08 |
| "排序了没反应" | `sortedBy` 返回新列表 | 10 |
| forEach 里 return 退出整个函数 | inline 非局部返回 | 12 |
| 协程取消不掉 | 死循环无挂起点 | 14 |
| Channel 消费端永远挂起 | 生产者忘 close | 15 |
| Mutex 二次锁死锁 | 不可重入（≠ synchronized） | 15/21 |
| runCatching 吞掉取消 | 协程里别包 CancellationException | 16 |
| 静态 getter 用属性语法报错 | 静态 get/set 不合成属性 | 18 |
| Period.days 数值"不对" | 它是分量；总天数用 ChronoUnit | 19 |
| 原始字符串 `"""…$"""` 编译错 | 行尾 $ 被当模板 | 19 |
| 快照测试偶发红 | 线程名/绝对路径/残留文件进输出 | 20/21/24 |
