# 09 · object 与委托

> 对应示例：`examples/09_delegation/`（含 Registry 单例、User2 伴生工厂、Box 类委托、lazy、observable/vetoable、Trimmed 自定义委托、Conf Map 委托、notNull、Basket 经典坑、ReadOnlyProperty/ReadWriteProperty 接口式委托）。全部代码经四层验证：`kotlinc -Werror` 零告警 → kotlin.test 单测通过 → 运行 exit 0 → 输出与 `expected.txt` 逐字节一致。环境：Kotlin 2.4.21（K2）+ JDK 21。

这一章讲 Kotlin 的两个"关键字级"设计模式：`object` 把单例做成了语言特性，`by` 把委托做成了语言特性。在 Java 里这两件事都要手写样板代码（双重检查锁、转发方法几十个），写错的空间很大；Kotlin 把它们收进编译器，一行声明，语义标准化。

---

## 9.1 为什么要把"委托"做成关键字

《Effective Java》推崇"组合优于继承"，但组合的痛点是转发代码：想把一个 `List` 包装一层、只加一个方法，就得把 `List` 接口的三十多个方法全部手写转发。Getter/setter 也类似——"延迟初始化""赋值时通知"这类横切需求，每个属性都得复制粘贴同一段逻辑。

委托（delegation）就是把"把调用转给另一个对象/另一段代码"这件事标准化。Kotlin 提供两级：

- **类委托** `class X : I by impl`——接口的全部方法自动转发给 `impl`；
- **委托属性** `val p by delegate`——属性的读写交给 `delegate` 的 `getValue`/`setValue`。

stdlib 内置了最常用的几种委托（`lazy`、`observable`、`vetoable`、`notNull`、Map 委托），自定义委托也只需两个 operator 函数。本章的示例把两类委托全部跑了一遍——类委托一节，委托属性五节，外加一个专门讲边界的收尾节。

---

## 9.2 object：声明即单例

```kotlin
object Registry {
    private val items = mutableMapOf<String, Int>()
    var probes = 0
    fun register(name: String) { probes++; items[name] = items.getOrDefault(name, 0) + 1 }
    fun snapshot(): Map<String, Int> = items.toMap()
}
```

`object Registry` 同时完成了"声明一个类"和"创建它的唯一实例"——访问 `Registry.register(...)` 就是在用这个实例。没有构造器调用、没有 `getInstance()`、没有线程安全问题（JVM 类加载机制保证初始化只发生一次）。

`register` 里的 [`getOrDefault`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.collections/get-or-default.html) 是 Map 的扩展函数：key 存在取值、不存在给默认值 0，所以"计数加一"一行写完。`snapshot()` 返回 `items.toMap()` 的拷贝，调用方改不动内部状态。

三次 register 之后：

```text
Registry: {a=2, b=1}（probes=3）
```

`a` 注册了两次所以是 2，`probes` 记录总调用次数。测试验证了单例的跨调用累积性：先 `register("x")` 记下值，再注册一次，`assertEquals(before + 1, ...)`——两次调用打到的是同一个实例。

**何时用 object**：全局唯一的注册表、配置持有器、无状态的工具类。注意单例本质是全局状态，测试之间会互相影响（09 章的坑位清单还会回到这一点）。

`object` 还有一种用法是**对象表达式**（匿名对象）：`val listener = object : ClickListener { override fun onClick() = ... }`，对应 Java 的匿名内部类。示例没有用到，语法记住 `object : 接口 { ... }` 即可。

---

## 9.3 companion object：类的"静态"面

Kotlin 没有 `static` 关键字。类级别的常量和工厂函数放在伴生对象里：

```kotlin
class User2 private constructor(val name: String) {
    companion object {
        const val MAX_LEN = 12                       // 编译期常量
        private var created = 0
        fun of(name: String): User2 {                // 工厂函数（主构造私有，统一入口）
            require(name.length <= MAX_LEN) { "名字过长: $name" }
            created++
            return User2(name)
        }
        fun createdCount() = created
    }
    fun describe() = "User2($name)"
}
```

三个设计联动：

1. **`private constructor`** 把主构造器封死，外部只能走 `User2.of(...)`——所有实例都经过工厂的校验与计数。工厂函数比构造器强的地方在于：可以返回缓存实例、可以返回子类型、名字还能表意（`of`、`from`、`empty`）。
2. **`const val MAX_LEN = 12`** 是真正的编译期常量（只能用于 String/基本类型），编译后直接内联到使用处，Java 侧也能当 `public static final` 用。
3. 伴生对象本质上是一个**具名 object**——它实现接口、持有状态（`created`）都没问题，只是访问时可以省略名字写 `User2.MAX_LEN`。

