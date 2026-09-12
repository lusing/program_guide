import java.lang.Thread

// 方式1: 继承 Thread 类
class WorkerThread : Thread() {
    override fun run() {
        println("Thread running: ${Thread.currentThread().name}")
    }
}

val thread1 = WorkerThread()
thread1.start()

// 方式2: 使用 Thread 构造函数
val thread2 = Thread {
    println("Hello from thread: ${Thread.currentThread().name}")
}
thread2.start()

// 方式3: kotlin.concurrent.thread
import kotlin.concurrent.thread

val thread3 = thread(start = true) {
    println("Thread from kotlin.concurrent")
}

val namedThread = thread(name = "BackgroundWorker", isDaemon = true) {
    // 后台工作
}
