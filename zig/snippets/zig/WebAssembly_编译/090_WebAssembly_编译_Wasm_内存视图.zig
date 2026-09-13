const std = @import("std");

// 获取 Wasm 导出的内存
export var memory: std.wasm.Memory = .{};

// 在内存中写入数据
export fn write_data(ptr: [*]u8, data: [*]const u8, len: usize) void {
    var i: usize = 0;
    while (i < len) : (i += 1) {
        ptr[i] = data[i];
    }
}

// 读取内存中的字符串
export fn read_string(ptr: [*]const u8) u32 {
    var len: u32 = 0;
    var p = ptr;
    while (p.* != 0) : (p += 1) {
        len += 1;
    }
    return len;
}
