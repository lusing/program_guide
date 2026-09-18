# 11 · 泛型 ⭐

> 对应示例：`examples/11_generics/`
>
> Kotlin 泛型 = Java 的"使用处通配符"升级成**声明处型变**（out/in），
> 再加 **reified**（inline 函数里保留类型实参）。
> 类型擦除依然存在——知道边界才知道 reified 为什么是半张门票。

## 11.1 泛型类与函数

```kotlin
class Box<T>(private val item: T) {
    fun get(): T = item
}
fun <T : Comparable<T>> maxOf3(a: T, b: T, c: T): T = maxOf(a, maxOf(b, c))
```

`<T : Any>` 把泛型钉成非空（默认 `T : Any?`，可传 null——04 章提过）。

## 11.2 为什么需要型变：数组协变之坑

Java 数组是协变的：`Object[] objs = new String[1]; objs[0] = 42;` 编译过、运行时 ArrayStoreException。**只读的数据可以安全协变，可写的不行**——Kotlin 把这条安全边界写进了类型系统。

## 11.3 out：协变（生产者）

```kotlin
interface Producer<out T> {          // T 只出现在"产出"位置（返回值）
    fun produce(): T
}

val p: Producer<Animal> = CatFarm(Cat())   // Producer<Cat> 当 Producer<Animal> 用 ✓
```

`out T` 承诺"只生产不消费 T"——产出 Cat 的地方当然也产出 Animal（Cat 是 Animal）。于是 `List<Cat>` 可以赋给 `List<Animal>`：**标准库的 List 声明就是 `List<out E>`**（所以 10 章能写出 `val animals: List<Animal> = listOf(Cat(), Dog())`）。

## 11.4 in：逆变（消费者）

```kotlin
interface Consumer<in T> {           // T 只出现在"消费"位置（参数）
    fun consume(x: T)
}

val c: Consumer<Cat> = AnyConsumer()        // Consumer<Animal> 当 Consumer<Cat> 用 ✓
```

能吃任何 Animal 的消费者当然能吃 Cat——方向反过来了。`Comparator<in T>` 是库里的经典：`sortedWith(compareBy<Animal> { ... })` 能排 List<Cat>。

记忆法（C# 发明的 PECS 简化版）：**out = 生产者（往外给），in = 消费者（往里收）**。函数类型的参数是 in、返回是 out：`(R) -> T` 实际是 `Function1<in R, out T>`。

## 11.5 星投影 `*`：类型实参未知

```kotlin
val unknown: List<*> = listOf(1, "二", 3.0)   // 元素类型不知道，但知道是"某种 List"
unknown.size                                        // ✓ 与 T 无关的操作
val first: Any? = unknown.first()                   // ✓ 读出来只能是 Any?
fun printSize(xs: List<*>) = println(xs.size)       // API 不关心元素类型时用它
```

`List<*>` ≈ Java 的 `List<?>`。能读（Any?）、不能写（编译器拒绝 `add`）——安全默认。

## 11.6 多重约束：where

```kotlin
fun <T> longerOf(a: T, b: T): T
        where T : CharSequence, T : Comparable<T> =
    if (a.length >= b.length) a else b
```

单上界写在 `<T : X>`；多个上界只能 `where`。String 同时满足两约束所以能调。

## 11.7 reified：把泛型实参带进运行时

```kotlin
inline fun <reified T> List<Any>.pick(): List<T> = filterIsInstance<T>()

inline fun <reified T> Any?.isA(): Boolean = this is T    // 普通 fun 里 this is T 是编译错！

mixed.pick<Int>()      // [1, 2]
42.isA<Int>()          // true
```

原理：`inline` 函数把**函数体复制进调用处**——`T` 在调用点被替换成具体类型，`is T` 就变成了 `is Int`。这是编译器魔法不是运行时魔法，所以：

- reified 必须 inline（成本：函数体膨胀）；
- 只能判断类，拿不到 `T::class` 以外的注解/泛型嵌套信息（那需要 kotlin-reflect）。

对比 Java：`pick(List.class)` 传 Class 对象的样板在 Kotlin 里消失。`filterIsInstance<T>()`、`enableApiVersion<T>()` 这类 API 全靠它。

## 11.8 类型擦除：泛型只活在编译期

```kotlin
val li: List<Int> = listOf(1)
val ls: List<String> = listOf("a")
li::class == ls::class                 // true！运行时都是 ArrayList
// if (li is List<Int>) {}             // ← 编译错：无法检查被擦除的参数
val anyList: Any = li
anyList is List<*>                     // ✓ 星投影是唯一能查的形态
li::class.java.name                    // java.util.Collections$SingletonList
```

泛型信息编译后抹掉（JVM 字节码层面 `List<Int>` 与 `List<String>` 是同一个类）——所以运行时检查只能到 `List<*>` 这一层。`.java` 属性是从 KClass 通往 JVM Class 的逃生舱（打印类名、反射操作）。

## 11.9 与其他语言对照

| 语言 | 型变 | 泛型运行时 | 代价 |
|---|---|---|---|
| Kotlin | 声明处 out/in | 擦除（reified 例外） | 零运行时成本 |
| Java | 使用处 `? extends` / `? super` | 擦除 | 通配符噪音 |
| C# | 声明处 out/in | **具化**（每个 T 一份机器码） | 代码膨胀 |
| Rust | 无型变（生命周期另算） | **单态化** | 编译慢、二进制大 |
| Go | 无型变（结构化约束） | 擦除（字典/GCShape） | 约束表达力弱 |

Kotlin 的取舍：擦除换互操作（字节码和 Java 完全互通），reified 补最高频的痛点。

## 11.10 坑位清单

1. **`is List<Int>` 编译错**——擦除。要运行时类型就星投影 + 元素逐个 `is`，或 reified 函数包一层。
2. reified 脱离 inline 不存在——不能在普通函数/类上声明 `reified`；抽象 API 想暴露它，只能 public inline + `@PublishedApi` internal 实函数。
3. **型变是接口契约不是实现细节**：给自己的类标 `out T` 前，检查 T 是否真的只出现在产出位（private var item: T 也算消费位，会编译错——Box<T> 不可 out，除非 item 变只读）。
4. 星投影的读是 Any?，写是禁止——拿 `MutableList<*>` 当参数时编译器什么都拦，基本说明 API 设计错了。
5. 泛型默认可空：`class Box<T>(val x: T)` 的 x 可空——要非空 `T : Any`。
6. `filterIsInstance` 内部就是 reified——别自己再写一遍。
