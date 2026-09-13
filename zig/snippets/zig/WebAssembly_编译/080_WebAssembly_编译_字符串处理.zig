const std = @import("std");

// 导出函数返回字符串
export fn get_greeting(name: [*]const u8) [*]const u8 {
    // 使用静态内存返回字符串
    // 注意：这种方法在实际应用中需要更仔细的内存管理
    const static_buf: [100]u8 = undefined;
    const msg = "Hello, " ++ std.mem.sliceAsBytes(name) ++ "!";

    var i: usize = 0;
    while (i < msg.len) : (i += 1) {
        static_buf[i] = msg[i];
    }
    static_buf[msg.len] = 0;

    return &static_buf;
}
