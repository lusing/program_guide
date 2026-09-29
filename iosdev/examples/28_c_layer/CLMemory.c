// ============================================================
// 28 章 · C 层实测（第一半：数组、字符串、指针、出参、内存块）
//
// 这个文件是**纯 C**：构建脚本用 clang 编它，不带 -fobjc-arc，也不链 Foundation。
// 所以它里面一个字符都不可能打印 —— 它只负责「量」，把数字交给 .m 去格式化。
// 这正好是本章想教的分工：C 层管内存，ObjC/Swift 层管字符串与打印。
// ============================================================
#include "CLTypes.h"
#include <string.h>    // strlen / memcpy / memmove / memset
#include <stdlib.h>    // malloc / calloc / free / realloc

// ---------------------------------------------------------------- §3 数组就是连续内存
// 5 个 int：连续 20 字节（在本章的 64 位目标上）
static int gInts[5] = { 10, 20, 30, 40, 50 };

// 2 行 3 列，行主序存放：m[0][0..2] 紧挨着 m[1][0..2]
static int gMatrix[2][3] = { { 1, 2, 3 }, { 4, 5, 6 } };

size_t CLSizeofInt5(void) { return sizeof(gInts); }

long CLIntArrayCount(void) { return (long)(sizeof(gInts) / sizeof(gInts[0])); }

// 两个指针相减得到的是「差几个元素」，单位由类型决定，不是字节
long CLGapInElements(void) { return (long)(&gInts[3] - &gInts[0]); }

// 先转成 char* 再相减，才是字节数
long CLGapInBytes(void) { return (long)((char *)&gInts[3] - (char *)&gInts[0]); }

// 二维数组：换行是「一整行那么远」，所以这里是 3 个 int = 12 字节
long CLRowGapInBytes(void) { return (long)((char *)&gMatrix[1][0] - (char *)&gMatrix[0][0]); }

// 数组名退化之前，&a 的类型是「指向整个数组的指针」，加一跳过的是 20 字节而不是 4
long CLWholeArrayPlusOneGap(void) {
    int (*whole)[5] = &gInts;          // 注意类型：不是 int*，是 int(*)[5]
    return (long)((char *)(whole + 1) - (char *)whole);
}

// 纯指针算术求和：*(a + i) 与 a[i] 是同一件事的两种写法
// 循环变量用 long 而不是 size_t：和 CLIntArrayCount() 的返回类型对齐，
// 一旦一个是有符号一个是无符号，-Wextra 的 -Wsign-compare 立刻报警（这本身就是个 C 常见坑）。
long CLSumViaPointer(void) {
    long sum = 0;
    long count = CLIntArrayCount();
    for (long i = 0; i < count; i++) { sum += *(gInts + i); }
    return sum;
}

int CLAtRowCol(void) { return gMatrix[1][2]; }

// ---------------------------------------------------------------- §3（续）数组名一进函数就退化
// 上面那些 sizeof 都成立，是因为数组还在**它自己的文件里**；
// 一旦当参数传出去，形参拿到的只是首地址，长度信息彻底消失。
long CLSizeofRealArray(void) {
    int arr[5] = { 1, 2, 3, 4, 5 };
    return (long)sizeof(arr);         // 20：本地真正的数组
}

// 数组当形参就退化：函数里 sizeof(形参) 拿到的是指针宽度，不是整块数组。
// 这里刻意写成 int *arr —— 写成 int arr[5] 会触发 -Wsizeof-array-argument
// （编译器难得替我们兜住一次这个坑），诊断原文见 §23 的探针记录。
static long CLSizeofParamPtr(int *arr) {
    return (long)sizeof(arr);         // 8（64 位指针），不是 20
}

long CLArrayDecaySizeof(void) {
    int arr[5] = { 1, 2, 3, 4, 5 };
    return CLSizeofParamPtr(arr);     // 传进去之后就不是数组了：8
}

// ---------------------------------------------------------------- §4 字符串
// C 字符串没有长度字段，长度是「数到 0」。所以 sizeof 和 strlen 是两回事。
size_t CLSizeofChineseLiteral(void) { return sizeof("中文"); }   // 6 字节内容 + 1 个 0
long CLUtf8LengthOfChinese(void) { return (long)strlen("中文"); }
long CLAsciiByteLen(void) { return (long)strlen("iOS"); }

long CLCharArraySizeof(void) {
    char s[] = "abc";                   // 数组：把字面量**复制**进栈上，带结尾 0
    return (long)sizeof(s);             // 4，不是 3
}

long CLTruncateToTwo(void) {
    char buf[] = "abcdef";
    buf[2] = '\0';                      // 手动插一个 0，字符串就地截断
    return (long)strlen(buf);
}

// 同一个字节，取出来的符号由 char 有没有符号决定（x86_64 有符号 / arm64 无符号）
int CLFirstByteAsChar(void) {
    const char *s = "中";               // UTF-8: E4 B8 AD
    char c = s[0];
    return (int)c;                      // 有符号 char 会给你 -28
}
int CLFirstByteAsUChar(void) {
    const char *s = "中";
    unsigned char c = (unsigned char)s[0];
    return (int)c;                      // 228，这才是字节本来的值
}

// 编译器会把同一个文件里的相同字面量合并成一份（-O0/-O2 是否都合，本章实测）
int CLStringLiteralsMerged(void) {
    const char *a = "merged-check";
    const char *b = "merged-check";
    return (a == b) ? 1 : 0;            // 只打布尔，地址本身绝不进输出
}

