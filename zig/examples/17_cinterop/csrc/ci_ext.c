// ci_ext.c 的实现：与 src/main.zig 一起链接进同一个可执行文件（17.6 混编）。
#include "ci_ext.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

// ── 17.4 布局保证 ──
// C 侧写：把偏移平移量加进这块内存
void ci_box_shift(ci_box_t *b, int dx, int dy) {
    if (b == NULL) return;
    b->x += dx;
    b->y += dy;
}

// C 侧读：和 Zig 侧读的是同一块内存（Zig 那边传的是同一个指针）。
// ⚠️ 打印故意走 stderr：Zig 的 std.debug.print 也写 stderr，两边才会按代码顺序交错。
// 走 stdout 的话，libc 的 stdout 缓冲会让 C 的输出全部堆到程序最后。
void ci_box_print(const char *tag, const ci_box_t *b) {
    if (b == NULL) return;
    fprintf(stderr, "  [C] %s: x=%d y=%d\n", tag, b->x, b->y);
}

// C 侧的 offsetof —— 和 Zig 的 @offsetOf 对照，是"布局一致"最直接的证据
size_t ci_box_off_x(void) { return offsetof(ci_box_t, x); }
size_t ci_box_off_y(void) { return offsetof(ci_box_t, y); }
size_t ci_box_size(void) { return sizeof(ci_box_t); }

// ── 结构体数组：静态存储期，Zig 侧拿到指针就能按下标读 ──
static const ci_pair_t ci_pair_table[] = {
    {"red", 3},
    {"green", 5},
    {"blue", 7},
};

const ci_pair_t *ci_pairs(void) { return ci_pair_table; }
int ci_pairs_len(void) { return (int)(sizeof(ci_pair_table) / sizeof(ci_pair_table[0])); }

// ── 函数指针：C 侧只管"怎么调用"，实现是 Zig 传进来的那个 ──
int ci_apply_op(ci_op_t op, int a, int b) {
    if (op == NULL) return 0;
    return op(a, b);
}

// ── 所有权：分配和释放都在 C 侧（同一对 malloc/free）──
ci_owner_t *ci_owner_new(const char *name, int id) {
    ci_owner_t *p = (ci_owner_t *)malloc(sizeof(ci_owner_t));
    if (p == NULL) return NULL;
    p->name = strdup(name); // 同样来自 libc；Zig 侧不要用 allocator.free 释放它
    p->id = id;
    return p;
}

void ci_owner_free(ci_owner_t *p) {
    if (p == NULL) return;
    free(p->name);
    free(p);
}
