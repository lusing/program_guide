// 29 · 进阶扩展：成员扩展双接收者、作用域收口、抽象成员扩展、typealias、import as 纸牌 DSL
import Rank.ACE
import Rank.KING
import Rank.QUEEN
import Suit.DIAMONDS
import Suit.HEARTS
import Suit.SPADES

// ---- 29.1/29.2 成员扩展 ----

data class User(val name: String, val categoryId: Int)

class UserDirectory(private val users: List<User>) {
    private val catNames = mapOf(1 to "管理员", 2 to "访客")

    /** 成员扩展：it 是扩展接收者元素，catNames 是分发接收者成员——免限定混用 */
    fun List<User>.labelAll(): List<String> = map { "${it.name}@${catNames[it.categoryId]}" }

    fun sameCategory(name: String): List<String> {
        val me = users.first { it.name == name }
        return users.filter { it.categoryId == me.categoryId && it != me }.labelAll()
    }
}

// ---- 29.3 抽象成员扩展：表格渲染框架 ----

class Row(val cells: List<String>)

abstract class TableFormatter {
    abstract fun Row.render(): String                    // 扩展点：实现者拿到 Row 作用域
    fun format(vararg rows: List<String>): String =
        rows.joinToString("\n") { Row(it.toList()).render() }
}

class MarkdownTable : TableFormatter() {
    override fun Row.render() = "| ${cells.joinToString(" | ")} |"
}

class CsvTable : TableFormatter() {
    override fun Row.render() = cells.joinToString(",")
}

// ---- 29.4 typealias ----

/** 函数类型别名 + 参数命名（IDE 提示里能看到 event/code 而非 p1/p2） */
typealias Handler = (event: String, code: Int) -> Boolean

/** 泛型别名 */
typealias Predicate<T> = (T) -> Boolean

/** 复合类型缩短：二维网格 */
typealias Grid = Array<IntArray>

/** 类实现函数类型别名——状态多到 lambda 装不下时的正解 */
class Guard : Handler {
    var calls = 0
    override fun invoke(event: String, code: Int): Boolean {
        calls++
        return code > 0 && event.isNotEmpty()
    }
}

fun main() {
    println("== 29.1 双接收者 ==")
    val dir = UserDirectory(listOf(User("ann", 1), User("bob", 2), User("cat", 1)))
    println("sameCategory(\"ann\") = ${dir.sameCategory("ann")}（catNames 来自分发接收者）")

    println("== 29.2 作用域收口 ==")
    with(dir) { println("with(dir) 里 users 调 labelAll 要走类内方法；类外直接调扩展编译不过") }
    println("顶层扩展全局可见、成员扩展圈在类内——DSL 收口的第二根支柱（第一根是 @DslMarker）")

    println("== 29.3 抽象成员扩展 ==")
    val table = listOf(listOf("姓名", "分数"), listOf("ann", "95"), listOf("bob", "88"))
    println(MarkdownTable().format(table[0], table[1], table[2]))
    println(CsvTable().format(table[0], table[1], table[2]))

    println("== 29.4 typealias ==")
    val isEven: Predicate<Int> = { it % 2 == 0 }
    println("isEven(4)=${isEven(4)}, isEven(5)=${isEven(5)}")
    val g: Grid = Array(2) { r -> IntArray(2) { c -> r * 2 + c } }   // 内层 it 会被遮蔽——命名 r/c 更清晰
    println("Grid 内容: ${g.joinToString { row -> row.joinToString() }}")
    val guard = Guard()
    val h: Handler = guard
    println("类实现 Handler: h(\"login\", 1)=${h("login", 1)}, h(\"login\", 0)=${h("login", 0)}, 调用次数=${guard.calls}")
    println("注意: typealias 不产生新类型——Handler 与 (String, Int) -> Boolean 完全互换")

    println("== 29.5 import as 与纸牌 DSL ==")
    val hand = listOf(KING of HEARTS, ACE of SPADES, QUEEN of DIAMONDS)
    println("hand = $hand")
    println("排序后 = ${hand.sortedWith(compareBy({ it.suit.name }, { it.rank.label }))}")
    println("零前缀调用 + infix of + 编译期杜绝非法牌；解冲突用 import a.Node as ANode")
}
