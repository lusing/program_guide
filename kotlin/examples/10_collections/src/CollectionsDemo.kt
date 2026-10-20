// 10 · 集合：只读/可变双轨、创建函数、常用操作全景、排序陷阱
// 集合逻辑集中放这个文件，Main.kt 负责演示输出

/** 词频统计：groupingBy + eachCount */
fun wordCount(text: String): Map<String, Int> =
    text.lowercase().split(Regex("\\W+")).filter { it.isNotBlank() }
        .groupingBy { it }.eachCount()

/** 分组：groupBy */
fun groupByGrade(students: List<Pair<String, Int>>): Map<Char, List<String>> =
    students.groupBy({ if (it.second >= 60) 'P' else 'F' }) { it.first }

/** 关联：associateBy / associateWith / associate */
fun indexByName(people: List<Person>): Map<String, Person> = people.associateBy { it.name }

data class Person(val name: String, val age: Int, val city: String)

/** 经典管道：filter → map → sorted → joinToString */
fun adultsIn(people: List<Person>, city: String): String =
    people.filter { it.city == city && it.age >= 18 }
        .sortedByDescending { it.age }
        .joinToString("、") { "${it.name}(${it.age})" }

/** 折叠：fold 带初值，reduce 无初值（空集合会炸） */
fun checksum(nums: List<Int>): Int = nums.fold(1) { acc, n -> (acc * 31 + n) % 100_007 }

/** flatMap：先映射后拍平 */
fun allHobbies(people: List<Person2>): Set<String> = people.flatMap { it.hobbies }.toSet()

data class Person2(val name: String, val hobbies: List<String>)

/** zip / chunked / windowed */
fun zipSums(a: List<Int>, b: List<Int>): List<Int> = a.zip(b).map { it.first + it.second }

/** 排序陷阱：sortedBy 返回新列表，sortBy 才是原地 */
fun sortDemo(): String {
    val src = mutableListOf(3, 1, 2)
    val copy = src.sorted()                 // 新列表
    return "src=$src, copy=$copy"
}

/** kotlin.comparisons.compareValues：两值比较返回 -1/0/1，自定义比较器的最小结石 */
fun ageGroup(p: Person): Int = when {
    p.age < 18 -> 0        // 未成年
    p.age < 60 -> 1        // 成年
    else -> 2              // 老年
}

/** compareValuesBy：按抽取的键依次比较——选择器列表的顺序就是优先级顺序 */
fun byAgeGroupThenName(a: Person, b: Person): Int =
    compareValuesBy(a, b, { ageGroup(it) }, { it.name })
