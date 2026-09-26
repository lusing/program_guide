// 33 · 七种图块：枚举 + ASCII 旋转帧（/ 分行；X = 占用格）

enum class Tetromino(vararg val rotations: String) {
    I("XXXX", "X/X/X/X"),
    O("XX/XX"),
    T("XXX/.X.", ".X/XX/.X", ".X./XXX", "X./XX/X."),
    S(".XX/XX.", "X./XX/.X"),
    Z("XX./.XX", ".X/XX/X."),
    J("X../XXX", "XX/X./X.", "XXX/..X", ".X/.X/XX"),
    L("..X/XXX", "X./X./XX", "XXX/X..", "XX/.X/.X");

    /** 第 rot 帧的行列表（rot 自动回绕——O 块一帧也安全） */
    fun frame(rot: Int): List<String> = rotations[rot % rotations.size].split('/')

    fun width(rot: Int): Int = frame(rot)[0].length

    fun height(rot: Int): Int = frame(rot).size

    fun cells(rot: Int): List<Pair<Int, Int>> = buildList {
        frame(rot).forEachIndexed { r, row -> row.forEachIndexed { c, ch -> if (ch == 'X') add(r to c) } }
    }
}
