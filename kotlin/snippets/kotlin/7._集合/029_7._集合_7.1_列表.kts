// 不可变列表
val list: List<String> = listOf("A", "B", "C")
val emptyList = emptyList<Int>()

// 可变列表
val mutableList: MutableList<String> = mutableListOf("A", "B", "C")
mutableList.add("D")
mutableList.remove("B")
mutableList[0] = "X"

// 访问元素
list[0]              // 第一个元素
list.first()
list.last()
list.getOrNull(10)   // 安全访问
list.contains("A")

// 切片
list.subList(0, 2)
list.take(2)
list.drop(1)

// 转换
list.map { it.uppercase() }
list.filter { it.length > 1 }
list.sorted()
list.sortedDescending()
