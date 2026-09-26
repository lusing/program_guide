// 33 · 剧本对局：图块展示 → 碰撞/旋转 → 硬降固化 → 消行计分 → 终局棋盘（零随机零时钟）

fun main() {
    println("== 33.1 七种图块与旋转帧 ==")
    for (t in Tetromino.entries) {
        println("${t.name}: ${t.rotations.size} 帧, 首帧 [${t.frame(0).joinToString(" | ")}]")
    }

    println("== 33.2 碰撞检测 ==")
    val g = Tetris()
    check(g.spawn(Tetromino.I))                      // x = (8-4)/2 = 2
    println("I 出生在 x=${g.x}, y=${g.y}")
    println("右移一格: ${g.move(1, 0)}（x=${g.x}）")
    println("右移 20 格: ${g.move(20, 0)}（撞墙拒动，x 仍=${g.x}）")
    println("旋转成竖条: ${g.rotate()}（rot=${g.rotation}）")
    println("左移 20 格: ${g.move(-20, 0)}（仍=${g.x}）")
    println(g.render())

    println("== 33.3 硬降与固化 ==")
    val dist = g.dropToBottom()
    g.lock()
    println("竖 I 硬降 ${dist} 格后固化（x=3 列 4..7 行）")
    println(g.render())

    println("== 33.4 消行与计分 ==")
    val g2 = Tetris()
    for (px in intArrayOf(0, 2, 4, 6)) {             // 四个 O 铺满底部两行
        check(g2.spawn(Tetromino.O, px))
        g2.dropToBottom()
        g2.lock()
    }
    println("四个 O 铺满两行 → 消除 ${g2.totalLines} 行，得分 ${g2.score}（LINE_SCORE[2]=${LINE_SCORE[2]}）")
    println(g2.render())

    println("== 33.5 剧本对局 ==")
    val g3 = Tetris()
    check(g3.spawn(Tetromino.T)); g3.move(1, 0); g3.rotate(); g3.rotate()   // T 转两下成 ".X./XXX"
    g3.dropToBottom(); g3.lock()
    check(g3.spawn(Tetromino.J)); g3.move(-1, 0)                            // J 左移一块
    g3.dropToBottom(); g3.lock()
    check(g3.spawn(Tetromino.I))                                            // 横 I 压在残行上方
    val d3 = g3.dropToBottom(); g3.lock()
    check(g3.spawn(Tetromino.Z)); g3.move(2, 0)
    val d4 = g3.dropToBottom(); g3.lock()
    println("T/J 落底；横 I 下落 ${d3} 格被残块垫住（停 y=5），Z 下落 ${d4} 格")
    println(g3.render())
    println("终局: 分数=${g3.score}, 消行=${g3.totalLines}——expected.txt 就是这局棋的回放")
}
