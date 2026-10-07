// 17 章的 C 侧：一个纯 C 实现 + 一个头文件。
// Zig 侧通过 build.zig 的 b.addTranslateC 把这个头文件翻译成 Zig 声明，
// 于是 csrc/ci.c 与 src/main.zig 一起链接成同一个可执行文件。
#include <stddef.h>

int ci_add(int a, int b);
int ci_triple(int a);
size_t ci_strlen(const char *s);
int ci_strcmp(const char *a, const char *b);

// 从 Zig 侧导出的函数（Zig 用 export + callconv(.C) 实现）
int zig_add(int a, int b);
const char *zig_version(void);