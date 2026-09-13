const std = @import("std");

pub fn main() void {
    // 使用 @panic 自定义错误消息
    if (true) {
        @panic("This is a custom panic message");
    }

    // 错误处理时的 panic
    const result = error.NextTime{};
    if (result) |err| {
        @panic("Error occurred: " ++ @errorName(err));
    }
}
