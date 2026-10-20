# 07 · 继承与接口

> 对应示例：`examples/07_inheritance/`（含 Shape/Circle/Rect2 继承链、抽象 Storage、双接口 Square2、Nested vs Inner、Counter2 可见性、when+is 智能转换渲染器）。全部代码经四层验证：`kotlinc -Werror` 零告警 → kotlin.test 单测通过 → 运行 exit 0 → 输出与 `expected.txt` 逐字节一致。环境：Kotlin 2.4.21（K2）+ JDK 21。

第 06 章讲的类默认是 `final` 的——别人不能继承。这一章讲"打开"继承之后的事：Kotlin 在语法层面做了哪些与 Java 不同的决定，以及抽象类、接口、智能转换、嵌套类这几块拼图如何配合。

---

## 7.1 为什么默认 final

Java 里所有类默认可以被继承，Effective Java 因此专门立了规矩："要么为继承而设计并写文档，要么禁止继承"。一个没按继承设计的类被子类化了，子类可能依赖父类的实现细节，父类升级时莫名其妙地破坏子类（所谓"脆弱基类"问题）。

Kotlin 把这个经验变成了语言默认值：**类默认 `final`，想被继承必须显式写 `open`**；成员也一样——可被覆写的成员要标 `open`，覆写方必须标 `override`（不写是编译错误，不像 Java 的 `@Override` 注解那样可写可不写）。三个关键字全是显式的，读代码时没有任何隐藏的多态：

```kotlin
open class Shape(val name: String) {
    open val area: Double get() = 0.0          // 属性也能 open
    open fun describe() = "$name: 面积 = ${"%,.2f".format(area)}"
}
```

`name` 没有 `open`，不可覆写；`area` 和 `describe` 可以。注意**属性也能 `open`**——这是 Kotlin 比 Java 多出的一维：覆写单位不只是方法，还可以是属性（本质是覆写它的 getter）。这个设计顺带带来性能红利：编译器看到非 open 调用可以静态分派，不必走虚方法表。

还要意识到一点：`Shape` 是 open 的**具体**类，别人仍然可以 `Shape("x")` 直接实例化——`open` 只打开"继承"的门，不关上"实例化"的门。示例注释特意提醒了这一点；想让基类只能被继承、不能被 new，答案在 7.3 的 `abstract`。

**构造器里调 open 成员是经典地雷**：父类构造器先跑，此时子类属性还没初始化，若父类 `init` 调用了 open 成员，子类覆写版读到的字段全是默认值。本示例的基类构造函数体是空的，刻意避开了这个坑；工程代码里请同样回避。

---

## 7.2 继承的语法细则

看示例里的两个子类：

```kotlin
class Circle(val radius: Double) : Shape("圆") {
    override val area: Double get() = Math.PI * radius * radius
}

class Rect2(val w: Double, val h: Double) : Shape("矩形") {
    override val area: Double get() = w * h
    override fun describe() = super.describe() + "（宽 $w × 高 $h）"   // 复用父类实现
}
```

四个要点逐条过：

1. **`: Shape("圆")` —— 把父类构造器调用直接写在类头上。** Java 要进构造器体里写 `super("圆")`，Kotlin 把它提升到声明处，"子类拿什么喂给父类"一眼可见。`Circle` 直接传字面量 `"圆"`，所以构造 `Circle` 时只需要给半径。
2. **用 `override val` 覆写属性。** `area` 在父类是 `open val`，子类用自定义 getter 覆写、每次访问现算。规则上 `var` 可以覆写 `val`（多提供一个 setter），反过来不行——`var` 的契约比 `val` 宽，窄契约不能冒充宽契约。
3. **`super.describe()` 显式复用父类行为。** `Rect2.describe` 是"父类版本 + 追加信息"。注意父类 `describe()` 里读 `area` 时会**动态分派**到子类覆写版，所以 `Rect2` 打出来是 12.00 而不是父类默认的 0.00：

   ```text
   矩形: 面积 = 12.00（宽 3.0 × 高 4.0）
   ```

   前半段 `"矩形: 面积 = 12.00"` 来自 `super.describe()`，后半段是子类追加。示例里 `Rect2` 的名字刻意与 06 章的 `Rect` 区分开，避免同名类撞车。
