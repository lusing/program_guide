// 创建范围
val range = 1..10
val halfOpen = 1 until 10
val stepped = 1..10 step 2

// 检查
range.contains(5)
5 in range

// 范围操作
range.start
range.endInclusive
range.step

// 迭代
for (i in 1..5) { println(i) }
for (i in 5 downTo 1) { println(i) }
for (i in 1..10 step 2) { println(i) }
