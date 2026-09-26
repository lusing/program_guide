# 28 · inline 进阶：非局部返回、crossinline 与自造控制流

> 对应示例：`examples/28_inline/`
>
> 内联的原理与代价、非局部返回（`forEach` 里裸 `return` 的真相）、noinline/crossinline、
> `@PublishedApi`、inline 属性——最后用这些知识**自造控制流**：`repeatUntilError`/`tryFewTimes`。

## 28.1 内联是什么：拷贝，不是调用

`inline fun` 把**函数体 + lambda 实参体**一起拷贝到调用点，运行期根本没有这次调用：

```kotlin
inline fun printExecutionTime(block: () -> Unit): Long {
    val start = System.nanoTime()
    block()
    return System.nanoTime() - start          // 返回纳秒差，数值不进快照
}
```

收益有二：**lambda 不装箱成 Function 对象**（零分配），以及下一节的**非局部返回**。代价是调用点字节码膨胀——把 50 行的大函数标 inline、再在 N 处调用，就是把 50 行复制 N 份。标准库的 `forEach/map/filter` 之所以标 inline，正是不想让你在循环里分配对象。

## 28.2 非局部返回：forEach 里裸 return 的真相

```kotlin
fun firstNegative(xs: List<Int>): Int? {
    xs.forEach { if (it < 0) return it }     // return 退出的是 firstNegative！
    return null
}
```

普通 lambda 里 `return` 只能带标签（`return@forEach`）——因为 lambda 是独立对象，凭什么替外层函数做返回？**inline lambda 的体被拷进外层函数**，`return` 天然就是外层的。反过来看（12 章的坑）：`forEach { return }` 想只跳过当轮却退出了整个函数，根因就在这。

自己写个**非内联**版就能对照出差异：

```kotlin
fun <T> eachSlow(xs: List<T>, f: (T) -> Unit) { for (x in xs) f(x) }   // 没有 inline

eachSlow(xs) { if (it < 0) return it }     // ✗ 编译错：'return' is not allowed here
eachSlow(xs) { if (it < 0) return@eachSlow }   // ✓ 只能标签返回
```

## 28.3 自造控制流：让函数"长得像语言结构"

`repeat`/`forEach` 的样子——名字在前、尾随 lambda 在后、体内像写语句——任何 inline 函数都能做。两个实用件：

```kotlin
/** 重复执行直到抛出约定异常，返回成功次数（读文件读到 EOF 就是这个形状） */
inline fun repeatUntilError(block: () -> Unit): Int {
    var n = 0
    try { while (true) { block(); n++ } }
    catch (e: IllegalStateException) { return n }
}

/** 重试最多 maxAttempts 次，block 返回 true 表示成功；返回实际尝试次数 */
inline fun tryFewTimes(maxAttempts: Int, block: (attempt: Int) -> Boolean): Int {
    var a = 0
    while (a < maxAttempts) { a++; if (block(a)) return a }
    return a
}
```

调用处完全像关键字：

```kotlin
val reads = repeatUntilError {
    if (cursor >= data.size) error("EOF")     // error() 抛 IllegalStateException
    cursor++
}
val used = tryFewTimes(5) { attempt -> attempt >= 3 }   // 第 3 次成功 → 3
```

这就是 Kotlin "可扩展语言感"的来源——`runBlocking`/`withTimeout` 全是这一招。

## 28.4 noinline：lambda 要当对象用时

inline 函数的 lambda 参数默认"会展开"，**不能当对象存起来或传给别的函数**。要存（延迟执行、放队列、注册回调）就标 `noinline`——它退回普通 Function 对象：

```kotlin
inline fun later(noinline block: () -> String, onRegister: (String) -> Unit = {}): () -> String {
    onRegister("已注册")     // 这个 lambda 照常内联展开
    return block             // block 当对象返回出去（noinline 的存在意义）
}

val saved = later({ "延迟求值" }) { println(it) }   // saved 是个真对象，随时调用
saved()
```

实测坑：**noinline 是唯一函数参数时 K2 同样告警** insignificant impact（一个 lambda 都没内联，inline 白标了）——所以要配一个真正内联的函数参数（如上面的 `onRegister`）。

## 28.5 crossinline：lambda 跑到别的执行上下文时

inline lambda 的体被拷进**另一个非内联 lambda**（如 `Runnable { block() }`）时，非局部返回的语义就乱了——外层函数可能已经返回。编译器要求这种参数标 `crossinline`（承诺不非局部返回）：

```kotlin
inline fun runAsTask(crossinline block: () -> Unit): Runnable = Runnable { block() }

val logs = mutableListOf<String>()
runAsTask { logs.add("任务体执行") }.run()     // 同步 run；真实项目里可能丢给线程池
```

`crossinline` 的 lambda 里裸 `return` 编译不过，只能 `return@runAsTask`——Android 的 `runOnUiThread { }` 正是这个形状（历史上它就是 crossinline 的教科书用例）。

## 28.6 public inline 的可见性红线与 @PublishedApi

public inline 函数体会被**拷贝进别的模块**，所以它不能引用 `internal`/`private` 成员（否则等于把私有实现泄漏到模块外，编译器直接拒绝）。但有时确实想"公开一个薄内联壳、实现藏起来"——用 `@PublishedApi` 白名单：

```kotlin
@PublishedApi
internal fun internalHelper(): String = "内部实现（承诺不改签名，等于公开）"

inline fun publicInlineApi(): String = internalHelper()   // ✓ 放行；去掉 @PublishedApi 则编译错
```

`@PublishedApi` 是"我担保这是事实公开"的承诺——外部模块已经能内联进它了，改签名就是破坏性变更。另一个实测坑：**public inline 函数没有函数类型参数时 K2 直接告警**（"expected performance impact from inlining is insignificant"，`-Werror` 必挂）——所以上面的壳带了个默认值的 lambda 参数。

## 28.7 inline 属性与 reified 回顾

无幕后字段的属性访问器也能 inline（getter 拷到访问点，连属性访问都省了）：

```kotlin
inline val tag: String get() = "无幕后字段的内联属性"
```

以及 11 章讲过的铁律在此闭环：**`reified` 只能用在 inline 函数**——具体化的前提是函数体在调用点展开、类型实参在编译期可见：

```kotlin
inline fun <reified T> typeName(): String? = T::class.simpleName   // 泛型当真类型用
typeName<List<Int>>()        // "List"——擦除世界里唯一能拿到实参的路子
```

## 本章坑位

- 大函数体标 inline = 字节码膨胀；inline 是给"小函数 + lambda 参数"用的
- 非 inline 的高阶函数里裸 `return` 编译不过——先看函数声明有没有 `inline`
- 要把 lambda 存对象/传出去 → `noinline`；要包进别的 lambda 执行 → `crossinline`
- public inline 引 internal 成员编译错 → `@PublishedApi internal`（承诺=公开）
- `reified` 离开 inline 不存在；`inline val` 必须无幕后字段
