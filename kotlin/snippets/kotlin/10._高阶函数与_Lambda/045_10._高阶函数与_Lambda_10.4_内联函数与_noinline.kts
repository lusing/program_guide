inline fun logger(block: () -> Unit) {
    println("Start")
    block()
    println("End")
}

// noinline 禁止内联
inline fun loggerWithCallback(
    block: () -> Unit,
    noinline callback: () -> Unit
) {
    block()
    callback()
}
