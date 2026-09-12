import kotlinx.coroutines.flow.*

// 使用 tap 操作符调试
flow {
    emit(1)
    emit(2)
    emit(3)
}.transform { value ->
    println("Emitted: $value")
    emit(value * 2)
}.collect {
    println("Collected: $it")
}

// 使用 onEach 调试
val debugFlow = flow {
    for (i in 1..10) {
        emit(i)
    }
}.onEach { value ->
    println("[Debug] Value: $value")
}.flowOn(Dispatchers.Default)

// 使用 also 调试
val numbers = flowOf(1, 2, 3, 4, 5)
    .also { println("Flow created") }
    .map { it * 2 }
    .also { println("After map") }
    .collect { println(it) }

// フローステートデバッグ
fun debugFlow(name: String) = flow {
    println("[$name] Emission started")
    emit(name.length)
    println("[$name] Emission completed")
}

// 收集时的异常处理
flow {
    emit(1)
    emit(2)
    throw RuntimeException("Error in flow")
}.catch { e ->
    println("Caught exception: ${e.message}")
}.collect { println(it) }
