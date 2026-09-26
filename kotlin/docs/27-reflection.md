# 27 · ⭐注解与反射：KClass、可调用引用与迷你测试框架

> 对应示例：`examples/27_reflection/`
>
> 自定义注解（元注解四件套、参数白名单）、使用处目标 `@get:`/`@field:`/`@param:`、
> KClass/KFunction/KProperty 反射、`::` 可调用引用全谱、泛型反射、手写迷你 @Test 框架。

> 本章需要 `kotlin-reflect.jar`（发行版自带；`kotlin-stdlib` 只含 `::class` 等基础面，
> `declaredFunctions/findAnnotation/typeParameters` 等完整 API 在独立 jar 里）。

## 27.1 声明注解：annotation class

```kotlin
annotation class TestCase(val id: String, val shouldPass: Boolean = true)   // 有默认值

@TestCase("登录")
fun loginTest() { ... }
```

注解类的参数类型有**白名单**：基本类型、String、枚举、KClass、其他注解、以及它们的数组——
`val handler: Runnable` 或 `val req: Request?` 直接编译错（注解要能在编译期落进 class 文件，
所以只能携带常量形态的元数据；参数也不允许非空默认 null 之外的可空性——`val x: String?` 不合法）。

## 27.2 元注解四件套

```kotlin
@Target(AnnotationTarget.FUNCTION, AnnotationTarget.CLASS)   // 能标在哪
@Retention(AnnotationRetention.RUNTIME)                       // 活到运行时（默认！）
@Repeatable                                                  // 同一处可标多次
@MustBeDocumented                                            // 进公开文档
annotation class Route(val path: String)
```

| 元注解 | 作用 | 关键差异 |
|---|---|---|
| `@Target` | 允许标注的位置 | `AnnotationTarget` 全景：CLASS/FUNCTION/PROPERTY/FIELD/CONSTRUCTOR/VALUE_PARAMETER/EXPRESSION/FILE/TYPEALIAS/PROPERTY_GETTER/SETTER…（比 Java 的多且细） |
| `@Retention` | 保留到哪个阶段 | **Kotlin 默认 RUNTIME**（Java 默认 CLASS——跨语言时最常踩的差异） |
| `@Repeatable` | 可重复标注 | 用处不大，Spring 路由类框架用 |
| `@MustBeDocumented` | 文档工具必须展示 | 纯声明性 |

## 27.3 使用处目标：@get: / @field: / @param:

Kotlin 属性在 JVM 上会裂成**三个挂点**（构造参数/幕后字段/getter），注解默认挂哪？规则：`param` > `property` > `field`。想精确指定就加使用处目标前缀：

```kotlin
annotation class Column(val name: String)

class Row(
    @param:Column("构造参数")     // 挂在 Java 构造器参数上
    @field:Column("幕后字段")     // 挂在字段上（JPA @Column 想要的就是它）
    @get:Column("getter")         // 挂在 getter 上（Jackson/JUnit 按方法找注解）
    val id: Int,
    @Column("裸写")               // 不加前缀 → 落到 param（优先级链）
    val name: String,
)
```

用 Java 反射验证落点（`getDeclaredField("id")` / `getMethod("getId")` / 构造器 `parameterAnnotations`）——示例程序会把三个挂点各自看到的注解打印出来。库集成时注解"不生效"十有八九是挂错了点：JPA 要 `@field:`、JUnit 的 `@get:Rule` 要 getter。

## 27.4 ::class 与可调用引用全谱

```kotlin
val k: KClass<String> = String::class        // KClass（Kotlin 侧）
"abc".javaClass                              // Class<String>（Java 侧）
String::class.java                           // KClass → Class
String::class.java.kotlin                    // Class → KClass（往返）
```

函数/属性/构造器都能"拿引用"，它们不只是 lambda 的语法糖——**本身就是反射对象（KFunction/KProperty）**：

