// 创建数组
val arr1 = arrayOf(1, 2, 3, 4, 5)
val arr2 = Array(5) { i -> i * 2 }
val arr3 = intArrayOf(1, 2, 3)

// 访问元素
arr1[0] = 10
val first = arr1[0]

// 数组属性
arr1.size
arr1.isEmpty()
arr1.isNotEmpty()

// 遍历
arr1.forEach { println(it) }
arr1.forEachIndexed { index, value -> println("$index: $value") }

// 常用操作
val sum = arr1.sum()
val filtered = arr1.filter { it > 2 }
val mapped = arr1.map { it * 2 }
