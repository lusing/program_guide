// Kotlin/Wasm 的 actual（wasm-wasi 目标）：WASI = 面向非浏览器的 WASM 系统接口，
// 没有 JS 宿主、没有 navigator/window——文件/时钟/环境变量走 WASI 预览版接口。
// node 经 node:wasi 模拟宿主运行（实验特性，25.4 有实测记录）。

actual fun platformName(): String = "wasm-wasi (WasmGC)"

actual fun platformProbe(): String = "wasi target, no JS host"
