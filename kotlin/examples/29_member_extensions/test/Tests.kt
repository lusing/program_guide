// 29 的测试：成员扩展、抽象成员扩展、typealias、纸牌 DSL
import Rank.ACE
import Rank.KING
import Rank.QUEEN
import Suit.CLUBS
import Suit.HEARTS
import Suit.SPADES
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

fun testMemberExtension() {
    val dir = UserDirectory(listOf(User("ann", 1), User("bob", 2), User("cat", 1)))
    assertEquals(listOf("cat@管理员"), dir.sameCategory("ann"))
    assertEquals(listOf("ann@管理员"), dir.sameCategory("cat"))
    assertEquals(emptyList(), dir.sameCategory("bob"))
}

fun testAbstractMemberExtension() {
    val rows = listOf(listOf("a", "b"), listOf("c", "d"))
    assertEquals("| a | b |\n| c | d |", MarkdownTable().format(rows[0], rows[1]))
    assertEquals("a,b\nc,d", CsvTable().format(rows[0], rows[1]))
}

fun testTypealias() {
    val isEven: Predicate<Int> = { it % 2 == 0 }
    assertTrue(isEven(4)); assertFalse(isEven(5))
    val g: Grid = Array(2) { r -> IntArray(2) { c -> r * 2 + c } }
    assertEquals(0, g[0][0]); assertEquals(2, g[1][0])
    val guard = Guard()
    val h: Handler = guard
    assertTrue(h("login", 1))
    assertFalse(h("login", 0))
    assertEquals(2, guard.calls)
}

fun testCards() {
    val c = KING of HEARTS
    assertEquals(Card(Rank.KING, Suit.HEARTS), c)
    assertEquals("K♥", c.toString())
    val hand = listOf(KING of HEARTS, ACE of SPADES, QUEEN of CLUBS)
    assertEquals(3, hand.size)
    assertEquals(setOf(Suit.HEARTS, Suit.SPADES, Suit.CLUBS), hand.map { it.suit }.toSet())
}

fun main() {
    testMemberExtension()
    testAbstractMemberExtension()
    testTypealias()
    testCards()
    println("29_member_extensions 全部测试通过")
}
