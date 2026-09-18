// Kotlin/JS 的 actual：external 声明 + js() 内联——Kotlin/JS 互操作 JS 的原生方式（25.3）。
// process 是 node 的全局对象；浏览器下不存在（教学点：宿主环境差异由 actual 吸收）。

private external val process: dynamic

actual fun platformName(): String = "js (node)"

actual fun platformProbe(): String = "node ${process.version}"
