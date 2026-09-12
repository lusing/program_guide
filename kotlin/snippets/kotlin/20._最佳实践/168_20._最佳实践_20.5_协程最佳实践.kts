// 使用 coroutineScope
suspend fun fetchData(): String = coroutineScope {
    val deferred1 = async { api.call1() }
    val deferred2 = async { api.call2() }

    val result1 = deferred1.await()
    val result2 = deferred2.await()

    "$result1 $result2"
}

// 使用 withContext 切换调度器
suspend fun loadData(): Data = withContext(Dispatchers.IO) {
    // I/O 操作
    database.query()
}

// キャンセル可能
class ViewModel : CoroutineScope by MainScope() {
    fun stop() {
        cancel()
    }
}
