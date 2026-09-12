import kotlin.concurrent.thread

// 创建线程
val t = thread(start = true) {
    println("Thread running")
}

// named thread
val worker = thread(name = "WorkerThread", isDaemon = true) {
    // work
}

// 使用 Thread
val thread = object : Thread() {
    override fun run() {
        println("Running")
    }
}
thread.start()
