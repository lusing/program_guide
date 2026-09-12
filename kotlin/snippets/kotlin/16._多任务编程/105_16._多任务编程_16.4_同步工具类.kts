import java.util.concurrent.*

// CountDownLatch
val latch = CountDownLatch(3)
repeat(3) {
    thread {
        latch.countDown()
    }
}
latch.await()

// CyclicBarrier
val barrier = CyclicBarrier(3)
repeat(3) { thread { barrier.await() } }

// Semaphore
val semaphore = Semaphore(2)
semaphore.acquire()
semaphore.release()