输出：

```text
User2(张三), User2(李四), 共创建 2 个（MAX_LEN=12）
```

测试守住工厂的校验职责：`assertFailsWith<IllegalArgumentException> { User2.of("这个名字超过十二个字符真的不行") }`——超长名字被 `require` 拒掉。

**companion 不是 static 的语法糖**这点值得强调：Java 的 static 成员属于类，而 companion 是一个真实存在的对象实例，能传参、能实现接口。日常使用时感知不强，但这个差别让"把工厂本身注入为依赖"成为可能。

---

## 9.4 类委托 `by`：组合终于不用写样板了

回到开头的问题：包装一个 `List`、只加一个方法。Java 要手写三十多个转发方法，Kotlin 一行：

```kotlin
class Box<T>(private val items: List<T>) : List<T> by items {
    override fun toString() = "Box(${items.joinToString()})"
    fun countWhere(pred: (T) -> Boolean) = items.count(pred)   // 只补想要的新方法
}
```

`: List<T> by items` 让编译器把 `List<T>` 接口的**全部方法**转发给构造参数 `items`。`Box` 白得 `size`、`get`、`filter`、`contains` 等一切 List 能力，自己只写两样：覆写 `toString()`，加新方法 `countWhere`。这一用法在 2018–2020 年的 Kotlin 书里就很常见，到今天仍是"组合优先"的标准写法——07 章说"能组合就别继承"，`by` 就是把组合的代价打到零的那颗糖。

运行：

```text
box.size = 5, box[2] = 3          // List 接口全部转发
box.countWhere{偶数} = 2    // 自己加的新能力
```

测试里特别验证了一条容易忽视的性质：**转发来的扩展函数也照常工作**——`assertEquals(listOf(2, 4), box.filter { it % 2 == 0 })`。`filter` 是 `Iterable<T>` 的扩展函数，底层调迭代器，而迭代器正是被转发的方法之一。

两条边界要记住：

- 委托关系编译期固定，`items` 不能在运行时换成另一个 List；
- 想覆写哪个方法直接写 `override`，其余照旧转发——覆写粒度是单个方法，不是一换全换。

与继承对比着看更有味道：若让 `Box` 继承某个 `AbstractList`，得到的是"是一个 List"的强耦合，父类一改实现你就跟着震；类委托是"有一个 List 替它干活"，`items` 从构造器注入，测试时传个假实现都方便。

---

## 9.5 委托属性之 lazy：首次访问才计算

```kotlin
val heavyConfig: Map<String, String> by lazy {
    println("  [lazy] heavyConfig 只算这一次！")
    mapOf("host" to "localhost", "port" to "8080")
}
```

[`lazy`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin/lazy.html) 是最常用的委托：lambda 里的初始化代码**推迟到第一次读属性时**执行，结果缓存，之后再读直接返回。输出把"只算一次"演给你看：

```text
第一次读 heavyConfig:
  [lazy] heavyConfig 只算这一次！
  host=localhost
第二次读 heavyConfig:
  port=8080（没有再打印 [lazy] 日志——已缓存）
```

测试用一个计数器把语义钉死：

```kotlin
var computed = 0
val x: Int by lazy { computed++; 7 }
assertEquals(0, computed)          // 没访问前不计算
assertEquals(7, x); assertEquals(1, computed)
assertEquals(7, x + 0); assertEquals(1, computed)   // 再访问也不重算
```

两个工程要点：

- **默认线程安全**：`lazy` 默认 `SYNCHRONIZED` 模式，多线程并发首访也只算一次；确定单线程环境可用 `lazy(LazyThreadSafetyMode.NONE)` 省掉同步开销。
- **初始化代价大且不一定用得上**才用 lazy——例子里的 `heavyConfig` 是"读配置文件"这类重活的替身。轻量属性用它反而增加一层委托调用的开销。

---

## 9.6 observable 与 vetoable：赋值拦截

[`Delegates.observable`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.properties/-delegates/observable.html) 在**每次赋值后**回调；[`Delegates.vetoable`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.properties/-delegates/vetoable.html) 在**赋值前**裁决，回调返回 `false` 就否决这次写入：

