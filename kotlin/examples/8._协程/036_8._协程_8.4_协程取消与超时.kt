import kotlinx.coroutines.*

fun main() = runBlocking {
    val job = launch {
        repeat(1000) { i ->
            delay(100)
            println("Job: $i")
        }
    }

    delay(500)
    job.cancel()

    // withTimeout
    try {
        withTimeout(1000) {
            delay(2000)
        }
    } catch (e: TimeoutCancellationException) {
        println("Timeout!")
    }

    // withTimeoutOrNull
    val result = withTimeoutOrNull(1000) {
        delay(500)
        "Done"
    }
    println(result)  // Done
}
