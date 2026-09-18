// 05 的测试：默认参数、vararg、infix、tailrec、局部函数
import kotlin.test.assertEquals
import kotlin.test.assertFailsWith
import kotlin.test.assertTrue

fun testDefaults() {
    assertEquals("http://api.example.com:8080 (timeout=3000ms)", connect("api.example.com"))
    assertEquals("https://api.example.com:443 (timeout=3000ms)", connect("api.example.com", 443, true))
    assertEquals("http://db.example.com:5432 (timeout=10000ms)", connect("db.example.com", port = 5432, timeoutMs = 10_000))
}

fun testVararg() {
    assertEquals(6, sum(1, 2, 3))
    assertEquals(0, sum())
    assertEquals(65, sum(*intArrayOf(10, 20, 30), 5))
}

fun testInfix() {
    assertEquals(1024, 2 pow 10)
    assertEquals(1, 3 pow 0)
    assertEquals(27, 3 pow 3)
}

fun testTailrec() {
    assertEquals(2_432_902_008_176_640_000L, factorial(20))
    assertEquals(2_880_067_194_370_816_120L, fib(90))
    assertEquals(1L, fib(1))
    assertEquals(0L, fib(0))
    // tailrec 不会栈溢出：大 n 也稳（100000! 尾部有大量 0，%10 必为 0）
    assertEquals(0L, factorial(100_000) % 10)
}

fun testLocalFun() {
    assertTrue(validateForm("张三", "z@ex.io", 30).isEmpty())
    assertEquals(3, validateForm("", "zex.io", 300).size)
    assertEquals("姓名 无效: 为空", validateForm("", "z@ex.io", 30).first())
}

fun testMaxOf3() {
    assertEquals(9, maxOf3(3, 9, 7))
    assertEquals('z', maxOf3('a', 'z', 'm'))
    assertEquals("zig", maxOf3("kotlin", "zig", "rust"))
}

fun main() {
    testDefaults()
    testVararg()
    testInfix()
    testTailrec()
    testLocalFun()
    testMaxOf3()
    println("05_functions 全部测试通过")
}
