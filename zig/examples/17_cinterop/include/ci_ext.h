// 17.4–17.6 用的第二组 C 声明。
//
// 为什么单独一个头文件：ci.h 是 17.2 的最小示例（add + triple + strlen + strcmp），
// 文档里整段贴的就是那 8 行。结构体 / 数组 / 函数指针这些"跨语言共享内存"的话题
// 放在这里，两个头文件各自被 b.addTranslateC 翻译成两个独立的 Zig 模块。
#include <stddef.h>

// ── 17.4 布局保证：Zig 侧用 extern struct 镜像这个 ci_box_t ──
// 声明序 + 自然对齐，与 C 的布局规则逐字节一致（可以用 @offsetOf / offsetof 对照验证）。
typedef struct ci_box {
    int x;
    int y;
} ci_box_t;

// C 侧往这块内存写
void ci_box_shift(ci_box_t *b, int dx, int dy);
// C 侧读同一块内存并打印
void ci_box_print(const char *tag, const ci_box_t *b);
// C 侧的 offsetof：Zig 侧用 @offsetOf，两边输出必须一致
size_t ci_box_off_x(void);
size_t ci_box_off_y(void);
size_t ci_box_size(void);

// ── 结构体数组 / 指针数组：Zig 侧按 [*c]const T 拿指针后直接按元素遍历 ──
typedef struct ci_pair {
    const char *key;
    int val;
} ci_pair_t;

const ci_pair_t *ci_pairs(void); // C 侧静态数组，生命周期 = 整个进程
int ci_pairs_len(void);
// ── 17.3 函数指针：C 定义类型，Zig 侧 export 一个实现再把指针传回来 ──
typedef int (*ci_op_t)(int, int);
int ci_apply_op(ci_op_t op, int a, int b);

// ── 所有权语义：结构体里带 char * ──
// 谁分配谁释放的配套三件套：new 用 C 的 malloc（strdup），free 用 C 的 free。
// Zig 侧只读 name，不许 free —— free() 记在 libc 一侧，Zig 的 allocator 释放它就是跨分配器错误。
typedef struct ci_owner {
    char *name; // 指向另一块 malloc 出来的内存
    int id;
} ci_owner_t;

ci_owner_t *ci_owner_new(const char *name, int id); // C 侧 malloc + strdup
void ci_owner_free(ci_owner_t *p); // C 侧 free(p->name); free(p);
