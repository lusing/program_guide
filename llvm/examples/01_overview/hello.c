/* 第 1 章示例：C 源码 → LLVM IR → 运行
 * 对照命令（docs/01-overview.md 1.5 节）：
 *   clang -S -emit-llvm -O1 -target x86_64-pc-windows-gnu hello.c -o hello.ll
 *   lli hello.ll
 *   clang hello.c -o hello_native.exe && ./hello_native.exe
 */
#include <stdio.h>

static int fib(int n) {
    return n < 2 ? n : fib(n - 1) + fib(n - 2);
}

int main(void) {
    printf("fib(10) = %d\n", fib(10));
    printf("==== 01 ok ====\n");
    return 0;
}
