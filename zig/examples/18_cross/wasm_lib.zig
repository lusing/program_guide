//! 18 交叉编译：wasm32-freestanding 模块（无 OS：没有 main，只有导出）
// 构建：zig build-lib wasm_lib.zig -target wasm32-freestanding（库形态，无需入口）

export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn fib(n: u32) u32 {
    if (n <= 1) return n;
    var a: u32 = 0;
    var b: u32 = 1;
    var i: u32 = 1;
    while (i < n) : (i += 1) {
        const t = a + b;
        a = b;
        b = t;
    }
    return b;
}