```kotlin
fun isOdd(x: Int) = x % 2 != 0
listOf(1, 2, 3).filter(::isOdd)              // 函数引用当值传

val f = ::isOdd
f.name                                       // "isOdd"
f.parameters.map { it.name }                 // [x]
f.returnType                                 // kotlin.Boolean

val up: () -> String = "kot"::uppercase      // 绑定引用：接收者已锁进引用里
val ctor: (Int, Int) -> P = ::P              // 构造器引用
var counter = 0
::counter.set(41); ::counter.get()           // 顶层 var 属性引用可读可写
```

绑定引用 vs 普通引用的类型差异：`String::uppercase` 是 `(String) -> String`，`"kot"::uppercase` 是 `() -> String`——后者适合把"这个对象的这个方法"当回调交出去（Android 的 `this::onUsersLoaded` 同理）。

## 27.5 反射 API：枚举成员并调用

```kotlin
class Calc {
    fun twice(x: Int) = x * 2
    private val secret = 1
}
val kc = Calc::class
kc.declaredFunctions.map { it.name }          // 本类声明的函数（含私有）
kc.memberFunctions                            // 含继承来的（toString/equals…）
kc.primaryConstructor?.call(...)              // 主构造器直接造对象
kc.declaredMemberProperties                   // 属性（KProperty1，可 .get(instance)）

f.call(calc, 21)                              // Kotlin 反射调用
f.javaMethod?.invoke(calc, 21)                // 降到 Java 反射（性能敏感路径可对照）
```

`declared*` 只看本类，`member*` 含继承——选错集合会"明明有这方法却找不到"。

## 27.6 泛型反射：擦除之后还能挖回什么

类型实参在运行时已擦除，但**声明处的形参信息**和**继承链上的实参**都还在：

```kotlin
class Box<T : Comparable<T>>(val value: T)
class StringList : ArrayList<String>()

Box::class.typeParameters                     // [T]
  .forEach { it.name; it.variance; it.isReified; it.upperBounds }   // T / invariant / false / [Comparable<T>]

StringList::class.supertypes                  // [ArrayList<String>, ...]
  .first { it.classifier == ArrayList::class }
  .arguments.first().type                     // kotlin.String ← 擦除后经继承链找回实参！
```

这就是 Gson/Jackson `TypeReference`/`typeToken` 魔法的原理：直接问 `Box<String>::class` 拿不回
`String`（擦除），但创建一个 `object : Box<String>()` 匿名子类，实参就刻进了父类签名里。

## 27.7 实战：手写迷你 @Test 框架

注解（贴元数据）+ 反射（发现并调用）= 一切框架的心脏。30 行造一个测试运行器：

```kotlin
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.RUNTIME)
annotation class TestCase(val id: String, val shouldPass: Boolean = true)

fun runTests(instance: Any): List<String> =
    instance::class.declaredFunctions                     // 1. 反射枚举方法
        .filter { it.hasAnnotation<TestCase>() }          // 2. 按注解筛选
        .sortedBy { it.findAnnotation<TestCase>()!!.id }  // 3. 定序（输出确定）
        .map { f ->
            val a = f.findAnnotation<TestCase>()!!
            try { f.call(instance); if (a.shouldPass) "PASS" else "FAIL(意外通过)" }
            catch (e: Exception) { if (a.shouldPass) "FAIL" else "XFAIL" }   // 4. 反射执行
        }.let { rs -> rs + "汇总: ${rs.size} 例, ${rs.count { it.startsWith("PASS") }} PASS" }
```

`hasAnnotation/findAnnotation` 是泛型函数——`findAnnotation<TestCase>()` 拿回**类型安全的注解实例**
（字段直接 `.id` 可访问），比 Java 的 `getAnnotation(TestCase::class.java)` 干净。

## 本章坑位

- `@Retention` Kotlin 默认 **RUNTIME**、Java 默认 CLASS——反射读不到注解先查这里
- 注解参数类型白名单外（如自定义类）编译不过；参数不能是可空类型
- 库注解"不生效"：JPA 挂字段用 `@field:`、按方法找的用 `@get:`，裸写落 param
- `declared*` 不含继承成员；`member*` 含——找不到方法先想是不是选错集合
- 完整反射 API 在 `kotlin-reflect.jar`，不是 stdlib（CLI 要自己上 classpath）
- `Box<String>::class` 挖不回 String（擦除）；实参只能经**继承链 supertypes** 找回