// strcmp 比的是内容，返回值的**符号**才是结论（具体数值是实现相关的，别断言等于 -1）
int CLStrcmpEqual(void) {
    const char *a = "iOS";
    char b[4];
    memcpy(b, a, 4);                       // 两块不同的内存，同样的内容
    return (strcmp(a, b) == 0) ? 1 : 0;    // 1：内容相等
}
int CLStrcmpSignOfAbcAbd(void) {
    const char *a = "abc";
    const char *b = "abd";                 // 谁长谁短都不重要，第一个不相等的字节定胜负
    int r = strcmp(a, b);
    return (r < 0) ? -1 : (r > 0 ? 1 : 0); // 归一成 -1，方便断言
}

// ---------------------------------------------------------------- §5 指针运算
// 加一前进多少字节 = sizeof(指向的类型)。这是指针运算唯一的一条规则。
long CLCharPtrStepBytes(void) {
    int v = 123456;
    char *p = (char *)&v;
    return (long)((char *)(p + 1) - (char *)p);      // 1
}
long CLIntPtrStepBytes(void) {
    int v = 123456;
    int *p = &v;
    return (long)((char *)(p + 1) - (char *)p);      // 4
}
long CLLongPtrStepBytes(void) {
    long v = 1;
    long *p = &v;
    return (long)((char *)(p + 1) - (char *)p);      // 8
}
long CLDoublePtrStepBytes(void) {
    double v = 1.0;
    double *p = &v;
    return (long)((char *)(p + 1) - (char *)p);      // 8
}
// void* 没有「指向的类型」，标准 C 根本不定义 void* + 1（把它列为约束违规）；
// clang 却按 GNU 扩展收下这一行、当成 1 字节 —— 连 -std=c11 都拦不住，只有 -pedantic 会警告。
// 「编译器不拦」和「标准允许」是两件事，这正是可移植性问题的来源（探针原文见 §23）。
int CLVoidPtrStepBytes(void) {
    int v = 1;
    void *p = &v;
    void *q = p + 1;                  // 标准不允许，clang 照收
    return (int)((char *)q - (char *)p);
}

// ---------------------------------------------------------------- §6 出参与二级指针
void CLOutThreeInts(int *a, int *b, int *c) {
    if (a) { *a = 11; }
    if (b) { *b = 22; }
    if (c) { *c = 33; }
}

int CLReadThroughDoublePointer(void) {
    int value = 42;
    int *p = &value;
    int **pp = &p;                    // pp 指向「那个指针」
    return **pp;                      // 先取 p，再取 p 指向的 int
}

// C 函数不会替你检查 NULL —— 检查是自己该做的事，这是 OC 里 NSError ** 写法的由来
int CLCallWithNullOut(int *out) {
    if (out == NULL) { return -1; }
    *out = 7;
    return 0;
}

// ---------------------------------------------------------------- §14 memcpy / memmove
void CLFillBuffer(char *buf, int len) {
    const char *seed = "abcdefg";
    int i;
    for (i = 0; i < len - 1 && seed[i] != '\0'; i++) { buf[i] = seed[i]; }
    buf[i] = '\0';
}

void CLCopyNonOverlap(char *dst, const char *src) {
    memcpy(dst, src, 5);              // 两块不重叠的内存：memcpy 完全够用
    dst[5] = '\0';
}

// buf 里是 "abcdefg"，把前 3 个字节搬到偏移 2 处 —— 源和目的在 buf[2]、buf[3] 上重叠。
// memmove 保证重叠也正确（它自己会判断方向）
void CLCopyOverlapWithMemmove(char *buf) {
    memmove(buf + 2, buf, 3);
}

// ---------------------------------------------------------------- §15 malloc 家族
long CLCallocZeroed(void) {
    int *p = (int *)calloc(4, sizeof(int));   // calloc 保证全 0
    long first = p ? p[0] : -1;
    free(p);
    return first;
}

int CLMallocHugeIsNull(void) {
    void *p = malloc((size_t)-1);             // 一个不可能给出来的尺寸
    int isNull = (p == NULL) ? 1 : 0;
    if (p) { free(p); }
    return isNull;                            // 这一版在 -O2 下会被折成常数，见下面第三版
}

// 同一个问题，但尺寸由调用方给。
int CLMallocIsNullForSize(size_t n) {
    void *p = malloc(n);
    int isNull = (p == NULL) ? 1 : 0;
    if (p) { free(p); }
    return isNull;
}

// 第三版：真的往那块内存写一个自己选的常数、再读回来交给调用方 —— 看着总该留下真分配了吧？
// 并没有。读回来的还是编译器自己写进去的那个常数，整块内存仍然没有任何「外部可见」的用途，
// -O2 于是把它编成「if (readBack) *readBack = 12345; return 0;」，一次 malloc 都不调（汇编见 §23）。
int CLMallocUsedIsNull(size_t n, long *readBack) {
    long *p = (long *)malloc(n);
    if (p == NULL) { if (readBack) { *readBack = -1; } return 1; }
    *p = 12345;
    if (readBack) { *readBack = *p; }
    free(p);
    return 0;
}

// 这一版把分配单独放进这个编译单元，只负责交出指针；判空写在别的编译单元（CLCollect.m 与 Swift）。
// 编译器看不穿这次调用，删不动，量到的才是分配器说的话。
void *CLMallocRaw(size_t n) { return malloc(n); }

void CLFreeRaw(void *p) { free(p); }
