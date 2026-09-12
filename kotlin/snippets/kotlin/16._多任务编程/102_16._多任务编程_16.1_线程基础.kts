class Buffer {
    private val queue = mutableListOf<Int>()
    private val lock = Any()

    fun produce(item: Int) {
        synchronized(lock) {
            queue.add(item)
            lock.notifyAll()
        }
    }

    fun consume(): Int {
        synchronized(lock) {
            while (queue.isEmpty()) {
                lock.wait()
            }
            return queue.removeAt(0)
        }
    }
}
