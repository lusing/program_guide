// 使用 volatile 确保汇编不会被优化掉
asm volatile (
    "nop"  // 空操作，用于延时或同步
    :
    :
    :
);

// 不使用 volatile 可能被优化掉
asm (
    "nop"
    :
    :
    :
);
