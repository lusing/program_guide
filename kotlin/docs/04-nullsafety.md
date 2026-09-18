# 04 · 空安全 ⭐

> 对应示例：`examples/04_nullsafety/`
>
> Kotlin 最著名的特性。核心思想一句话：**"可能为 null"是类型的一部分**——
> `String` 里存不进 null，能存 null 的是 `String?`，两种类型用起来规则不同。
> 十亿美元错误（Tony Hoare 论 null）在编译期被拦住。

## 4.1 类型即空安全

```kotlin
val s: String = "abc"
val t: String? = null        // 可空是另一种类型，不是修饰

s.length                     // ✓ 编译器保证非空
// t.length                  // ✘ 编译错：t 可能是 null
// val bad: String = null    // ✘ 编译错：null 不是 String
```

对照：Java 的 NPE 是运行时惊喜；Rust 用 `Option<T>`（`String` vs `Option<String>` 几乎同构）；Go 的 nil 接口坑靠人肉防。Kotlin 的差异在**语法糖的甜度**——下面这些操作符让你不必到处 `match`。

## 4.2 安全调用 `?.`：链式下钻

```kotlin
data class User(val name: String?, val email: String?)

val host = u?.email?.substringAfter('@') ?: "无域名"
```

链条上任何一环是 null，整个表达式就是 null——不会中途 NPE。等价的 Java 是四层嵌套 if；等价的 Rust 是 `u.and_then(|u| u.email).and_then(...)`。

## 4.3 Elvis `?:`：null 时的默认/出口

```kotlin
val name = u?.name ?: "匿名"          // 默认值
val v = maybe ?: return               // 提前返回
val x = maybe ?: error("必须有值")     // 直接抛异常（16 章）
```

名字来自侧过来的猫王发型。右侧可以是任意表达式（包括 `return`/`throw` 这种 `Nothing` 型，16 章展开这个技巧）。

## 4.4 判空后的智能转换

```kotlin
val email = u.email
if (email != null) {
    println(email.uppercase())        // ✓ email 自动智能转换为 String
}
email?.let { println(it.uppercase()) }   // 函数式等价写法
```

`?.let {}` 是"非空才执行一段逻辑"的惯用法。但注意**嵌套 `?.let` 会缩进地狱**——三 层以上判空，改用"提前返回"（Elvis 返回默认值）或重新建模（让类型不可空）。

## 4.5 `!!`：断言非空（最后一个手段）

```kotlin
val forced = u2.name!!        // 是 null 就抛 NullPointerException
```

它合法，但每次写都是在说"我比编译器懂"。合理场景：框架保证初始化顺序、测试里的确定值。滥用 `!!` 等于把 Java 的 NPE 搬回来。出现 `!!` 链时，优先怀疑类型建模错了。

## 4.6 安全转换 `as?` 与过滤 `filterNotNull`

```kotlin
fun lengthIfText(x: Any): Int? = (x as? String)?.length
// as: 不是目标类型 → ClassCastException；as? → null

listOf("18", "x", "").map { it.toIntOrNull() }   // [18, null, null]
    .filterNotNull()                             // [18] —— 顺带获得 List<Int>（非空元素）
```

`toIntOrNull()` 这类 `xxxOrNull` 家族是解析类 API 的标配——**解析失败是正常分支，不是异常**（对照 Java 的 `Integer.parseInt` + try/catch）。

## 4.7 takeIf / takeUnless：值过滤谓词

```kotlin
val even = 4.takeIf { it % 2 == 0 }        // 4（谓词真 → 接收者；假 → null）
3.takeIf { it % 2 == 0 }                   // null
```

和 `?:` 组合成"校验 + 默认"一行流。别过度——两步以上的逻辑，普通 if 更可读。

## 4.8 lateinit：非空但要晚点初始化

```kotlin
class Config {
    lateinit var endpoint: String            // 不给初值，承诺"用之前会初始化"
    fun ready() = ::endpoint.isInitialized   // 可探测
}
```

解决"字段非空、但构造时拿不到值"的场景（依赖注入、测试 setup）。规则：

- 只能 `var`（可重新赋值，比如测试重置）；类型必须非空非原始。
- 初始化前访问 → `UninitializedPropertyAccessException`（比 NPE 消息明确）。
- 和 `by lazy`（09 章）的选型：**lateinit = var、外部初始化、可换值**；**lazy = val、首次访问算一次、永久缓存**。

## 4.9 可空性是穿透的

```kotlin
val ages: List<Int?> = listOf(18, null, 33)   // 元素可空
val m: Map<String, Int?> = mapOf("b" to null) // 值可空——map["不存在的键"] 与 "值为 null" 无法用 get 区分！
fun <T> identity(x: T): T = x                 // T 默认可空（上界是 T : Any?）
fun <T : Any> strict(x: T): T = x             // 上界 Any = 非空泛型（11 章泛型细讲）
```

`map["k"]` 返回 null 有歧义（键不存在 vs 值就是 null）——要区分用 `containsKey` 或 `getValue`（值缺失抛异常）。

## 4.10 与 Java 互操作：平台类型（18 章细讲）

Java 的引用没空性信息，Kotlin 称之为**平台类型** `String!`——编译器放行，风险回归。解法是注解（JetBrains `@Nullable`/JSR-305）让边界收紧。本章记住结论：**Java 边界上的值一律先当 `T?` 对待**。

## 4.11 坑位清单

1. **`?.let` 嵌套三层 = 重构信号**。提前返回（Elvis）或改类型建模。
2. `!!` 出现在库代码里 = 代码异味；出现在跨语言边界 = 先检查是不是该声明成可空。
3. `lateinit` 的 `isInitialized` 只能**同一类内**通过 `::prop` 引用访问。
4. 泛型参数默认可空：`fun <T> f(x: T)` 能传 null；要非空写 `<T : Any>`。
5. `as?` 链别忘了后面的 `?.`：`(x as? String)?.length`——`as?` 结果本身可空。
6. `Map<K, V?>` 的 `[]` 歧义：null 分不清"没这个键"和"值就是 null"。
7. 数组/集合里的 null 传染：`List<Int?>` 与 `List<Int>` 是不同类型，混用会编译错（这是特性不是坑——逼你显式决策）。
