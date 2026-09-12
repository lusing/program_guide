val set = setOf(1, 2, 3, 4, 5)

// 基本操作
set.contains(3)
set.isEmpty()
set.size

// 集合运算
set.union(setOf(4, 5, 6))     // 并集
set.intersect(setOf(3, 4, 5)) // 交集
set.minus(setOf(1, 2))        // 差集
set.subtract(setOf(1, 2))     // 减法

// 转换
set.map { it * 2 }
set.filter { it > 2 }
set.associate { it to it * 2 }