4. **`override` 的成员默认仍是 open 的**，可被下一代继续覆写；想封死要写成 `final override`。

多态调用处没有任何意外——`render`（见 7.5）遍历 `List<Shape>` 时各就各位：

```text
圆，半径 1.0，精确面积 3.1416
矩形: 面积 = 12.00（宽 3.0 × 高 4.0）
矩形覆写并复用父类: 矩形: 面积 = 12.00（宽 3.0 × 高 4.0）
```

测试里用父类引用验证了动态分派确实发生：

```kotlin
val c: Shape = Circle(1.0)
assertEquals(Math.PI, c.area, 1e-9)
assertEquals(12.0, Rect2(3.0, 4.0).area)
```

`c` 的静态类型是 `Shape`，读 `area` 拿到的却是 `Circle` 的 π·r²。

---

## 7.3 抽象类：不能实例化的半成品

`Shape` 是 `open` 的具体类，意味着别人可以 `Shape("x")` 直接 new 一个——但"形状"这个概念本身没有面积公式，实例化它语义上说不通。这个场景该用 `abstract`：**不能被实例化、允许包含未实现成员**：

```kotlin
abstract class Storage {
    abstract fun save(key: String, value: String)
    fun dump() = "Storage@${this::class.simpleName}"     // ::class 拿运行时类型
}

class MemoryStorage : Storage() {
    val data = mutableMapOf<String, String>()
    override fun save(key: String, value: String) { data[key] = value }
}
```

三个细节：

- `abstract fun save` 没有函数体，天然是 open 的——不需要也不能再写 `open`。抽象类里的**具体成员**（如 `dump()`）反而默认 final，要开放覆写仍需 `open`。
- `dump()` 返回 `"Storage@${this::class.simpleName}"`：`this::class` 拿到的是**运行时真实类型**的 KClass 引用，`simpleName` 是类名。所以通过父类引用调用，打出来的也是子类名：

  ```kotlin
  val st: Storage = MemoryStorage()
  st.save("lang", "kotlin")
  println("${st.dump()} -> ${(st as MemoryStorage).data}")
  ```

  ```text
  Storage@MemoryStorage -> {lang=kotlin}
  ```

  后半段的 `(st as MemoryStorage).data` 演示了 `as` 强转：`data` 只在子类上存在，父类引用摸不到。**确定类型时才用 `as`**，不确定就用 `as?`（失败得 null）。
- 测试直接验证了子类的存储行为：

  ```kotlin
  val st = MemoryStorage()
  st.save("a", "1"); st.save("b", "2")
  assertEquals(mapOf("a" to "1", "b" to "2"), st.data)
  ```

何时用抽象类而不是接口：需要**持有状态**（backing field）、需要 `protected`/构造器、或"是一个"关系语义强时用抽象类；纯能力契约用接口（下节）。

---

## 7.4 接口：纯契约 + 可带默认实现

Kotlin 接口与 Java 8+ 接口基本同构：无状态（不能持有 backing field）、可给方法默认实现、一个类可实现多个接口。示例用两个小接口演示"组合出能力"：

```kotlin
interface Area { val area: Double }
interface Named { val name: String
    fun label() = "[$name]" }                 // 默认实现
class Square2(val side: Double, override val name: String) : Area, Named {
    override val area: Double get() = side * side
    // label() 直接继承默认实现；要覆写也行
}
```

- `Area` 只声明抽象属性 `area`。**接口属性没有 backing field**，它只是"实现方必须能给出这个值"的契约；`Square2` 用自定义 getter 每次现算，零存储。
- `Named` 的 `label()` 有默认实现 `"[$name]"`；`Square2` 没覆写它，直接继承。注意 `override val name: String` 写在主构造器参数上——一个参数同时完成了"存值"和"履行接口契约"两件事。
- 多实现时通过接口引用访问，该是谁就是谁：

  ```kotlin
  val sq: Named = Square2(2.0, "方块")
  println("${sq.label()}, area = ${(sq as Square2).area}")
  val area2: Area = Square2(3.0, "方块")
  println("面积 = ${area2.area}")
  ```

  ```text
  [方块], area = 4.0
  面积 = 9.0
  ```

- 测试确认默认实现生效：`assertEquals("[方块]", (sq as Named).label())`。

