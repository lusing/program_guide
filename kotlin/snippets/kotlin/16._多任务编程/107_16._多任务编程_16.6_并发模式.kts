// 生产者-消费者
class ProducerConsumer {
    private val queue = ArrayBlockingQueue<Int>(10)

    fun produce() {
        for (i in 1..100) {
            queue.put(i)
            println("Produced: $i")
        }
    }

    fun consume() {
        repeat(100) {
            val item = queue.take()
            println("Consumed: $item")
        }
    }
}

// 读写锁
import java.util.concurrent.locks.ReentrantReadWriteLock

class ReaderWriter {
    private var data = mutableMapOf<String, String>()
    private val lock = ReentrantReadWriteLock()

    fun write(key: String, value: String) {
        lock.writeLock().lock()
        try { data[key] = value } finally { lock.writeLock().unlock() }
    }

    fun read(key: String): String? {
        lock.readLock().lock()
        try { return data[key] } finally { lock.readLock().unlock() }
    }
}
