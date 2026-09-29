// ============================================================
// 28 章 · C 层实测（第二半：结构体、联合体、枚举、句柄、函数与宏）
//
// 同样是纯 C。这里放的「不透明句柄」是本章最像真实工程的一段：
// 结构体的**定义**只在本文件里出现，头文件只给一个 `typedef struct CLOpaque *CLOpaqueRef`，
// 外面既看不见字段、也造不出对象 —— CFRunLoop/NSUserDefaults 那些 CF 类型就是这么设计的。
// ============================================================
#include "CLTypes.h"
#include "CLMacros.h"
#include <stdarg.h>    // va_list / va_start / va_arg / va_end
#include <stdlib.h>
#include <string.h>

// ---------------------------------------------------------------- §7 结构体布局
size_t CLSizeofPackA(void) { return sizeof(struct CLPackA); }
size_t CLSizeofPackB(void) { return sizeof(struct CLPackB); }
size_t CLSizeofPackC(void) { return sizeof(struct CLPackC); }
size_t CLSizeofRectLike(void) { return sizeof(struct CLRectLike); }

// offsetof 是编译期常量，来自 <stddef.h>，不是编译器扩展
size_t CLOffsetIInA(void) { return offsetof(struct CLPackA, i); }
size_t CLOffsetDInA(void) { return offsetof(struct CLPackA, d); }
size_t CLOffsetIInB(void) { return offsetof(struct CLPackB, i); }
size_t CLOffsetExtraInRect(void) { return offsetof(struct CLRectLike, extra); }

// ---------------------------------------------------------------- §8 联合体与浮点位模式
size_t CLSizeofFloatBits(void) { return sizeof(union CLFloatBits); }

uint32_t CLBitsOf(float f) {
    union CLFloatBits u;
    u.f = f;                    // 写 float 那个成员
    return u.bits;              // 读另一个成员：同一块内存的另一种解释
}

uint32_t CLSignOfBits(uint32_t bits) { return (bits >> 31) & 1u; }
uint32_t CLExponentField(uint32_t bits) { return (bits >> 23) & 0xFFu; }
uint32_t CLMantissaField(uint32_t bits) { return bits & 0x7FFFFFu; }

// ---------------------------------------------------------------- §9 枚举
size_t CLSizeofColorEnum(void) { return sizeof(enum CLColor); }
long CLColorValue(enum CLColor c) { return (long)c; }
size_t CLSizeofSignedEnum(void) { return sizeof(enum CLSigned); }

// sizeof 看不出底类型有没有符号，「小减大」才看得出来：
// 无符号底类型会回绕成一个巨大的正数，有符号底类型就老老实实是负数。
long CLColorSubtractWrapped(void) { return (long)(enum CLColor)(CL_RED - CL_BLUE); }
long CLSignedSubtractWrapped(void) { return (long)(enum CLSigned)(CL_NEG - CL_POS); }

// ---------------------------------------------------------------- §10 不透明句柄
// 定义只在这里：外面拿到的是 CLOpaqueRef（一个指针），字段完全不可见
struct CLOpaque {
    int seed;
    long refs;
};

static long gAlive = 0;      // 「现在有几个句柄活着」——只统计本章节自己造的

CLOpaqueRef CLOpaqueCreate(int seed) {
    struct CLOpaque *h = (struct CLOpaque *)malloc(sizeof(struct CLOpaque));
    if (h == NULL) { return NULL; }
    h->seed = seed;
    h->refs = 1;
    gAlive += 1;
    return h;                // 调用方拿到一个「看不见的结构体」的指针
}

void CLOpaqueRetain(CLOpaqueRef h) { if (h) { h->refs += 1; } }

void CLOpaqueRelease(CLOpaqueRef h) {
    if (h == NULL) { return; }
    h->refs -= 1;
    if (h->refs == 0) {
        gAlive -= 1;
        free(h);             // 归零才真释放；之后这个指针就是野指针
    }
}

long CLOpaqueRefCount(CLOpaqueRef h) { return h ? h->refs : -1; }
int  CLOpaqueSeed(CLOpaqueRef h) { return h ? h->seed : -1; }
long CLOpaqueAliveObjects(void) { return gAlive; }

// ---------------------------------------------------------------- §11 函数
// 值传递：函数里怎么改，外面的变量都不知道
void CLTrySwap(int x, int y) {
    int t = x; x = y; y = t;         // 换的是两份拷贝
}

int CLAddFunc(int a, int b) { return a + b; }
int CLMulFunc(int a, int b) { return a * b; }

// 递归：n <= 1 时收敛，否则调用自己两次（斐波那契是最短的例子）
int CLFibonacci(int n) {
    if (n <= 1) { return n; }
    return CLFibonacci(n - 1) + CLFibonacci(n - 2);
}

// ---------------------------------------------------------------- §12 可变参数
// count 说有几个就读几个：这个 count 是唯一的护栏，读多就是 UB（探针记录）
int CLSumVarargs(int count, ...) {
    va_list ap;
    va_start(ap, count);
    int sum = 0;
    for (int i = 0; i < count; i++) { sum += va_arg(ap, int); }
    va_end(ap);
    return sum;
}

