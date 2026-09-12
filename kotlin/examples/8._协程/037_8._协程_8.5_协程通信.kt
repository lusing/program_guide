import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.*

fun main() = runBlocking {
    // Channel
    val channel = Channel<Int>()

    launch {
        for (x in 1..5) {
            channel.send(x * x)
        }
        channel.close()
    }

    for (y in channel) {
        println(y)
    }

    // Flow
    flow {
        for (i in 1..5) {
            delay(100)
            emit(i)
        }
    }.collect { value ->
        println(value)
    }

    // 流操作
    flow {
        emit(1)
        emit(2)
        emit(3)
    }.map { it * it }.filter { it % 2 == 0 }.collect {
        println(it)
    }
}
