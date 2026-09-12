// 不可变集合
val set: Set<String> = setOf("A", "B", "C")

// 可变集合
val mutableSet: MutableSet<String> = mutableSetOf("A", "B", "C")
mutableSet.add("D")
mutableSet.remove("A")

// 操作
set.contains("A")
set.union(setOf("X", "Y"))
set.intersect(setOf("A", "Z"))
set.minus(setOf("B"))