int CLMaxOfVarargs(int count, ...) {
    va_list ap;
    va_start(ap, count);
    int max = va_arg(ap, int);        // 至少要有 1 个，否则这里就是 UB
    for (int i = 1; i < count; i++) {
        int v = va_arg(ap, int);
        if (v > max) { max = v; }
    }
    va_end(ap);
    return max;
}

// ---------------------------------------------------------------- §13 函数指针
int CLDoubleOf(int x) { return x * 2; }
int CLSquareOf(int x) { return x * x; }
int CLNegateOf(int x) { return -x; }

// 「按名字找函数」在 C 里的形态是一张表 —— 和 §4 的 _cmd / OC 的 selector 是同一件事的低配版
static struct CLDispatchEntry {
    const char *name;
    CLIntMap fn;
} gTable[] = {
    { "double-it", CLDoubleOf },
    { "square-it", CLSquareOf },
    { "negate-it", CLNegateOf },
};

long CLTableSize(void) { return (long)(sizeof(gTable) / sizeof(gTable[0])); }

// 按下标取函数；越界返回 NULL（C 里函数指针可以是 NULL，调用前必须挡）
CLIntMap CLMapAt(int index) {
    if (index < 0 || index >= (int)(sizeof(gTable) / sizeof(gTable[0]))) { return NULL; }
    return gTable[index].fn;
}

// 表里的名字：只打名字不打指针
const char *CLMapNameAt(int index) {
    if (index < 0 || index >= (int)(sizeof(gTable) / sizeof(gTable[0]))) { return "?"; }
    return gTable[index].name;
}

int CLApplyTable(int index, int value) {
    CLIntMap fn = CLMapAt(index);
    if (fn == NULL) { return -9999; }      // 没人接 —— 静默失败，OC 里 target 为 nil 同款
    return fn(value);
}

// qsort 的比较函数：签名必须是 int(const void*, const void*)
int CLCompareAsc(const void *pa, const void *pb) {
    int a = *(const int *)pa;
    int b = *(const int *)pb;
    if (a < b) { return -1; }
    if (a > b) { return 1; }
    return 0;
}

void CLSortInts(int *arr, int count) {
    qsort(arr, (size_t)count, sizeof(int), CLCompareAsc);
}

// bsearch：找到返回那个元素，找不到返回 NULL
int CLSearchSorted(int *arr, int count, int key) {
    int target = key;
    void *hit = bsearch(&target, arr, (size_t)count, sizeof(int), CLCompareAsc);
    return hit ? *(int *)hit : -1;
}

// ---------------------------------------------------------------- §16 宏
// 宏是编译前的文本替换，所以「参数展开几次」是能量出来的。
// 这里刻意避开 i++：两次自增之间没有顺序点属于未定义行为，不作证据。
// 换成一个「每调一次就返回下一个 10 的倍数」的函数，副作用次数与返回值都能确定。
static int gSideEffects = 0;
void CLResetSideEffects(void) { gSideEffects = 0; }
int CLSideEffectOnce(void) {
    gSideEffects += 1;
    return 10 * gSideEffects;       // 第一次 10，第二次 20，第三次 30
}

// CL_TWICE(x) 展开成 ((x) + (x))：函数被调用两次 -> 10 + 20
int CLMacroTwiceValue(void) {
    CLResetSideEffects();
    return CL_TWICE(CLSideEffectOnce());
}
int CLMacroTwiceSideEffects(void) {
    CLResetSideEffects();
    (void)CL_TWICE(CLSideEffectOnce());
    return gSideEffects;
}

// 同名同形的函数版本：参数只求值一次 -> 10 + 10
int CLFuncTwiceValue(void) {
    CLResetSideEffects();
    return CLTwiceFunc(CLSideEffectOnce());
}
int CLFuncTwiceSideEffects(void) {
    CLResetSideEffects();
    (void)CLTwiceFunc(CLSideEffectOnce());
    return gSideEffects;
}

int CLTwiceFunc(int v) { return v + v; }

int CLMacroSqrOfSum(int base) {
    int r = CL_SQR_BAD(base + 1);           // 展开成 base + 1 * base + 1
    return r;
}
int CLMacroSafeSqrOfSum(int base) {
    return CL_SQR_PAREN(base + 1);          // 括号版本：优先级对了
}
int CLMacroDoWhileCount(int base) {
    int n = base;
    CL_BUMP_TWO(n);                         // 两条语句，外面看是一条
    if (base > 0) { CL_BUMP_TWO(n); } else { CL_BUMP_TWO(n); }  /* 多语句宏放进 if 才不炸 */
    return n;
}
const char *CLStringifyName(void) { return CL_STRINGIFY(CL_Paste_Target); }
int CLPastedInto(void) { return CL_PASTE(CL_, answer); }   // -> CL_answer = 77
const char *CLCurrentFuncName(void) { return __func__; }
long CLConditionBranchId(void) {
    // 分支编号 = 64 位标志 * 1 + 有 stdint 标志 * 10，两个开关都能单独核对
    return (long)(CL_WORD_BRANCH + CL_HAS_STDINT * 10);
}
