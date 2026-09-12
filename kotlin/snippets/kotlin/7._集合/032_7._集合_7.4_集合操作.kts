val numbers = listOf(1, 2, 3, 4, 5, 6, 7, 8, 9, 10)

// 过滤
val even = numbers.filter { it % 2 == 0 }
val filtered = numbers.filterNot { it > 5 }

// 映射
val squared = numbers.map { it * it }
val indexed = numbers.mapIndexed { i, v -> i to v }

// 分组
val grouped = numbers.groupBy { if (it % 2 == 0) "even" else "odd" }

// 归约
val sum = numbers.reduce { acc, v -> acc + v }
val sumWithInit = numbers.reduceIndexed { i, acc, v -> acc + v }

// 所有/任意
val allPositive = numbers.all { it > 0 }
val anyEven = numbers.any { it % 2 == 0 }
val noneNegative = numbers.none { it < 0 }

// 分割
val (even, odd) = numbers.partition { it % 2 == 0 }