如果实现的两个接口给了**同名同参的默认方法**，Kotlin 不替你二选一，直接编译报错，逼你覆写并在方法体内用 `super<接口名>.方法()` 显式挑一个（Java 的写法是 `接口名.super.方法()`）。这就是注释里说的"多实现解决钻石问题"——不决绝二义性，而是把选择权交回给你。

---

## 7.5 类型检查与智能转换：`when` + `is`

`is` 对应 Java 的 `instanceof`，但 K2 编译器多做一件事：**检查通过后自动把变量智能转换（smart cast）到目标类型**，分支体内不用手写强转：

```kotlin
fun render(s: Shape): String = when (s) {
    is Circle -> "圆，半径 ${s.radius}，精确面积 ${"%,.4f".format(s.area)}"
    is Rect2  -> s.describe()
    else      -> s.describe()
}
```

`is Circle` 分支里直接读 `s.radius`——Java 16 的 pattern matching for instanceof 才追上这个体验，且只覆盖单个 `if`；Kotlin 的 `when` 每个分支都享受。示例里还有一段对 `Any` 列表的"全类型分拣"，更能体现 `when`+`is` 的表达力：

```kotlin
val objs: List<Any> = listOf(Circle(0.5), "文本", 42, Rect2(1.0, 1.0))
for (o in objs) {
    val msg = when (o) {
        is Shape -> "形状（${if (o is Circle) "圆" else "矩形"}，area=${"%,.2f".format(o.area)}）"
        is String -> "字符串 '${o.take(4)}'"
        is Int -> if (o >= 0) "非负整数 $o" else "负整数 $o"
        else -> "其他: $o"
    }
    println("  $msg")
}
```

`is Shape` 分支里 `o.area` 已可用；再嵌套一层 `o is Circle` 判断细分类型。`is String` 分支里 `o.take(4)` 直接调 String 的方法。输出：

```text
  形状（圆，area=0.79）
  字符串 '文本'
  非负整数 42
  形状（矩形，area=1.00）
```

智能转换有前提：变量必须是编译器能证明"两次访问之间不会被改"的——`val`、局部 `var` 通常可以；带自定义 getter 的属性、跨模块的 `var` 不行（getter 可能每次返回不同值）。通不过时有两条路：把值先存进局部 `val` 再检查；或显式 `as` / `as?`。`as` 失败抛 `ClassCastException`，`as?` 失败得 null——业务代码优先 `as?` + Elvis，只有"失败就是 bug"的场景才用 `as`。

---

## 7.6 嵌套类 vs 内部类：默认不持有外部引用

Java 里写 `class Inner` 默认持有外部类实例的隐式引用（想不持有要加 `static`），这个默认值选反了：忘了加 `static` 的内部类把外部实例钉在堆里，是 Android 内存泄漏的经典来源。Kotlin 把默认方向倒了过来——**默认就是静态嵌套，想要外部引用必须显式写 `inner`**：

```kotlin
class Outer(val tag: String) {
    class Nested(val info: String) {          // 嵌套：不持有 Outer 实例
        fun show() = "Nested($info)"
    }
    inner class Inner {                       // inner：能访问 this@Outer
        fun show() = "Inner(属于 ${this@Outer.tag})"
    }
}
```

- `Outer.Nested("...")` 不需要 `Outer` 实例就能构造，编译后等价于 Java 的 static nested class。
- `Outer("外层").Inner()` 必须通过某个外部实例构造；类体内用 `this@Outer` 限定语法访问外部实例成员。
- 输出对照：

  ```text
  Nested(静态嵌套，无需 Outer 实例)
  Inner(属于 外层)
  ```

- 测试把两种构造路径都跑通了：

  ```kotlin
  assertEquals("Nested(信息)", Outer.Nested("信息").show())
  assertEquals("Inner(属于 X)", Outer("X").Inner().show())
  ```

经验法则：嵌套类只是"逻辑上住在某个类里"就用默认嵌套；确实需要读外部状态（监听器、迭代器这类）才加 `inner`。

---

## 7.7 可见性四档与 `internal`

```kotlin
class Counter2 {
    private var hits = 0
    internal fun bump() { hits++ }            // internal：模块内可见
    fun report() = "hits = $hits"
}
```

Kotlin 四档可见性：`public`（默认）/ `internal` / `protected` / `private`。与 Java 的关键差异：

