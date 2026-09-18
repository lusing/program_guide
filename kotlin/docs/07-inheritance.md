# 07 · 继承与接口

> 对应示例：`examples/07_inheritance/`
>
> Kotlin 把 Java 的默认反转了：**类默认 final，继承要显式 open**。
> "为继承而设计，否则禁止继承"（Effective Java 第 19 条）从建议变成了语言规则。

## 7.1 默认 final：显式 open

```kotlin
open class Shape(val name: String) {
    open val area: Double get() = 0.0
    open fun describe() = "$name: 面积 = ..."
}

class Circle(val radius: Double) : Shape("圆") {
    override val area: Double get() = Math.PI * radius * radius   // 属性也能 override
}

class Rect2(val w: Double, val h: Double) : Shape("矩形") {
    override fun describe() = super.describe() + "（宽 $w × 高 $h）"  // super 复用
}
```

- 类要 `open` 才可被继承；成员要 `open` 才可被 override。
- 覆写自动是 open 的（想封死：`final override fun`）。
- 属性也能覆写（val 覆写 val；var 可以覆写 val，反向不行）。

为什么默认 final？继承是最紧的耦合——父类实现细节全变成子类的隐性依赖。默认 final 逼你把"多态"接口化（下节），把"扩展"外挂化（13 章）。

## 7.2 继承语法细则

```kotlin
class Circle(radius: Double) : Shape("圆(${radius})")   // 父类构造立刻带参
```

父类有主构造参数时，继承处必须当场传。`Any` 是万物之祖——只有 `equals/hashCode/toString` 三个可覆写（没有 wait/notify，那些是 JVM 的）。

## 7.3 抽象类

```kotlin
abstract class Storage {
    abstract fun save(key: String, value: String)     // 无实现，子类必须给
    fun dump() = "Storage@${this::class.simpleName}"  // 具体成员照常有
}
class MemoryStorage : Storage() {
    override fun save(key: String, value: String) { ... }
}
```

`abstract` 隐含 open。选型：**抽象类 = 共享实现 + 部分契约；接口 = 纯契约（可多实现）**。Kotlin 接口可以有默认实现后，抽象类主要剩"带状态"这一条不可替代性。

## 7.4 接口：默认实现与属性

```kotlin
interface Area { val area: Double }

interface Named {
    val name: String
    fun label() = "[$name]"               // 默认实现
}

class Square2(val side: Double, override val name: String) : Area, Named {
    override val area: Double get() = side * side
    // label() 用默认实现；覆写也行
}
```

- 接口可多实现（类只能单继承）。
- 接口属性没有 backing field：要么抽象（子类实现），要么自定义访问器现算。
- **钻石问题**：两个接口有同名默认实现时，编译器强制你 `override fun label() = super<Area>.label()` 指明用哪边——歧义永不静默。

## 7.5 类型检查与智能转换

```kotlin
val objs: List<Any> = listOf(Circle(0.5), "文本", 42)
for (o in objs) {
    val msg = when (o) {
        is Shape -> "形状（area=${o.area}）"    // o 已智能转换为 Shape
        is String -> "字符串 '${o.take(4)}'"
        is Int -> if (o >= 0) "非负整数 $o" else "负整数 $o"
        else -> "其他"
    }
}
```

`is` 判真后**自动智能转换**（编译器插好检查），不再手写 `(Shape) o`。强制转换用 `as`（错类型抛 ClassCastException）；拿不准用 `as?`（04 章）。

**when + is + 智能转换**是 Kotlin 模式匹配的三件套——密封类型（08 章）让它如虎添翼。

## 7.6 嵌套类 vs 内部类

```kotlin
class Outer(val tag: String) {
    class Nested(val info: String) {           // 嵌套：静态，不持外部引用
        fun show() = "Nested($info)"
    }
    inner class Inner {                        // inner：持有 this@Outer
        fun show() = "Inner(属于 ${this@Outer.tag})"
    }
}
Outer.Nested("信息").show()        // 无需 Outer 实例
Outer("外层").Inner().show()       // 必须有实例
```

Kotlin **默认嵌套（无外部引用）**，要内部类写 `inner`——和 Java 相反（Java 默认 inner）。这避免了 Java 内部类隐式持有所致内存泄漏的整类 bug（Android Handler 泄漏）。

## 7.7 可见性四档实战

```kotlin
class Counter2 {
    private var hits = 0          // 只在本类
    internal fun bump() { hits++ }  // 同模块（编译单元）可见——模块内 API 的"包私有加强版"
    fun report() = "hits = $hits"
}
```

| 修饰符 | 范围 | 备注 |
|---|---|---|
| public | 任意 | 默认 |
| internal | 同模块 | 一个 Gradle module / 一次 kotlinc 编译 |
| protected | 本类 + 子类 | 接口成员不能 protected |
| private | 本类（或顶层：本文件） | 顶层 private = 文件私有 |

## 7.8 坑位清单

1. **覆写自动 open**：`override fun` 默认还能被再覆写，想封死要写 `final override`。
2. 接口属性没有 backing field——`interface I { var x: Int = 0 }` 编译错；抽象声明或用访问器。
3. 智能转换失效的经典场景：**open var 属性**（子类可覆写 getter，两次访问可能不同值）——编译器会拒绝转换，解法是先取局部 val。
4. `is` 数值分支不按继承层次匹配：`is Number` 与 `is Int` 都能匹配 42，**when 按分支顺序**取第一个——把更具体的类型放前面。
5. Java 匿名内部类的"隐式持有外部"在 Kotlin 嵌套类里不存在——从 Java 迁移时语义对不上的高发点。
6. `internal` 的边界是**模块**不是包：同一个 Gradle 模块里 internal 到处可见；跨模块（哪怕是同公司）就是不可见。
