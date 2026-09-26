// 33 的测试：图块帧、碰撞、移动/旋转、消行计分、剧本对局
import kotlin.test.assertEquals
import kotlin.test.assertFalse
import kotlin.test.assertTrue

fun testPieces() {
    assertEquals(2, Tetromino.I.rotations.size)
    assertEquals(1, Tetromino.O.rotations.size)
    assertEquals(4, Tetromino.T.rotations.size)
    assertEquals(listOf("XXXX"), Tetromino.I.frame(0))
    assertEquals(listOf("X", "X", "X", "X"), Tetromino.I.frame(1))
    assertEquals(2, Tetromino.O.width(0)); assertEquals(2, Tetromino.O.height(0))
    assertEquals(4, Tetromino.T.cells(0).size)        // T 四个占用格
    assertEquals(4, Tetromino.I.cells(0).size)
    // rot 回绕：O 块 rot 任意值都安全
    assertEquals(Tetromino.O.frame(0), Tetromino.O.frame(7))
}

fun testFits() {
    val g = Tetris()                                   // 8x8 全空
    assertTrue(g.fits(Tetromino.I, 0, 2, 0))           // 界内
    assertFalse(g.fits(Tetromino.I, 0, -1, 0))         // 左墙
    assertFalse(g.fits(Tetromino.I, 0, 5, 0))          // 右墙（5..8 越界）
    assertFalse(g.fits(Tetromino.I, 1, 2, 5))          // 底（竖条高 4，y=5 → 8 越过 7）
    assertTrue(g.fits(Tetromino.O, 0, 0, 6))           // O 高 2：y=6 恰好贴底
    assertFalse(g.fits(Tetromino.O, 0, 0, 7))          // 行越界（第 8 行不存在）
}

fun testMoveRotate() {
    val g = Tetris()
    assertTrue(g.spawn(Tetromino.I))
    assertTrue(g.move(1, 0)); assertFalse(g.move(20, 0))
    assertTrue(g.move(0, 1)); assertFalse(g.move(0, 100))
    assertTrue(g.rotate())                             // I → 竖条
    assertEquals(3, g.dropToBottom())                  // y 1→4（高 4，底行 7）
    g.lock()
    for (r in 4..7) assertEquals(1.toByte(), g.at(r, 3))   // x=3 列 4..7 行固化
    assertEquals(null, g.piece)
}

fun testClearLines() {
    val g = Tetris()
    // 手工铺：第 6 行放一格，第 7 行铺满
    g.field[6 * 8 + 2] = 1
    for (c in 0 until 8) g.field[7 * 8 + c] = 1
    assertEquals(1, g.clearLines())
    assertEquals(1.toByte(), g.at(7, 2))               // 上方整体下移
    assertEquals(0.toByte(), g.at(7, 0))               // 其余为空
    assertEquals(0.toByte(), g.at(6, 2))
}

fun testFourOClearTwoLines() {
    val g = Tetris()
    for (px in intArrayOf(0, 2, 4, 6)) {
        assertTrue(g.spawn(Tetromino.O, px)); g.dropToBottom(); g.lock()
    }
    assertEquals(2, g.totalLines)
    assertEquals(100, g.score)                          // LINE_SCORE[2] = 100（经典表 40/100/300/1200）
    assertTrue(g.field.all { it == 0.toByte() })        // 棋盘清空
}

fun testScriptedGame() {
    val g = Tetris()
    assertTrue(g.spawn(Tetromino.T)); g.move(1, 0); g.rotate(); g.rotate()
    g.dropToBottom(); g.lock()
    assertTrue(g.spawn(Tetromino.J)); g.move(-1, 0)
    g.dropToBottom(); g.lock()
    assertTrue(g.spawn(Tetromino.I))
    assertEquals(5, g.dropToBottom())                    // 横 I 被 T/J 残块垫住，停在 y=5（距底 2 格）
    g.lock()
    assertEquals(0, g.totalLines)                        // 本局未凑满行
    assertEquals(0, g.score)
}

fun main() {
    testPieces()
    testFits()
    testMoveRotate()
    testClearLines()
    testFourOClearTwoLines()
    testScriptedGame()
    println("33_tetris 全部测试通过")
}
