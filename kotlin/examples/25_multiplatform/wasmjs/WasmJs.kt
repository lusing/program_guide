// Kotlin/Wasm 的 actual（wasm-js 目标）：跑在浏览器的 JS 引擎或 node 里，WasmGC 原生分配。
// wasm-js 有 JS 宿主，理论上可经 JS 互操作拿 navigator——语法与 Kotlin/JS 不同（25.4），
// 教学示例保持无互操作：探针返回固定标识，快照完全确定。

actual fun platformName(): String = "wasm-js (WasmGC)"

actual fun platformProbe(): String = "wasm-js target, JS host present"