```kotlin
class Temperature {
    var celsius: Double by Delegates.observable(20.0) { _, old, new ->
        println("  [observable] $old ℃ → $new ℃")
    }
    var safeRange: Double by Delegates.vetoable(20.0) { _, _, new -> new in -50.0..60.0 }
}
```

回调签名的三个参数是 `KProperty<*>`（属性元数据，这里用 `_` 忽略）、旧值、新值。运行：

```text
  [observable] 20.0 ℃ → 25.5 ℃
  [observable] 25.5 ℃ → 30.0 ℃
safeRange 最终 = 45.0（999 被否决）
```

`celsius` 两次赋值各打一条日志；`safeRange = 999.0` 因为 `999 !in -50.0..60.0` 被否决，属性保持 45.0。测试把否决语义写成断言：赋 100.0 后读回来仍是 10.0。

**何时用**：observable 适合"状态变化要刷新 UI/写日志/同步缓存"；vetoable 适合把校验规则钉在属性上，让非法值根本进不来。相比手写 setter，好处是逻辑可复用——同一个委托实例可以给一个类的多个属性用。

---

## 9.7 自定义委托：getValue / setValue

内置委托不够用时，自己写一个类，提供两个 `operator` 函数即可：

```kotlin
class Trimmed(private var raw: String) {
    operator fun getValue(thisRef: Any?, prop: KProperty<*>): String = raw.trim()
    operator fun setValue(thisRef: Any?, prop: KProperty<*>, v: String) { raw = v }
}
class Form { var title: String by Trimmed("  默认标题  ") }
```

- `getValue(thisRef, prop)`：`thisRef` 是属性所属的宿主对象（顶层属性为 null），`prop` 是 [`KProperty`](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.reflect/-k-property/index.html) 元数据（能拿到属性名，做日志很有用）。
- `setValue` 多一个新值参数；只读 `val` 的委托只需 `getValue`。
- `Trimmed` 的策略是**读时 trim**：存原始值，每次取出都去过空白。输出：

```text
title 初始 = '默认标题'（读值时 trim）
title 赋值后 = '新标题'
```

测试覆盖了写路径：`f.title = "  A B  "` 后读出 `"A B"`。

自定义委托的典型应用：属性持久化（读写落到 SharedPreferences/文件）、校验、单位换算、弱引用缓存。凡是"get/set 里想写同一段逻辑"的场景，都值得想一次"能不能抽成委托"。

---

## 9.8 Map 委托：配置项直接当属性

```kotlin
class Conf(private val map: Map<String, Any?>) {
    val host: String by map
    val port: Int by map
    val debug: Boolean by map
}
```

`by map` 让属性的读写落到 Map 上：**属性名就是 key**，值从 `map["host"]` 取并强转。于是 JSON 反序列化出来的一包 `Map<String, Any?>` 可以直接当强类型对象用：

```text
db.local:5432 debug=true
```

边界在测试里：**缺 key 在读值时抛异常**（`assertFailsWith<Exception> { C2(emptyMap()).missing }`）——因为属性声明是 `val missing: String`（非空），Map 里又没有，只能炸。容错的做法是把属性声明成可空类型，或者读前 `map.containsKey` 自查。这一"Map 当动态对象"的用法在 2018–2020 年的 Kotlin 书里常见于配置解析与脚本桥接场景，今天更推荐 kotlinx.serialization 这类真反序列化，但 Map 委托在写脚本、读简单配置时依然顺手。

---

## 9.9 notNull 与 observable 的边界

最后两个"知道边界才不踩雷"的委托。

**`Delegates.notNull<T>()`**（[官方文档](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.properties/-delegates/not-null.html)）：读前必须先赋值，否则抛 `IllegalStateException`：

```kotlin
class Service { var name: String by Delegates.notNull() }
```

```text
notNull 未初始化即读: Property name should be initialized before get.
赋值后: main-service
```

它常被拿来和 `lateinit` 比。`lateinit var` 也是"先声明后赋值"，但有三条硬限制：不能用于基本类型（`Int`/`Double` 等）、不能用于可空类型、不能用于顶层/局部变量。notNull 全类型通吃，代价是每次读写多走一层委托调用，略慢。示例末尾自己总结了一行：

```text
选型: lateinit 更快但不能用于基本类型/顶级属性；notNull 全类型可用但要过委托调用
```

**observable 的经典坑——它只盯"赋值"，不盯"内部改动"**：

