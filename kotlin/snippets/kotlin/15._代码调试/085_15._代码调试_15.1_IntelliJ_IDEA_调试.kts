// 行断点 - 在代码行上单击左侧
fun calculate() {
    val x = 10      // ← 断点
    val y = 20      // ← 断点
    val sum = x + y
}

// 条件断点 - 右键断点 → Breakpoint Properties
// 添加条件: x > 100
for (i in 1..1000) {
    processItem(i)  // ← 条件断点: i == 50
}

// 日志断点 - Log message to console
// ${"value = " + value}
