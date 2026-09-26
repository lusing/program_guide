# 29 · 进阶扩展：成员扩展、typealias 与作用域收口

> 对应示例：`examples/29_member_extensions/`（两个源文件：`Cards.kt` + `Main.kt`）
>
> 成员扩展的双接收者、扩展的作用域收口、抽象成员扩展（渲染器框架）、
> typealias 全景（命名函数类型/泛型别名）、导入别名 `import as` 与类型安全纸牌 DSL。

## 29.1 成员扩展：双接收者

扩展函数可以声明在**类体里**——这时它有两个接收者：`List<User>` 是**扩展接收者**（it/this 指向它），外层的 `UserDirectory` 是**分发接收者**（直接访问它的成员）：

```kotlin
data class User(val name: String, val categoryId: Int)

class UserDirectory(private val users: List<User>) {
    private val catNames = mapOf(1 to "管理员", 2 to "访客")

    fun List<User>.labelAll(): List<String> =
        map { "${it.name}@${catNames[it.categoryId]}" }    // catNames 来自分发接收者，免限定
}
```

`labelAll` 里 `it` 是扩展接收者的元素、`catNames` 是外层类成员——两类成员**免限定混用**，这是顶层扩展做不到的。调用也要在类内：`users.labelAll()`。

## 29.2 作用域收口：扩展不是只能全局

顶层扩展是"全局污染"（谁都能 `import` 到，命名空间越堆越满）；**成员扩展只在类体（及子类）内可用**——编译器在类外直接拒绝调用：

```kotlin
val dir = UserDirectory(users)
dir.users.labelAll()      // ✗ 编译错：labelAll 不是 UserDirectory 的可见成员
with(dir) { users.labelAll() }   // ✓ 在分发接收者作用域里
```

这是 Kotlin DSL"收口"的第二根支柱（第一根是 23 章的 `@DslMarker`）：把扩展圈进 Builder 类，外面想调都调不到——标准库 `kotlinx.html` 的 `unsafe {}`、Gradle Kotlin DSL 的窄作用域全是这一招。

## 29.3 抽象成员扩展：把"接收者作用域"做成扩展点

成员扩展还能是 `abstract`——子类用扩展实现抽象点，实现里天然拿到接收者作用域。一个迷你表格渲染框架：

```kotlin
class Row(val cells: List<String>)

abstract class TableFormatter {
    abstract fun Row.render(): String                    // 扩展点：给我一个 Row 作用域的渲染器
    fun format(rows: List<Row>) = rows.joinToString("\n") { it.render() }
}

class MarkdownTable : TableFormatter() {
    override fun Row.render() = "| ${cells.joinToString(" | ")} |"   // cells 免限定
}
class CsvTable : TableFormatter() {
    override fun Row.render() = cells.joinToString(",")              // 同一扩展点另一种实现
}
```

框架作者把"渲染时你将拿到一个 Row"写进签名，实现者拿到的就是干净的作用域——Marvel Gallery 的 `abstract fun Holder.onBindViewHolder()` 正是这个形状（Android 的 RecyclerView 适配器基类）。

## 29.4 typealias 全景

```kotlin
typealias Handler = (event: String, code: Int) -> Boolean   // ① 函数类型别名 + 参数命名
typealias Predicate<T> = (T) -> Boolean                     // ② 泛型别名
typealias Grid = Array<IntArray>                            // ③ 复合类型缩短

val isEven: Predicate<Int> = { it % 2 == 0 }
val g: Grid = Array(2) { IntArray(2) { it } }
```

① 的参数名会进 IDE 提示——`Handler` 当回调类型时，调用方能看到 `event`/`code` 而不是 `p1`/`p2`（对应 Android 里 `OnElementClicked(position, view, parent)` 的工程写法）。别名还能加可见性（`private typealias` 文件内私有）。

更冷门但成立的一条：**类可以实现函数类型别名**（函数类型的本质是带 `invoke` 的接口）：

```kotlin
class Guard : Handler {
    override fun invoke(event: String, code: Int) = code > 0
}
val h: Handler = Guard();  h("login", 1)      // true
```

状态多到 lambda 装不下时，用类实现回调类型是正解。注意：typealias **不产生新类型**（纯别名，`Handler` 与 `(String, Int) -> Boolean` 完全互换）——想要真新类型得用手写 wrapper 类。

## 29.5 导入别名 import as：纸牌 DSL `KING of HEARTS`

`import x.y.Z as W` 两个用途：**消前缀**与**解冲突**。经典应用——类型安全纸牌（枚举 + infix + 静态导入三合一）：

```kotlin
// Cards.kt
enum class Rank(val label: String) { ACE("A"), KING("K"), QUEEN("Q"), JACK("J"), TEN("10") }
enum class Suit(val symbol: String) { SPADES("♠"), HEARTS("♥"), DIAMONDS("♦"), CLUBS("♣") }
data class Card(val rank: Rank, val suit: Suit) { override fun toString() = "${rank.label}${suit.symbol}" }
infix fun Rank.of(suit: Suit): Card = Card(this, suit)

// Main.kt —— 静态导入枚举常量，调用处零前缀
import Rank.ACE
import Rank.KING
import Suit.HEARTS
import Suit.SPADES

val hand = listOf(KING of HEARTS, ACE of SPADES)  // 读出来就是牌
```

`KING of HEARTS` 编译期就是 `Card(Rank.KING, Suit.HEARTS)`——不存在"红桃十三"这种非法牌；`of` 的 infix 让语序贴近自然语言。解冲突场景：两个包都有 `Node` 类时 `import a.Node as ANode` 各自安好。

## 本章坑位

- 成员扩展类外调用编译错——这是**特性**（作用域收口），不是 bug
- 双接收者里 `this` 指扩展接收者；要拿外层写 `this@UserDirectory`
- typealias 零运行时成本也零类型隔离——别名与原类型完全互换
- `import as` 只能作用于**声明**（类/函数/属性/枚举常量），不能作用于表达式
- 类实现函数类型要 override 的方法是 `invoke`
