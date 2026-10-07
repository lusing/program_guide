/* 18 交叉编译：这份 C 由 zig cc 编译。
 *
 * 四条验证通道之一：
 *   zig cc hello.c -o build/18_cross_hello_c && ./build/18_cross_hello_c
 *
 * 本章的点是「**同一份 C 代码换编译器**」：
 *   · zig cc hello.c   → clang 前端（0.17 内建 clang 22.1.8）+ Zig 自带的 LLD 链接器
 *   · 系统的 cc hello.c → Apple 的 clang + ld64
 * 两边编出的机器码一样，**区别在链接器和目标覆盖能力**：
 * `zig cc -target aarch64-linux hello.c -o hc` 能直接交叉出 Linux ELF，
 * 系统 cc 做不到（除非你先装好交叉工具链 + sysroot）。
 *
 * ⚠️ macOS 上 `zig cc` **不需要** -isysroot：0.17 会自己探测 SDK 路径
 *    （`zig cc -v hello.c` 的输出里能看到 -isystem .../MacOSX15.2.sdk/usr/include）。
 *    老版本教程里"zig cc 必须配 -isysroot $(xcrun --show-sdk-path)"的说法已过时。
 *
 * ⚠️ 0.17 已移除 @cImport（见 17 章），所以 C 侧的头文件不会自动翻译成 Zig。
 *    Zig 侧要调本文件的函数，只写一行 extern 声明即可（见 18.11）：
 *      extern fn c_triple(x: c_int) c_int;
 */
#include <stdio.h>
#include <stdint.h>

/* 与 Zig 混编时用的入口：Zig 侧用 `extern fn c_triple(x: c_int) c_int;` 声明它。
 * 故意**不**定义 main —— 两边都定义 main 会在链接期报 duplicate symbol _main（18.11）。 */
int32_t c_triple(int32_t x)
{
    return x * 3;
}

int main(void)
{
    printf("hello from C, compiled by zig cc\n");
    /* 顺带证明 libc 头文件与实现都就位：printf 能用说明 zig cc 补齐了
     * 目标平台的 libc，而不是只过了个语法检查。 */
    printf("c_triple(7) = %d\n", c_triple(7));
    /* printf 计算宽度用到了运行期数据 → 真正跑起来的代码，不只是常量折叠 */
    printf("sizeof(int) = %zu, sizeof(void*) = %zu\n", sizeof(int), sizeof(void *));
    return 0;
}
