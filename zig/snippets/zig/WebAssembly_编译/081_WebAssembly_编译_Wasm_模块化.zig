const std = @import("std");

// 导出多个函数
export fn add(a: i32, b: i32) i32 {
    return a + b;
}

export fn sub(a: i32, b: i32) i32 {
    return a - b;
}

export fn mul(a: i32, b: i32) i32 {
    return a * b;
}

export fn div(a: i32, b: i32) i32 {
    return a / b;
}

// 导出常量
export fn get_version() u32 {
    return 1;
}