- **`internal` 是 Java 没有的**：模块内可见、跨模块不可见（"模块"指一起编译的一组文件；教程所有示例同一次编译，即同一模块）。Java 的"包私有"挡不住同包不同源集的访问，`internal` 挡得住——JVM 上 `internal` 成员会被名字改写（name mangling），防 Java 侧误调。`bump()` 标 `internal` 是"库内部可调用、库外用户看不到"的标准用法。
- **没有包私有**：Kotlin 不鼓励用包划可见性边界；文件级声明用 `private` 表示"本文件内可见"，这在 Java 里没有对应物。
- 示例末尾有一行被注释掉的代码 `// c.hits ← 编译错：private 成员外部不可见`——留着它就是提醒：试一下就知道编译器守得很严。

三次 `bump()` 之后：

```text
hits = 3
```

测试同样验证了这条最小闭环：`c.bump()` 一次，`assertEquals("hits = 1", c.report())`。

---

## 7.8 继承、抽象类、接口：怎么选

三种机制摆在面前时的决策顺序：

1. **只是"有个能力"**——用接口。`Area`、`Named` 这种纯契约，实现方彼此毫无关系也能实现同一个接口。接口还能多实现，是 Kotlin 里唯一的"多继承"通道。
2. **"是一个"且要共享状态或实现骨架**——用抽象类。`Storage` 可以持有成员、写具体方法，子类填抽象的空。一个类只能继承一个父类，这个名额要留给真正的"种类"关系。
3. **具体类想被继承**——先想三遍，再写 `open`。默认 final 不是障碍，是提醒：继承把父类的实现细节变成了子类的依赖，能组合就别继承（第 09 章的类委托 `by` 就是为"组合优先"准备的语法糖）。
4. **只是想给类"挂"一些命名空间内的辅助类型**——用嵌套类，连继承都不必。

---

## 7.9 对照 Java：一眼看清差异

| 主题 | Java | Kotlin |
| --- | --- | --- |
| 默认可继承 | 是 | 否（要 `open`） |
| 覆写标记 | `@Override`（可选注解） | `override` 关键字（必选） |
| 可覆写单位 | 仅方法 | 方法 + 属性 |
| 封死覆写 | `final` 方法 | `final override`（override 默认仍 open） |
| 父类构造调用 | 构造器体内 `super(...)` | 类头上 `: Super(...)` |
| 接口默认方法 | `default` | 直接写方法体 |
| instanceof 后 | 手动强转 | 智能转换 |
| 嵌套类默认 | 持有外部引用（要 `static` 才不持有） | 不持有（要 `inner` 才持有） |
| 模块可见性 | 无（包私有近似） | `internal` |

---

## 7.10 坑位清单

1. **构造器里别调 open 成员**：父类构造器先执行，此时子类字段未初始化，覆写版读到的是默认值。需要"构造后回调"就用工厂函数。
2. **`override` 后默认还是 open**：不想被第三代覆写就写 `final override`。
3. **多接口同名默认方法必须显式覆写**，并在体内 `super<A>.foo()` 选择来源，否则编译不过。
4. **智能转换对自定义 getter、跨模块 `var` 失效**：把值先存进局部 `val`，转换一次用到底。
5. **`as` 失败抛 `ClassCastException`**，业务代码优先 `as?` + Elvis；只有"失败即 bug"的场景才用 `as`（如 7.3 里确定 `st` 就是 `MemoryStorage`）。
6. **嵌套类默认不持有外部引用**，这正是你要的；别习惯性写 `inner`，泄漏外部实例的坑就是这么来的。
7. **`internal` 在 JVM 上靠名字改写实现**：Java 侧反射仍摸得到，别拿它当安全边界，它是"API 整洁"工具。
8. **open 类不等于抽象类**：`open class Shape` 仍可被 `Shape("x")` 实例化；语义上"不该有实例"的基类请直接 `abstract`，别依赖约定。
9. **接口属性没有状态**：`interface Area { val area: Double }` 只是契约，实现方若写成构造器存值属性也合法——调用方感觉不到差别，这正是"统一访问"的红利。

---

上一章：[06 ⭐类与属性](06-classes.md) · 下一章：[08 ⭐密封枚举 when](08-sealed-enum.md)
