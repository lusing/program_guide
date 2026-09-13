const std = @import("std");

// 安全的汇编封装
const CPUIDResult = struct {
    eax: u32,
    ebx: u32,
    ecx: u32,
    edx: u32,
};

fn safe_cpuid(func: u32) CPUIDResult {
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
        : [func] "{eax}" (func)
        : "cc"
    );

    return .{
        .eax = eax,
        .ebx = ebx,
        .ecx = ecx,
        .edx = edx,
    };
}

pub fn main() void {
    const vendor_id = safe_cpuid(0);
    std.debug.print("CPU Vendor: {s}{s}{s}\n", .{
        std.mem.sliceAsBytes(&vendor_id.ebx),
        std.mem.sliceAsBytes(&vendor_id.edx),
        std.mem.sliceAsBytes(&vendor_id.ecx),
    });
}
