// C 侧实现：这个文件由 zig 的 C 编译器前端编译，与 Zig 代码一起链接。
#include "ci.h"
#include <string.h>

int ci_add(int a, int b) { return a + b; }
int ci_triple(int a) { return a * 3; }

size_t ci_strlen(const char *s) { return strlen(s); }

int ci_strcmp(const char *a, const char *b) { return strcmp(a, b); }

// 调用 Zig 导出的函数：C 侧完全看不出对面是 Zig
int ci_call_zig_add(int a, int b) { return zig_add(a, b); }