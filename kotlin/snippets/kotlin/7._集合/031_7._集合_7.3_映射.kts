// 不可变映射
val map: Map<String, Int> = mapOf("A" to 1, "B" to 2, "C" to 3)

// 可变映射
val mutableMap: MutableMap<String, Int> = mutableMapOf("A" to 1, "B" to 2)
mutableMap["C"] = 3
mutableMap.remove("A")
mutableMap["B"] = 10

// 访问
map["A"]
map.getOrNull("Z")
map.containsKey("A")
map.containsValue(1)

// 遍历
map.forEach { (key, value) -> println("$key: $value") }
map.keys
map.values
