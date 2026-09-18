// Kotlin/Native 的 actual：platform.posix —— konanc 自带的平台库绑定（C 互操作一瞥，25.2）。
// mingw_x64 目标下 getenv 返回 CPointer<ByteVar>?，toKString() 转 Kotlin 字符串。

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.toKString
import platform.posix.getenv

@OptIn(ExperimentalForeignApi::class)   // C 互操作 API 全家都要 opt-in（25.2）
actual fun platformName(): String = "native (mingw_x64)"

@OptIn(ExperimentalForeignApi::class)
actual fun platformProbe(): String = "user=${getenv("USERNAME")?.toKString() ?: "absent"}"
