// 使用预分配容量
val list = mutableListOf<Int>().apply { ensureCapacity(1000) }

// 避免不必要的对象创建
fun isNullOrBlank(str: String?) = str == null || str.isBlank()

// 使用数组代替 List (原生类型)
val intArray = IntArray(1000)
val arrayList = ArrayList<Int>()

// 懒加载
val expensive by lazy { computeExpensive() }

// 内联函数
inline fun measure(block: () -> Unit) {
    val start = System.currentTimeMillis()
    block()
    println(System.currentTimeMillis() - start)
}
