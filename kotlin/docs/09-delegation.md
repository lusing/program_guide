# 09 · object、companion 与委托 ⭐

> 对应示例：`examples/09_delegation/`
>
> Kotlin 没有 static——它的替代品（object/companion）+ 语言级委托
> （类委托 by、委托属性 by）是三个"别处没有"的特性，也是 Kotlin
> 框架代码密度高的原因。

## 9.1 object 声明：单例一行搞定

```kotlin
object Registry {
    private val items = mutableMapOf<String, Int>()
    var probes = 0
    fun register(name: String) { probes++; items[name] = items.getOrDefault(name, 0) + 1 }
    fun snapshot(): Map<String, Int> = items.toMap()
}
```

类声明 + 唯一实例同时完成，**线程安全的懒初始化**由类加载机制保证（JVM class init 锁）。对照 Java 的 double-checked locking/enum 单例/holder 模式——全部一行结束。

## 9.2 companion object：类的"静态侧"

```kotlin
class User2 private constructor(val name: String) {     // 构造私有 → 统一入口
    companion object {
        const val MAX_LEN = 12                          // 编译期常量（内联进调用处）
        private var created = 0
        fun of(name: String): User2 {                   // 工厂函数
            require(name.length <= MAX_LEN) { "名字过长: $name" }
            created++
            return User2(name)
        }
        fun createdCount() = created
    }
    fun describe() = "User2($name)"
}
User2.of("张三"); User2.createdCount(); User2.MAX_LEN
```

companion 是"挂在类上的具名单例"。它能实现接口、有名字、能被扩展（13 章）——比 static 强一档。`const val` 只能放常量表达式（原始类型+String），编译期内联。

工厂模式天然友好：构造私有 + companion 工厂是标准搭配（比次构造器重载清爽）。

## 9.3 匿名对象：object expression

```kotlin
val cmp = object : Comparator<Int> {
    override fun compare(a: Int, b: Int) = b - a
}
```

Java 匿名类的等价物，但**能实现多个接口、能访问闭包里的非 final 变量**。事件回调、临时接口实现的标准写法（SAM 接口优先 lambda，12 章）。

## 9.4 类委托 by：组合一行化

```kotlin
class Box<T>(private val items: List<T>) : List<T> by items {   // 全部 List 方法转发
    override fun toString() = "Box(${items.joinToString()})"
    fun countWhere(pred: (T) -> Boolean) = items.count(pred)    // 只补新方法
}
```

`List<T> by items` = 编译器生成全部接口方法的转发（装饰器模式一行版）。**优先组合 over 继承**（Effective Java 第 18 条）在这里从纪律变成了语法。

Java 实现同样的"只读包装"要手写 15 个方法；Kotlin 一行 + 想覆写谁覆写谁。

## 9.5 委托属性 by：属性 = 委托对象

```kotlin
val heavyConfig: Map<String, String> by lazy { ... }    // 惰性
var celsius: Double by Delegates.observable(20.0) { _, old, new -> ... }   // 赋值回调
var safeRange: Double by Delegates.vetoable(20.0) { _, _, new -> new in -50.0..60.0 }  // 可否决
val host: String by map                                // Map 委托
```

四种内置形态：

| 形态 | 语义 | 典型场景 |
|---|---|---|
| `by lazy {}` | 首次访问求值 + 缓存（默认线程安全） | 昂贵配置、UI 绑定 |
| `by Delegates.observable(init) { .. }` | 每次赋值回调（old/new） | 脏标记、审计日志 |
| `by Delegates.vetoable(init) { .. }` | 赋值前谓词，可拒绝 | 字段校验 |
| `by map` | 属性 = map 的键 | 动态配置（Conf(map)） |

`lazy` 的线程模式：默认 `LazyThreadSafetyMode.SYNCHRONIZED`（双检锁）；单线程场景 `lazy(initializer) { }` 前传 `LazyThreadSafetyMode.NONE` 省锁。

## 9.6 自定义委托：两个 operator

```kotlin
class Trimmed(private var raw: String) {
    operator fun getValue(thisRef: Any?, prop: KProperty<*>): String = raw.trim()
    operator fun setValue(thisRef: Any?, prop: KProperty<*>, v: String) { raw = v }
}

class Form { var title: String by Trimmed("  默认标题  ") }   // 读写都过委托
```

约定：`getValue(thisRef, property)` 必须有；可写属性再加 `setValue`。`property` 是反射元数据（名字/类型）——用它做依赖追踪、ORM 映射的钩子。

## 9.7 lateinit vs lazy 总决

| 维度 | `lateinit var` | `by lazy` |
|---|---|---|
| var/val | 只能 var | 只能 val |
| 初始化者 | 外部（DI 框架、setup） | 自己的 lambda |
| 可空性 | 声明为非空 | 推断非空 |
| 换值 | ✓（可重置，测试友好） | ✘（一次定型） |
| 探测 | `::x.isInitialized` | 无（也不需要） |
| 典型 | `@Inject lateinit var svc` | `val db by lazy { connect() }` |

## 9.8 坑位清单

1. **object 的初始化在类加载时**——object 里引用其他类可能触发加载顺序问题；重初始化逻辑放显式 `init`/首次调用。
2. companion 的 `const val` 只能是编译期常量；`val x = System.currentTimeMillis()` 不行（也不该）——运行时求值用普通 `val`（每次类加载算一次）。
3. `by map` 读**缺失的键**抛 `NoSuchElementException`（不是 null）——可选键要 `map["k"] ?: 默认` 或干脆别用 Map 委托。
4. `vetoable` 的谓词**返回 false = 拒绝本次赋值**（旧值保留），不是抛异常。
5. 类委托 `List<T> by items` 转发的是**接口方法**——`equals/hashCode/toString` 是 Any 的方法，不会转发；要控制就自己 override（示例的 Box 就覆写了 toString）。
6. `lazy` 默认线程安全但也意味着**第一次访问有锁开销**；确认单线程用 NONE 模式。
