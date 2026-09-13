const std = @import("std");

// Wasm 导出的内存
export var memory: std.wasm.Memory = .{};

// 导出分配函数
export fn malloc(size: usize) [*]u8 {
    // 在实际应用中，需要实现内存分配
    // 这里只是示例
    return undefined;
}

export fn free(ptr: [*]u8) void {
    // 释放内存
}
