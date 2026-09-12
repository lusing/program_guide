import kotlinx.coroutines.*

fun main() = runBlocking {
    // launch: 启动新协程，不返回结果
    launch {
        delay(1000)
        println("Launch: Done")
    }

    // async: 启动新协程，返回结果
    val deferred = async {
        delay(1000)
        "Async: Result"
    }
    println(deferred.await())

    // runBlocking: 阻塞当前线程直到协程完成
    println("Before delay")
    delay(500)
    println("After delay")
}
