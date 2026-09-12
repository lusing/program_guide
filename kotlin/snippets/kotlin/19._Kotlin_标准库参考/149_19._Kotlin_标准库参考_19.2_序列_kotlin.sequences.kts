// 创建序列
val seq = listOf(1, 2, 3, 4, 5).asSequence()

// 操作 (延迟执行)
val result = seq
    .map { it * 2 }
    .filter { it > 5 }
    .toList()

// 序列生成
val infinite = generateSequence(1) { it + 1 }
val fibonacci = generateSequence(1 to 1) { (a, b) -> b to a + b }

// 常用函数
seq.any { it > 3 }
seq.all { it > 0 }
seq.none { it < 0 }
seq.count { it > 2 }
seq.firstOrNull { it > 2 }
seq.find { it % 2 == 0 }
seq.elementAtOrNull(10)
