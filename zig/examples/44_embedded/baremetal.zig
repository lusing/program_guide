//! 44 章裸机侧：freestanding 目标编译验证（宿主不可运行，编译即验证）。
//! 真实板级工程还需要链接脚本（定段地址/向量表位置）与启动汇编，
//! 本章聚焦"Zig 语言侧要写对什么"。

const Uart = packed struct {
    data: u8,
    status: u8,
    _: u16,
};

/// 裸机没有 OS，入口由 bootloader 直接跳转进来。
/// noreturn：永不返回（没有地方可返回）；callconv(.c)：约定与汇编启动代码一致。
export fn _start() callconv(.c) noreturn {
    // 真实裸机：第一件事是设栈指针（SP），否则第一次函数调用就踩空。
    // 清 BSS / 搬 DATA 在此完成（符号由链接脚本导出）。
    mainLoop();
    while (true) {} // 主循环不该返回；返回即死循环兜底
}

fn mainLoop() void {
    const uart: *volatile Uart = @ptrFromInt(0x0900_0000); // 板级固定地址
    while ((uart.status & 0x1) == 0) {} // TX ready？
    uart.data = 'B';
}

/// 中断 handler：真实工程里它的地址被链接脚本放进向量表。
export fn uart_irq_handler() callconv(.c) void {
    const uart: *volatile Uart = @ptrFromInt(0x0900_0000);
    _ = uart.data; // 读 data = 清 RX 中断标志（读侧效应）
}
