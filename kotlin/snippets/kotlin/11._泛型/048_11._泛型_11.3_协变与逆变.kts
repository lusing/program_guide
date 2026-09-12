// 协变 out (生产者)
interface Producer<out T> {
    fun produce(): T
}

// 逆变 in (消费者)
interface Consumer<in T> {
    fun consume(item: T)
}

// 不变
interface Container<T> {
    fun set(value: T)
    fun get(): T
}

// 星投影
val list: List<*> = listOf(1, 2, 3)
val first = list[0]  // 类型为 unknown
