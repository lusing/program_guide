// ============================================================
// 28 章 · C 层实测（第一半之前的那一半：类型、运算符、控制语句）
//
// 纯 C，没有 Foundation，一行都打印不出来。它只负责「量」：
// 每个函数回答一个可以直接断言的小问题，答案全是整型，交给 CLCollect.m / main.swift 去格式化。
//
// 为什么这一节值得从头量一遍：《iOS开发从入门到精通》第 2/3 章讲的就是这些，
// 而它们决定了后面所有内存代码的对错 —— char 有没有符号、除法往哪边取整、
// 0.1 + 0.2 为什么不等于 0.3、switch 少一个 break 会怎样。
// 这些结论在 Swift 侧很多是**反过来**的（Swift 的 Int 恒为 64 位、溢出直接 trap、
// 裸类型不隐式转换），所以本章把 C 的量法摆在这里，Swift 的对照放 §18。
// ============================================================
#include "CLTypes.h"
#include <limits.h>    // INT_MAX / SCHAR_MIN / SCHAR_MAX
#include <math.h>      // isinf / signbit / atan2f（§8 的负零证据）
#include <stdlib.h>    // malloc / free（§2 的 goto 清理段要用）

// ---------------------------------------------------------------- §1 数据类型

size_t CLSizeofChar(void)      { return sizeof(char); }        // 永远是 1，这是定义不是实测
size_t CLSizeofShort(void)     { return sizeof(short); }
size_t CLSizeofInt(void)       { return sizeof(int); }
size_t CLSizeofLong(void)       { return sizeof(long); }       // Apple(LL64) 8，Windows 4
size_t CLSizeofLongLong(void)  { return sizeof(long long); }   // 到哪都是 8
size_t CLSizeofFloat(void)     { return sizeof(float); }
size_t CLSizeofDouble(void)    { return sizeof(double); }
size_t CLSizeofIntPtr(void)    { return sizeof(int *); }
size_t CLSizeofSizeT(void)     { return sizeof(size_t); }
size_t CLSizeofPtrDiff(void)   { return sizeof(ptrdiff_t); }

size_t CLAlignmentOfInt(void)    { return _Alignof(int); }
size_t CLAlignmentOfPackA(void)  { return _Alignof(struct CLPackA); }
size_t CLAlignmentOfDouble(void) { return _Alignof(double); }

// 裸 char 有没有符号是**实现定义**的，不是标准规定的：这一条只能在真机器上量
int CLCharIsSigned(void) {
    char c = (char)-1;
    return (c < 0) ? 1 : 0;
}

long CLMaxSignedChar(void)   { return (long)SCHAR_MAX; }   // 127
long CLMinSignedChar(void)   { return (long)SCHAR_MIN; }   // -128 或 0
long CLMaxInt(void)          { return (long)INT_MAX; }

// 无符号算术**定义**了回绕（模 2^n），有符号溢出才是未定义行为，所以这里只用无符号量
long CLUnsignedWrapAfterMax(void) {
    unsigned int u = (unsigned int)INT_MAX;
    u += 1u;                       // 2147483648：回绕到 0x80000000
    return (long)u;
}

// ---- 整型除法与余数：C99 起明确「向 0 取整」，于是余数的符号跟着被除数 ----
int CLIntDivTrunc(void)          { return 7 / 2; }     // 3
int CLIntDivNegativeTrunc(void)  { return -7 / 2; }    // -3，不是 -4
int CLModNegative(void)          { return -7 % 2; }    // -1，不是 1
int CLModPositive(void)          { return 7 % 2; }     // 1

// 整型提升：char 参与运算前会先升成 int，所以「两个 char 相加」的结果类型是 int
long CLPromotionResultSizeof(void) {
    char a = 1, b = 2;
    return (long)sizeof(a + b);   // 4，不是 1
}