```kotlin
class Basket {
    val changes = mutableListOf<String>()
    var fruits: MutableList<String> by Delegates.observable(mutableListOf("苹果")) { _, o, n ->
        changes += "$o → $n"
    }
}
```

`b.fruits.add("梨")` 改的是列表**内部**，`fruits` 这个引用没换——setter 没跑，回调不触发。只有 `b.fruits = mutableListOf(...)` 整体换引用才算"赋值"。输出对照：

```text
内部 add 后内容=[苹果, 梨]，但 observable 记录数=0（引用没换，没触发！）
整体换引用: 记录数=1，最后一条=[苹果, 梨] → [苹果, 梨, 西瓜]
```

测试同样钉死这条边界：`add` 后 `assertEquals(0, b.changes.size)`，换引用后 `assertEquals(1, ...)`。**工程对策**：要盯集合内部变化，要么用不可变集合 + 整体换值（函数式风格，observable 天然契合），要么放弃 observable 改用带通知的集合实现。拿 observable 包 `MutableList` 再指望监听 `add`，是最常见的误用。

---

## 9.10 委托属性的接口形式：ReadOnlyProperty / ReadWriteProperty

9.7 的自定义委托靠的是"约定"——类里恰好有 `getValue`/`setValue` 签名，编译器就认。标准库把这份约定固化成了两个接口，住在 [kotlin.properties](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.properties/) 包（API 索引里与 kotlin.reflect 并列的那包）。示例把它们和 9.7 的 `Trimmed` 对照实现（`src/Main.kt` 第 18-33 行）：

```kotlin
import kotlin.properties.ReadOnlyProperty
import kotlin.properties.ReadWriteProperty
import kotlin.reflect.KProperty

/** ReadOnlyProperty：只读委托一个 getValue 就够（对照：lazy 走的是 Lazy<T> 的 getValue 运算符扩展，没实现这个接口） */
class Constant(private val v: String) : ReadOnlyProperty<Any?, String> {
    override fun getValue(thisRef: Any?, property: KProperty<*>): String = v
}

/** ReadWriteProperty：可写委托 = getValue + setValue（Trimmed 的接口化写法） */
class Trimmed2 : ReadWriteProperty<Any?, String> {
    private var raw = ""
    override fun getValue(thisRef: Any?, property: KProperty<*>): String = raw.trim()
    override fun setValue(thisRef: Any?, property: KProperty<*>, value: String) { raw = value }
}

class Form2 {
    val title: String by Constant("订单")     // 只读：编译期就定了谁来实现
    var note: String by Trimmed2()            // 可写：接口强迫两个函数都实现，漏一个编译不过
}
```

三个知识点：

