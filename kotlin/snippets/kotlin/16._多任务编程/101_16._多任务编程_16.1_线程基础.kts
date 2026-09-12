// synchronized 关键字
class Counter {
    private var count = 0

    fun increment() {
        synchronized(this) {
            count++
        }
    }

    @Synchronized
    fun increment2() {
        count++
    }
}

// Lock 接口
import java.util.concurrent.locks.ReentrantLock

class LockCounter {
    private var count = 0
    private val lock = ReentrantLock()

    fun increment() {
        lock.lock()
        try {
            count++
        } finally {
            lock.unlock()
        }
    }
}
