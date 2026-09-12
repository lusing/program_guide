val map = mapOf("a" to 1, "b" to 2, "c" to 3)

// 访问
map["a"]
map.getOrDefault("d", 0)
map.contains("a")
map.containsKey("a")
map.containsValue(1)
map.isEmpty()
map.size

// 遍历
map.forEach { (k, v) -> println("$k: $v") }
map.keys
map.values

// 转换
map.mapKeys { (k, v) -> k.uppercase() }
map.mapValues { (k, v) -> v * 2 }
map.filter { (k, v) -> v > 1 }
map.toMap()

// 合并
map + ("d" to 4)
map.minus("a")
map.merge("a", 10) { old, new -> old + new }