- **`ReadOnlyProperty` 只有一个 `getValue`**（[文档](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.properties/-read-only-property/index.html)），给 `val` 属性当委托；**`ReadWriteProperty` 要 `getValue` + `setValue` 成对实现**（[文档](https://kotlinlang.org/api/core/kotlin-stdlib/kotlin.properties/-read-write-property/index.html)），给 `var` 用。只读属性接了个可写委托（或反过来）编译期就报错——接口把"这个委托能不能写"变成了**类型信息**，而不只是约定。
- 两个方法的第一参数 `thisRef` 是**被委托属性所在的对象**（顶层属性为 null），第二参数 `property: KProperty<*>` 是属性自身的反射句柄（名字、注解、返回类型都能查）。本例没用它们，但框架型委托（按属性名查 Map、按注解换行为）全靠这两个参数——`thisRef` 可空正是为顶层属性准备的。
- **`by lazy` 走的不是接口而是运算符扩展**：stdlib 给 `Lazy<T>` 定义了一个 `operator fun getValue(thisRef, property)` 扩展，所以 `Lazy` 自己**没有**实现 `ReadOnlyProperty`（本地实测：`Lazy<Int>` 赋不到 `ReadOnlyProperty<Any?, Int>`，编译不过）。这反过来证明了"约定式委托"的威力——不需要接口，一个签名正确的运算符扩展就能让任意类型当委托；`ReadOnlyProperty`/`ReadWriteProperty` 只是把这份约定固化成类型。理解了这两条路（约定 / 接口），标准库委托就不是黑魔法。

演示与输出（`expected.txt` 第 29-31 行）：

```kotlin
println("== 9.10 委托属性接口：ReadOnlyProperty / ReadWriteProperty ==")
val f2 = Form2()
println("title = ${f2.title}（ReadOnlyProperty：只实现 getValue）")
f2.note = "  草稿  "
println("note 赋值 '  草稿  ' 读出 '${f2.note}'（ReadWriteProperty：get + set 成对）")
```

```
== 9.10 委托属性接口：ReadOnlyProperty / ReadWriteProperty ==
title = 订单（ReadOnlyProperty：只实现 getValue）
note 赋值 '  草稿  ' 读出 '草稿'（ReadWriteProperty：get + set 成对）
```

`title` 恒为构造时给定的 `"订单"`；`note` 存原值、读时 trim——与 9.7 的 `Trimmed` 行为一致，区别只在这个类**声明了自己是谁**。测试 `testPropertyInterfaces` 断言三条：`assertEquals("订单", f.title)`、`f.note = "  A B  "` 后读回 `"A B"`、再赋 `"x"` 读回 `"x"`（trim 对无空白串是恒等）。

kotlin.properties 包还有一个**绑定期钩子**值得知道：委托类自己定义一个 `operator fun provideDelegate(thisRef, property)`，编译器在"把委托对象绑到属性上"时会调它一次、并允许返回另一个委托对象——实测在 `val name by Checked(...)` 首次求值前打印了 `[provideDelegate] 绑定属性 name`。典型用途是绑定前的校验（比如 Map 委托在这里检查 key 存在）。注意它是**类自身的运算符**，不是 `ReadOnlyProperty` 伴生的成员。同包的 `Delegates` 类则装着 9.5–9.9 用过的 `observable`/`vetoable`/`notNull` 三兄弟。

## 9.11 委托速查与坑位清单

| 需求 | 用什么 | 注意 |
| --- | --- | --- |
| 单例 | `object` | 全局状态，测试要隔离 |
| 类级常量/工厂 | `companion object` | `const val` 只接 String/基本类型 |
| 包装接口加方法 | `类 : I by impl` | 委托对象编译期固定 |
| 昂贵的延迟初始化 | `by lazy` | 默认线程安全；轻量属性别用 |
| 赋值后通知 | `Delegates.observable` | 盯不住集合内部改动 |
| 赋值前校验 | `Delegates.vetoable` | 回调返回 false 即否决 |
| 晚初始化（引用类型） | `lateinit var` | 不支持基本类型/可空/顶层 |
| 晚初始化（任意类型） | `Delegates.notNull` | 每次访问多一层委托调用 |
| Map 当对象 | `by map` | 缺 key 读时炸；类型靠强转 |
| 自建委托 | 实现 `ReadOnlyProperty`/`ReadWriteProperty` | 可读可写进类型；`provideDelegate` 可做绑定期检查 |

1. **单例 object 是全局状态**：多测试用例共享它，用例间互相污染——测试里用独立名称（`register("x")`）就是在回避这个。
2. **lazy 的 lambda 里别引用了还没初始化的对象成员**：首访时机不可控，顺序错了拿到半初始化的 `this`。
3. **observable 回调里再给自己赋值会递归**：回调内改其他属性可以，改自己死循环。
4. **vetoable 否决后属性保持旧值**，没有异常也没有日志——调用方不知道被否决了，关键路径要自己补日志。
5. **Map 委托的 key 是属性名字符串**：重命名属性等于改了配置协议，IDE 重构不会帮你改配置文件。
6. **类委托的转发基于接口**：`Box by items` 只转发 `List` 接口成员，`items` 具体类（如 ArrayList）的额外方法转不过来。
7. **委托属性每次访问都过 getValue**：属性里写 `by Trimmed(...)` 意味着每次读都 trim 一遍，热点路径上的重活委托要想清楚成本。
8. **接口式必须写 `override`，约定式不能写**：前者漏写报 `'getValue' hides member of supertype ... and needs an 'override' modifier`，后者多写报 `'getValue' overrides nothing`（本地 kotlinc 2.4.21 实测）——两种写法看类声明就能分辨，别混。
9. **只读委托接 `var` 编译不过**：`ReadOnlyProperty` 给 `var` 用会报 `type 'X' has no method 'setValue(...)', so it cannot serve as a delegate for var`——可读/可写在委托层就是分开的两个接口。
10. **顶层属性的 `thisRef` 是 null**（实测：成员属性拿到 `Holder@...`、顶层属性拿到 `null`）——自建委托里别无条件解引用 `thisRef`。

---

上一章：[08 ⭐密封枚举 when](08-sealed-enum.md) · 下一章：[10 集合](10-collections.md)
