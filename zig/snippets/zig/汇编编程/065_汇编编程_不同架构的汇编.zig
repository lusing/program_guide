const std = @import("std");
const builtin = @import("builtin");

comptime {
    if (builtin.cpu.arch != .x86_64) {
        @compileError("This example requires x86_64 architecture");
    }
}

// 使用 rdtsc 指令获取时间戳计数器
pub fn rdtsc() u64 {
    var low: u32 = undefined;
    var high: u32 = undefined;

    asm volatile (
        \\rdtsc
        : [low] "={eax}" (low),
          [high] "={edx}" (high)
        :
        :
    );

    return @as(u64, @as(u32, low)) | (@as(u64, @as(u32, high)) << 32);
}

// 使用 cpuid 指令获取 CPU 信息
pub fn cpuid() void {
    var eax: u32 = undefined;
    var ebx: u32 = undefined;
    var ecx: u32 = undefined;
    var edx: u32 = undefined;

    asm volatile (
        \\cpuid
        : [eax] "={eax}" (eax),
          [ebx] "={ebx}" (ebx),
          [ecx] "={ecx}" (ecx),
          [edx] "={edx}" (edx)
        : [func] "{eax}" (0)
        :
    );

    std.debug.print("CPU Vendor ID: {s}{s}{s}\n", .{
        std.mem.sliceAsBytes(&eax),
        std.mem.sliceAsBytes(&ebx),
        std.mem.sliceAsBytes(&ecx),
    });
}
