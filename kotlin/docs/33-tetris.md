# 33 · ⭐实战：俄罗斯方块核心逻辑

> 对应示例：`examples/33_tetris/`（`Pieces.kt` + `Game.kt` + `Main.kt`）
>
> 七种图块的枚举建模（ASCII 旋转帧）、ByteArray 位矩阵场地、碰撞检测、硬降固化、
> 消行上移与经典计分、剧本化对局——全程零随机零时钟，快照就是整局回放。

## 33.1 图块建模：枚举 + ASCII 旋转帧

参考书（实例精解第 3 章）用 `enum Shape` 给每个图块实现抽象的 `getFrame`——本例把旋转帧写成
**ASCII 字符串**（`/` 分行），枚举构造器里一次声明全部旋转态：

```kotlin
enum class Tetromino(vararg val rotations: String) {
    I("XXXX", "X/X/X/X"),
    O("XX/XX"),
    T("XXX/.X.", ".X/XX/.X", ".X./XXX", "X./XX/X."),
    S(".XX/XX.", "X./XX/.X"),
    Z("XX./.XX", ".X/XX/X."),
    J("X../XXX", "XX/X./X.", "XXX/..X", ".X/.X/XX"),
    L("..X/XXX", "X./X./XX", "XXX/X..", "XX/.X/.X");
}
```

`frame(rot)` 拆行、`X` 是占用格——图块数据即文档，比二维数组字面量可读得多。O 块天然只有一帧、I 块两帧、其余四帧，`rot % rotations.size` 自动回绕。

## 33.2 场地：一维 ByteArray

8×8 棋盘用**一维原语数组**（26 章）：`index(r, c) = r * w + c`，`0` 空 `1` 占——
零装箱、行清零就是一次 `Arrays.fill`：

```kotlin
val field = ByteArray(w * h)
fun at(r: Int, c: Int) = field[r * w + c]
```

## 33.3 碰撞检测：一个函数定乾坤

书上叫 `moveValid`/`validTranslation`——本质是一个谓词：**图块每个占用格落在界内且不叠占**：

```kotlin
fun fits(t: Tetromino, rot: Int, px: Int, py: Int): Boolean {
    t.frame(rot).forEachIndexed { r, row ->
        row.forEachIndexed { c, ch ->
            if (ch == 'X') {
                val x = px + c; val y = py + r
                if (x !in 0 until w || y !in 0 until h || at(y, x) != EMPTY) return false
            }
        }
    }
    return true
}
```

移动/旋转/落地全部是它的**查询**：`move(dx)` = `fits(…, x+dx, y)`，`rotate()` = `fits(…, newRot, x, y)`——先试后改，绝不动了再说。这就是碰撞引擎的全部秘密。

## 33.4 硬降、固化与消行

```kotlin
fun dropToBottom(): Int { var d = 0; while (move(0, 1)) d++; return d }   // 一路试到贴底
fun lock() { /* 把占用格写回 field，piece = null */ }
fun clearLines(): Int {
    // 满行删除 + 上方整体下移一行（书上的 assessField + shiftRows），返回消除行数
}
```

计分用经典表 `[0, 40, 100, 300, 1200]`（书上的 `boostScore`）——四行同消 1200 分的爽点保留。

## 33.5 剧本对局：零随机、零时钟

`Main` 是一场编排好的对局：逐块 spawn → 平移/旋转 → 硬降 → 固化，中途故意铺满两行看消除计分。
全程无随机、无真实计时——**`expected.txt` 就是这局棋的逐帧回放**，渲染函数把活动块用形状字母、
固化块用 `#` 画出来：

```text
........
........
....T...
###TT###   ← 活动块 T 与固化块同框
########
```

改坏任何一处（旋转帧、碰撞、消行上移、计分），快照立即红——这是确定性设计换来的回归网。

## 33.6 表驱动测试

- 每个 enum 的帧数、首帧形状断言（I 两帧、O 一帧……）
- `fits` 的墙/地/叠占三类反例 + 正例
- 旋转在墙边被拒、平移越界被拒
- 铺满一行 → `clearLines()` 消除且上方下移、分数入账
- 连续对局（spawn→drop→lock 若干轮）终局棋盘逐行断言

## 本章坑位

- 一维数组下标 `r * w + c` 别写反（`c * h + r` 行列互换,棋盘会"转置"）
- 消行要从**底往上**扫，且删除后行号要回退重扫本行（上方整体下移一格）
- `rotate()` 回绕用 `rot % rotations.size`——O 块一帧取模天然安全
- 活动块渲染要在固化块**之后**叠加，否则被盖住
- 快照里别打印分数以外的动态值；本例连分数都是确定的（表驱动计分）
