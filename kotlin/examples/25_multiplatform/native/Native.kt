// Kotlin/Native 的 actual：platform.posix —— konanc 自带的平台库绑定（C 互操作一瞥，25.2）。
// getenv 返回 CPointer<ByteVar>?，toKString() 转 Kotlin 字符串。
//
// 跨平台要点：快照只有一份，platformName() 只报**目标族**（kotlin-native），
// 宿主三元组（mingw_x64 / macosx_x64 / linux_x64）交给 platformProbe()——
// 后者不进快照（main 里打印成 "ok (host-dependent, redacted)"）。
// 否则像旧版那样写死 "native (mingw_x64)"，换到 macOS/Linux 编译就是一句假话，
// 而且快照在两个平台上不可能同时成立。

import kotlinx.cinterop.ExperimentalForeignApi
import kotlinx.cinterop.toKString
import platform.posix.getenv

actual fun platformName(): String = "native (kotlin-native)"

@OptIn(ExperimentalForeignApi::class)   // C 互操作 API 全家都要 opt-in（25.2）
actual fun platformProbe(): String {
    // Windows 上是 USERNAME，Unix 上是 USER —— 两个都问，避免换平台拿到 "absent"
    val user = getenv("USER")?.toKString() ?: getenv("USERNAME")?.toKString() ?: "absent"
    return "kotlin-native user=$user"     // 固定前缀保证长度：Common.kt 断言 ≥8 字符
}
