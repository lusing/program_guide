import kotlinx.coroutines.*
import kotlin.js.Promise

// Kotlin 协程与 JS Promise 互操作
suspend fun fetchUserData(): User {
    return Promise { resolve, reject ->
        // 模拟异步请求
        setTimeout({
            resolve(jsObject<User> {
                name = "Alice"
                age = 25
            })
        }, 1000)
    }.await()
}

// 使用 async
fun main() = runBlocking {
    val user = fetchUserData()
    console.log(user)
}
