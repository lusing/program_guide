// 创建列表
val list = listOf(1, 2, 3, 4, 5)
val mutableList = mutableListOf(1, 2, 3)

// 访问元素
list[0]           // 第一个元素
list.first()      // 首元素
list.last()       // 尾元素
list.getOrNull(10) // 安全访问

// 查询
list.contains(3)
list.indexOf(3)
list.lastIndexOf(3)
list.isEmpty()
list.isNotEmpty()
list.size

// 转换
list.map { it * 2 }           // 映射
list.filter { it > 2 }        // 过滤
list.flatMap { listOf(it, it) } // 平铺
list.distinct()               // 去重
list.take(3)                  // 取前N个
list.drop(2)                  // 跳过前N个
list.takeWhile { it < 4 }     // 连续满足条件
list.dropWhile { it < 4 }     // 跳过连续满足条件
list.partition { it % 2 == 0 } // 分区

// 归约
list.sum()                    // 求和
list.average()                // 平均值
list.minOrNull()              // 最小值
list.maxOrNull()              // 最大值
list.reduce { acc, v -> acc + v }  // 归约
list.fold(0) { acc, v -> acc + v } // 带初始值归约

// 排序
list.sorted()                 // 升序
list.sortedDescending()       // 降序
list.sortWith(compareBy { it }) // 自定义比较
list.shuffled()               // 随机打乱

// 聚合
list.groupBy { if (it % 2 == 0) "even" else "odd" }
list.associateBy { "key_$it" }
list.foldIndexed(0) { i, acc, v -> acc + i + v }
