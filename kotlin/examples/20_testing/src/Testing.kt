// 20 · 测试：被测对象（一个小型任务清单领域）+ 断言画廊 + 表驱动
// 本教程各示例用"自写 main + kotlin.test 断言"的形式；真实工程用 JUnit5（17 章的 Gradle 工程演示）

interface TaskStore {
    fun add(title: String): Int
    fun complete(id: Int): Boolean
    fun all(): List<Task2>
}

data class Task2(val id: Int, val title: String, val done: Boolean = false)

/** 内存实现：生产代码用文件/数据库实现（24 章） */
class InMemoryStore : TaskStore {
    private val items = mutableListOf<Task2>()
    private var next = 1
    override fun add(title: String): Int {
        require(title.isNotBlank()) { "标题不能为空" }
        val t = Task2(next++, title)
        items += t
        return t.id
    }
    override fun complete(id: Int): Boolean {
        val i = items.indexOfFirst { it.id == id }
        if (i < 0) return false
        items[i] = items[i].copy(done = true)
        return true
    }
    override fun all(): List<Task2> = items.toList()
}

/** 表驱动经典例：fizzbuzz */
fun fizzbuzz(n: Int): String = when {
    n % 15 == 0 -> "FizzBuzz"
    n % 3 == 0 -> "Fizz"
    n % 5 == 0 -> "Buzz"
    else -> n.toString()
}

/** 分数分级（边界测试的好目标） */
fun grade(score: Int): Char {
    require(score in 0..100) { "分数越界: $score" }
    return when {
        score >= 90 -> 'A'
        score >= 80 -> 'B'
        score >= 60 -> 'C'
        else -> 'D'
    }
}

/** 随机数：测试里用固定种子保证可复现（nextInt(from, until) 是左闭右开） */
fun rollDie(rng: kotlin.random.Random): Int = rng.nextInt(1, 7)
