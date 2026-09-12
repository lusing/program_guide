// 获取内存使用情况
fun printMemoryInfo() {
    val runtime = Runtime.getRuntime()
    val usedMemory = runtime.totalMemory() - runtime.freeMemory()
    val maxMemory = runtime.maxMemory()

    println("Used Memory: ${usedMemory / 1024 / 1024}MB")
    println("Max Memory: ${maxMemory / 1024 / 1024}MB")
    println("Free Memory: ${runtime.freeMemory() / 1024 / 1024}MB")
}

// 对象分配分析
fun analyzeObjectAllocation() {
    printMemoryInfo()

    val largeList = mutableListOf<List<Int>>()
    repeat(1000) {
        largeList.add((1..1000).toList())
    }

    printMemoryInfo()
}

// 使用 finalize 诊断泄露
class LeakedObject {
    override fun finalize() {
        println("LeakedObject was garbage collected")
    }
}
