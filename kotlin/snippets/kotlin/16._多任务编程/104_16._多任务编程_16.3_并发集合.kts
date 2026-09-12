import java.util.concurrent.*

// 并发队列
val boundedQueue = ArrayBlockingQueue<String>(3)
val unboundedQueue = LinkedBlockingQueue<String>()
val clq = ConcurrentLinkedQueue<Int>()

// 并发集合
val concurrentSet = ConcurrentHashMap.newKeySet<String>()
val skipListMap = ConcurrentSkipListMap<String, Int>()
