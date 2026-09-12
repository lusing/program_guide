import java.time.Duration
import java.time.Instant

// 简单性能测试
fun measureTimeMillis(block: () -> Unit): Long {
    val start = System.currentTimeMillis()
    block()
    return System.currentTimeMillis() - start
}

fun measureTime(block: () -> Unit): Duration {
    val start = Instant.now()
    block()
    return Duration.between(start, Instant.now())
}

// 使用示例
fun testPerformance() {
    val list = (1..10000).toList()

    val mapTime = measureTime { list.map { it * 2 } }
    val forEachTime = measureTime {
        val result = mutableListOf<Int>()
        for (i in list) {
            result.add(i * 2)
        }
    }

    println("Map: ${mapTime.toMillis()}ms")
    println("ForEach: ${forEachTime.toMillis()}ms")
}

// 性能测试工具类
object PerformanceTest {
    fun run(
        name: String,
        iterations: Int = 1000,
        block: () -> Unit
    ): Long {
        var total = 0L
        repeat(iterations) {
            val start = System.nanoTime()
            block()
            total += System.nanoTime() - start
        }
        val avg = total / iterations
        println("$name: ${avg}ns (avg)")
        return avg
    }
}

// 使用
fun performanceTest() {
    PerformanceTest.run("List map", 1000) {
        (1..100).toList().map { it * 2 }
    }
    PerformanceTest.run("For loop", 1000) {
        val result = mutableListOf<Int>()
        for (i in 1..100) {
            result.add(i * 2)
        }
    }
}