// ---- 浮点：位数就那么多，超出就是丢，不会报错 ----
int CLFloatToIntTrunc(void)        { return (int)3.9; }      // 3：向 0 截断
int CLNegativeFloatToIntTrunc(void){ return (int)-3.9; }     // -3：也是向 0，不是向下取整
int CLDoubleSumEqualsPointThree(void) {
    double s = 0.1 + 0.2;
    return (s == 0.3) ? 1 : 0;    // 0
}
// float 只有 24 位有效尾数，2^24+1 这个整数就存不下了，会被吸到 2^24
int CLFloatCannotHold2To24Plus1(void) {
    float big = 16777217.0f;      // 2^24 + 1
    float base = 16777216.0f;     // 2^24
    return (big == base) ? 1 : 0;
}
// +0.0 与 -0.0：位模式不同，但 == 比较相等。写成函数而不是在调用点直接比，
// 是为了让「相等」这一步真的在运行时发生一次（也让 Swift 侧能拿到同一个答案）。
int CLFloatZeroEqualsNegativeZero(void) {
    float a = 0.0f, b = -0.0f;
    return (a == b) ? 1 : 0;
}
// 除法是「负零真的存在」的第一处证据：1.0f / -0.0f 给的是负无穷，不是正无穷。
int CLReciprocalOfNegativeZeroIsNegInf(void) {
    float v = 1.0f / -0.0f;
    return (isinf(v) && signbit(v)) ? 1 : 0;
}
// atan2 是第二处：它专门按符号区分两个零，所以 -pi 与 +pi 分得开。
int CLAtan2DistinguishesZeros(void) {
    float a = atan2f(-0.0f, -1.0f);   // -pi
    float b = atan2f(0.0f, -1.0f);    // +pi
    return (a < 0 && b > 0 && a != b) ? 1 : 0;
}
// 把「0.1 + 0.2」那多出来的位打出来：位模式是确定的整数，可以断言
long CLDoubleToLongBits(void) {
    union CLDoubleBits u;
    u.d = 0.1 + 0.2;
    return (long)u.bits;          // 只有低位会用到，见 §1 的打印
}
long CLDoubleBitsOfPointThree(void) {
    union CLDoubleBits u;
    u.d = 0.3;
    return (long)u.bits;
}

// ---------------------------------------------------------------- §2 运算符与控制语句

int CLPrefixPostfixFirst(void) {
    int i = 5;
    int a = i++;                   // 先给值，再自增
    return a;                      // 5
}
int CLPrefixPostfixSecond(void) {
    int i = 5;
    (void)i++;                     // 上面那句的后续
    int b = ++i;                   // 先自增，再给值
    return b;                      // 7
}

int CLPrecedenceSum(void)     { return 2 + 3 * 4; }        // 14：乘除优先于加减
int CLTernaryPrecedence(void) {
    int a = 3, b = 4;
    int r = a > b ? a : b + 1;     // 逗号最低，?: 倒数第二；这里加的是 b + 1
    return r;                      // 5，不是 4
}

int CLBitwiseAnd(void) { return 12 & 10; }   // 1000 & 1010 = 1000
int CLBitwiseOr(void)  { return 12 | 10; }   // 1110
int CLBitwiseXor(void) { return 12 ^ 10; }   // 0110
int CLBitwiseNotZero(void) { return ~0; }    // -1：按位取整，符号位也跟着翻

// 1 << 31 对有符号 int 是未定义行为，所以从无符号出发，再显式转回来（这是实现定义，clang 给回绕值）
int CLShiftLeftOne31(void) {
    unsigned int u = 1u << 31;     // 2147483648，无符号这边完全合法
    return (int)u;                 // -2147483648
}
long CLShiftLeftOne31Unsigned(void) { return (long)(1u << 31); }
int CLArithmeticShiftRight(void) { return -8 >> 1; }   // -4：有符号右移补符号位（实现定义，clang 是算数右移）
int CLLogicalShiftRight(void) {
    unsigned int u = (unsigned int)-8;   // 0xFFFFFFF8
    return (int)(u >> 1);                // 0x7FFFFFFC：高位补 0，得到一个很大的正数
}

