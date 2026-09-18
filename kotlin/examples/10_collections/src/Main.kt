// 10 · 集合：只读/可变双轨、创建函数、常用操作全景

fun main() {
    println("== 10.2 只读与可变双轨 ==")
    val ro: List<Int> = listOf(1, 2, 3)              // 只读接口（不是不可变！）
    val mu: MutableList<Int> = mutableListOf(1)
    mu += 2; mu.add(3)                               // mutable 才有写方法
    println("listOf=$ro, mutableListOf=$mu")
    val view: List<Int> = mu                          // 可变列表可当只读用（向上转型视图）
    mu.add(4)
    println("只读引用能看到底层变化: view=$view（所以只读 ≠ 不可变）")
    val frozen: List<Int> = mu.toList()              // 真正想"快照"就拷贝
    mu.add(5)
    println("快照 toList 不受影响: frozen=$frozen")
    val stuck = listOf(1, 2)
    // stuck.add(3)                                  // ← 编译错：List 接口没有 add

    println("== 10.3 创建函数全家 ==")
    println("listOf(1,2,3) = ${listOf(1, 2, 3)}")
    println("mutableListOf = ${mutableListOf("a")}")
    println("emptyList<Int>() = ${emptyList<Int>()}")
    println("List(3) { it * it } = ${List(3) { it * it }}      // 工厂：按下标构造")
    println("MutableList(3) { 0 } = ${MutableList(3) { 0 }}")
    println("buildList { add(1); add(2) } = ${buildList { add(1); add(2) }}   // 构建期可变，产物只读")
    println("mapOf(\"a\" to 1) = ${mapOf("a" to 1)}")
    println("setOf(1, 2, 2, 3) = ${setOf(1, 2, 2, 3)}          // 去重")
    println("(1..5).toList() = ${(1..5).toList()}")

    println("== 10.4 map / filter / 链式管道 ==")
    val nums = (1..10).toList()
    println("偶数的平方: ${nums.filter { it % 2 == 0 }.map { it * it }}")
    println("第一个 >7 的元素: ${nums.first { it > 7 }}")
    println("没有匹配时用 firstOrNull: ${nums.firstOrNull { it > 99 }}")
    println("count/sum/avg/max: count=${nums.count()}, sum=${nums.sum()}, avg=${"%.1f".format(nums.average())}, max=${nums.maxOrNull()}")
    println("take/drop: take(3)=${nums.take(3)}, drop(7)=${nums.drop(7)}")
    println("distinct: ${listOf(1, 2, 2, 3, 1).distinct()}")

    println("== 10.5 分组与关联 ==")
    val text = "the quick brown fox jumps over the lazy dog the end"
    val top = wordCount(text).entries.sortedWith(
        compareByDescending<Map.Entry<String, Int>> { it.value }.thenBy { it.key }
    ).take(3)
    println("词频 Top3: ${top.joinToString { "${it.key}×${it.value}" }}")
    val students = listOf("张三" to 88, "李四" to 45, "王五" to 60, "赵六" to 59)
    println("按成绩分组: ${groupByGrade(students).entries.joinToString { "${it.key}: ${it.value}" }}")
    val people = listOf(
        Person("Alice", 30, "北京"), Person("Bob", 17, "上海"),
        Person("Carol", 25, "北京"), Person("Dave", 41, "深圳"),
    )
    println("indexByName: ${indexByName(people).keys}")
    println("北京的成年人: ${adultsIn(people, "北京")}")

    println("== 10.6 flatMap / zip / chunked / windowed ==")
    val team = listOf(
        Person2("张三", listOf("读书", "跑步")), Person2("李四", listOf("跑步", "编程")),
    )
    println("全员爱好去重: ${allHobbies(team).sorted()}")
    println("zipSums([1,2,3],[10,20,30]) = ${zipSums(listOf(1, 2, 3), listOf(10, 20, 30))}")
    println("chunked(2) = ${(0..5).toList().chunked(2)}")
    println("windowed(2) = ${(1..4).toList().windowed(2)}")
    println("zipWithNext = ${(1..4).zipWithNext().joinToString { "(${it.first},${it.second})" }}")

    println("== 10.7 fold / reduce / scan ==")
    val ns = listOf(1, 2, 3, 4)
    println("求和 reduce: ${ns.reduce { a, b -> a + b }}")
    println("fold(10): ${ns.fold(10) { a, b -> a + b }}")
    println("runningFold: ${ns.runningFold(0) { a, b -> a + b }}    // 前缀和")

    println("== 10.8 Map 操作 ==")
    val m = mutableMapOf("a" to 1)
    m["b"] = 2
    println("getOrPut: ${m.getOrPut("c") { 3 }}，再取还是同一个值: ${m.getOrPut("c") { 99 }}")
    println("mapValues: ${m.mapValues { it.value * 10 }}")
    println("filterKeys: ${m.filterKeys { it != "b" }}")
    val pairs = mapOf("x" to 1, "y" to 2)
    for ((k, v) in pairs) print("$k=$v ")
    println()

    println("== 10.9 Set 运算 ==")
    val a = setOf(1, 2, 3); val b = setOf(3, 4)
    println("a ∪ b = ${a + b}（或 a.union(b)）")
    println("a ∩ b = ${a intersect b}")
    println("a − b = ${a - b}")

    println("== 10.10 排序：sorted 新列表 vs sort 原地 ==")
    println(sortDemo())
    val byName = people.sortedWith(compareByDescending<Person> { it.age }.thenBy { it.name })
    println("按年龄降序: ${byName.joinToString { it.name }}")
}
