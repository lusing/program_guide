# 13 · 扩展 ⭐

> 对应示例：`examples/13_extensions/`
>
> 给已有类型"外挂"新成员：不改源码、不用继承、连 String/Int 这样的
> 最终类型都能扩。但有一条铁律：**扩展是静态解析的**——理解它，一半
> 的"怪异行为"就不再怪异。

## 13.1 扩展函数

```kotlin
fun String.initials(): String =
    split(Regex("\\s+")).filter { it.isNotBlank() }.joinToString("") { it.take(1).uppercase() + "." }

"Ada Lovelace Byron".initials()        // A.L.B.
fun Int.timesRepeat(s: String): String = s.repeat(this)
3.timesRepeat("哈")                     // 哈哈哈
```

语法 = `fun 接收者类型.名字(...)`。函数体里 `this` 就是接收者。**编译后的真身**：静态方法 `initials(String $this$initials)`——所以：

- 不污染原类型（实例里没有这个方法）；
- 访问不到 private/protected 成员（毕竟在外面）；
- 依赖导入（`import` 特定扩展才可见）——扩展是按文件组织的模块级能力。

## 13.2 扩展属性（没有 backing field）

```kotlin
val String.shoutLen: Int get() = length + 1          // 必须自定义访问器现算
val <T> List<T>.secondOrNullExt: T? get() = getOrNull(1)
```

不能存状态（没有字段），只能从现有成员推算。要状态就用映射表（ WeakHashMap）——那是库的做法，不是语言能力。

## 13.3 可空接收者

```kotlin
fun String?.orDash(): String = this ?: "—"

val s: String? = null
s.orDash()          // "—"（null 也能调扩展！）
```

接收者类型本身是 `String?`——04 章的空安全操作符在扩展里照样用。标准库的 `String?.isNullOrEmpty()` 就是这么写的。这是扩展相对成员的一大优势：**成员方法必须非空调用，扩展可以对 null 调用**。

## 13.4 泛型扩展与伴生扩展

```kotlin
fun <T> List<T>.interspersed(sep: String): String = joinToString(sep)   // 对所有 List

class Money(val cents: Long) {
    companion object { fun ofYuan(y: Long) = Money(y * 100) }
}
fun Money.Companion.ofCents(c: Long): Money = Money(c)      // 给"静态侧"挂函数
Money.Companion.ofCents(250)
```

伴生扩展 = 给别的类的 companion 补工厂/常量——库作者的常用钩子（如各类 `Context.xxx` DSL 入口）。

## 13.5 铁律：静态解析（不分发）

```kotlin
open class Animal2 { open fun who() = "Animal2" }
class Dog2 : Animal2() { override fun who() = "Dog2" }
fun Animal2.tag() = "[A]"
fun Dog2.tag() = "[D]"

val a: Animal2 = Dog2()
a.who()      // "Dog2"   ← 成员是虚方法：运行时类型决定
a.tag()      // "[A]"    ← 扩展是静态绑定：编译期声明类型决定
```

扩展调用在**编译期**就按"接收者的静态类型"选定，不走虚表。所以：

- 扩展不能被"覆写"——子类扩展和父类扩展是两个静态方法；
- 泛型扩展 `fun <T> T.foo()` 对 `T` 的任何静态类型都是同一个实现。

真实翻车场景：把扩展当多态用（期望子类扩展生效）——不会生效，用成员虚方法或接口默认实现重写设计。

## 13.6 成员优先 & 遮蔽

```kotlin
class Doc(val title: String) {
    fun render() = "成员渲染: $title"          // 成员
}
@Suppress("EXTENSION_SHADOWED_BY_MEMBER")       // 编译器会警告：这个扩展永远不会被调到
fun Doc.render() = "扩展渲染: ${title.uppercase()}"

Doc("t").render()      // 成员渲染 —— 永远
```

成员永远赢。编译器对"被成员遮蔽的扩展"有专门警告——看到它就是"删掉扩展"的信号。

## 13.7 标准库 = 扩展大展

```kotlin
"42".toIntOrNull()               // String 的扩展
listOf(1, 2).map { it + 1 }      // Iterable 的扩展
x?.let { }; x.also { }           // T 的扩展（12 章）
"abc".replace(Regex("a"), "b")   // String.replace(Regex, String)
```

**半个标准库是扩展函数**——这就是 Kotlin 能把 JDK 类型用出现代手感的原因。给自己的领域类型设计 API 时，同样优先"核心最小成员 + 模块扩展分层"。

## 13.8 坑位清单

1. **静态解析**：通过父类引用调不到子类扩展（13.5 的实证）；扩展不参与多态。
2. **成员压扩展**：同名时成员赢，扩展连被调用的机会都没有。
3. 扩展**访问不到私有成员**——要私有数据就得改造成员或同文件顶层函数。
4. 扩展需要**显式导入**（同包除外）——"怎么这个项目有 `x.foo()` 而我没有"先查 import。
5. 给第三方库类型写扩展 = 你模块的糖；一旦同名扩展在两个库都出现，调用点歧义编译错——扩展名别太通用（`foo()` 撞车比想象中容易）。
6. 可空扩展的调用点迷惑性：`s.orDash()` 看起来像成员调用，实际 null 也进得去——评审时注意接收者可空的扩展是否真的合理。