// 短路：右边根本不参与运算，所以副作用次数能直接量出来
static int gOpSideEffects = 0;
static int CLSideEffectOp(void) { gOpSideEffects += 1; return 1; }
static void CLResetOpSideEffects(void) { gOpSideEffects = 0; }
int CLShortCircuitAndCalls(void) {
    CLResetOpSideEffects();
    int r = 0 && CLSideEffectOp();       // 左边已经是 0，右边不执行
    (void)r;
    return gOpSideEffects;               // 0
}
int CLShortCircuitOrCalls(void) {
    CLResetOpSideEffects();
    int r = 1 || CLSideEffectOp();       // 左边已经是 1，右边不执行
    (void)r;
    return gOpSideEffects;               // 0
}
int CLShortCircuitAndRunsCalls(void) {
    CLResetOpSideEffects();
    int r = 1 && CLSideEffectOp();       // 这个必须跑才能决定结果
    (void)r;
    return gOpSideEffects;               // 1
}

long CLForLoopSum0To9(void) {
    long sum = 0;
    for (int i = 0; i < 10; i++) { sum += i; }
    return sum;                          // 45
}
int CLWhileLoopCount(void) {
    int n = 0, i = 0;
    while (i < 5) { i++; n += 2; }
    return n;                            // 10
}
int CLDoWhileRunsOnce(void) {
    int n = 0, i = 10;
    do { n += 1; i += 1; } while (i < 5); // 条件一开始就是假
    return n;                            // 1：do-while 至少跑一次
}
int CLContinueCount(void) {
    int n = 0;
    for (int i = 0; i < 10; i++) {
        if (i % 2 == 0) { continue; }    // continue 只跳过本轮剩下的语句
        n += 1;
    }
    return n;                            // 5
}
// break 只跳**最内层**一层循环，这是 C 里没有「跳出外层」语法时唯一的老办法
int CLNestedLoopFlagBreakCount(void) {
    int hits = 0;
    int done = 0;
    for (int i = 0; i < 5 && !done; i++) {
        for (int j = 0; j < 5; j++) {
            if (i * j >= 6) { done = 1; break; }  // 这个 break 只出内层，靠 done 停外层
            hits += 1;
        }
    }
    return hits;
}
// 少写 break 会连着往下跑：这就是 -Wimplicit-fallthrough 存在的理由。
// 这里用 __attribute__((fallthrough)) 而不是传统的「// fall through」注释 ——
// 本机 Apple clang 16 只认前者：开着 -Wimplicit-fallthrough 时，
// 五种注释写法（// fall through、/* fall through */、/* FALLTHRU */、/* falls through */、
// /* -FALL-THROUGH- */）全都照警告，只有这个属性（以及 C23 的 [[fallthrough]];）能压住。
// 原文与另一条实测：-Wall -Wextra 根本不会打开这条警告，必须显式点名。见 §2 正文与 §23 探针记录。
int CLSwitchFallthroughAdds(void) {
    int total = 0;
    for (int k = 0; k < 3; k++) {
        switch (k) {
            case 0:
                total += 1;
                __attribute__((fallthrough));   // 少写这一行，case 1 也会被跑一遍
            case 1:
                total += 10;
                break;
            case 2:
                total += 100;
                break;
            default:
                total += 1000;
                break;
        }
    }
    return total;                        // (1+10) + 10 + 100 = 121
}
// default 写在最前面也一样是「谁都不匹配才走它」，位置不影响语义
int CLSwitchDefaultFirstValue(void) {
    int v = 2;
    switch (v) {
        default: return 999;
        case 1: return 11;
        case 2: return 22;
    }
}
// C 的函数没有异常，出错就一路 goto 到清理段 —— iOS 底层（CoreFoundation、sqlite3）全是这个形状
int CLGotoCleanupValue(void) {
    int opened = 0;
    int wrote = 0;
    int result = -1;
    void *handle = NULL;
    handle = malloc(8);
    if (handle == NULL) { goto fail; }
    opened = 1;
    wrote = 1;
    if (!opened) { goto fail; }
    result = opened * 1 + wrote * 10;    // 11：一切顺利
    free(handle);
    return result;
fail:
    if (opened) { /* 这里才需要收尾 */ }
    free(handle);                        // free(NULL) 是合法的，所以这一句可以无条件写
    return result;
}
