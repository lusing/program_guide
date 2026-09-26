// 33 · 场地与规则：一维 ByteArray、碰撞检测、硬降固化、消行上移、经典计分
import java.util.Arrays

private val EMPTY: Byte = 0
private val FILLED: Byte = 1

/** 经典计分表：0/1/2/3/4 行（书上的 boostScore） */
val LINE_SCORE = intArrayOf(0, 40, 100, 300, 1200)

class Tetris(val w: Int = 8, val h: Int = 8) {
    val field = ByteArray(w * h)
    var piece: Tetromino? = null
    var rotation = 0
    var x = 0
    var y = 0
    var score = 0
    var totalLines = 0

    fun at(r: Int, c: Int): Byte = field[r * w + c]

    /** 碰撞检测（书上的 moveValid）：每个占用格界内且不叠占 */
    fun fits(t: Tetromino, rot: Int, px: Int, py: Int): Boolean {
        for ((r, c) in t.cells(rot)) {
            val fx = px + c; val fy = py + r
            if (fx !in 0 until w || fy !in 0 until h || at(fy, fx) != EMPTY) return false
        }
        return true
    }

    /** 出生：放顶部中间；放不下 = 局终（返回 false） */
    fun spawn(t: Tetromino, x0: Int = -1): Boolean {
        val px = if (x0 >= 0) x0 else (w - t.width(0)) / 2
        if (!fits(t, 0, px, 0)) return false
        piece = t; rotation = 0; x = px; y = 0
        return true
    }

    fun move(dx: Int, dy: Int): Boolean {
        val t = piece ?: return false
        if (!fits(t, rotation, x + dx, y + dy)) return false
        x += dx; y += dy
        return true
    }

    fun rotate(): Boolean {
        val t = piece ?: return false
        val nr = (rotation + 1) % t.rotations.size
        if (!fits(t, nr, x, y)) return false
        rotation = nr
        return true
    }

    /** 硬降：一路试到贴底，返回下降格数 */
    fun dropToBottom(): Int {
        var d = 0
        while (move(0, 1)) d++
        return d
    }

    /** 固化（书上的写入 field）+ 消行计分 */
    fun lock() {
        val t = piece ?: return
        for ((r, c) in t.cells(rotation)) field[(y + r) * w + (x + c)] = FILLED
        piece = null
        val cleared = clearLines()
        score += LINE_SCORE[cleared]
        totalLines += cleared
    }

    /** 满行删除 + 上方整体下移一行（书上的 assessField + shiftRows）；从底往上扫 */
    fun clearLines(): Int {
        var cleared = 0
        var r = h - 1
        while (r >= 0) {
            val full = (0 until w).all { at(r, it) != EMPTY }
            if (full) {
                for (rr in r downTo 1) System.arraycopy(field, (rr - 1) * w, field, rr * w, w)
                Arrays.fill(field, 0, w, EMPTY)
                cleared++
                // 上方整体下移后，本行是新内容——不递减 r，重扫本行
            } else r--
        }
        return cleared
    }

    /** 渲染：固化块 #，活动块用形状字母，空 .（活动块最后叠加） */
    fun render(): String = (0 until h).joinToString("\n") { r ->
        (0 until w).joinToString("") { c ->
            val t = piece
            when {
                at(r, c) != EMPTY -> "#"
                t != null && (r - y) in 0 until t.height(rotation) &&
                    (c - x) in 0 until t.width(rotation) &&
                    t.frame(rotation)[r - y][c - x] == 'X' -> t.name
                else -> "."
            }
        }
    }
}
