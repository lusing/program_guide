import kotlinx.coroutines.*

// 协程构建器
runBlocking { }
launch { }
async { }

// 协程控制
delay(1000)         // 延迟
yield()             // 让步
withTimeout(1000) { } // 超时
withTimeoutOrNull(1000) { } // 可空超时

// 协程上下文
Dispatchers.Default
Dispatchers.IO
Dispatchers.Main
Dispatchers.Unconfined

// 流
flow { emit(1) }.collect { }
channel.receive()   // Channel
mutex.withLock { }  // Mutex
