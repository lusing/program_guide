import java.util.concurrent.atomic.*

val atomicInt = AtomicInteger(0)
atomicInt.incrementAndGet()
atomicInt.compareAndSet(1, 10)

val atomicRef = AtomicReference<String>()
val atomicBool = AtomicBoolean(false)

val atomicArray = AtomicIntegerArray(intArrayOf(1, 2, 3))
