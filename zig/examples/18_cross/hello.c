/* 18 交叉编译：这份 C 由 zig cc 编译（build.ps1 实测 zig cc hello.c） */
#include <stdio.h>

int main(void) {
    printf("hello from C, compiled by zig cc\n");
    return 0;
}
