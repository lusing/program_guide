// ============================================================
// 28 章 · C 层的「对外类型」头文件
//
// 这个文件是**纯 C**（不带任何 ObjC/Foundation 依赖），它会同时被三方 include：
//   CLMemory.c / CLLayout.c  —— 真正实现的地方（clang 按 C 编译，没有 -fobjc-arc）
//   CLCollect.m              —— ObjC 侧调用并格式化
//   Bridging.h               —— Swift 侧透过它看到全部 C 符号
// 三方看到的是同一份声明，所以「同一个 C 函数从 OC 和 Swift 各调一次、结果必须一致」
// 这件事在本章是结构上成立的，不是我口头保证的。
// ============================================================
#ifndef CLTypes_h
#define CLTypes_h

#include <stddef.h>   // size_t / ptrdiff_t / offsetof
#include <stdint.h>   // int32_t / uint64_t：C 里唯一该用的整数类型

// ------------------------------------------------------------ 结构体：三种字段顺序
// 同样的字段、不同的书写顺序，sizeof 会差出 4 个字节。§7 拿它做实测。
struct CLPackA { char c; int i; char d; };    // 顺序「最差」的那个
struct CLPackB { int i; char c; char d; };    // 同类字段挤在一起
struct CLPackC { char c; char d; int i; };    // 和 B 等价，只是 c/d 在前

// 嵌套：结构体里套结构体。对齐由**最宽成员**决定 —— CLPackB 最宽的成员是 int（4），
// 所以整个嵌套结构的对齐也是 4，不是外部直觉上的「8 的倍数」。实测见 §7。
struct CLRectLike {
    struct CLPackB origin;   // 8 字节（int + char + char + 补 2）
    int extra;               // 4 字节；8 + 4 = 12 已经是 4 的倍数，所以尾部不用再补
};

// ------------------------------------------------------------ 联合体：看位模式用
union CLFloatBits {
    float    f;
    uint32_t bits;      // 所有成员都从同一块内存的起点开始，谁大谁定 sizeof
};

// double 那一头同理：8 字节 + 64 位整数
union CLDoubleBits {
    double     d;
    uint64_t   bits;
};

// ------------------------------------------------------------ 枚举
enum CLColor { CL_RED = 1, CL_GREEN = 2, CL_BLUE = 4, CL_BIG = 100000 };

// 带负数的枚举，看看编译器实际选了多大的整型
enum CLSigned { CL_NEG = -7, CL_POS = 7 };

// ------------------------------------------------------------ 不透明句柄
// C 库的经典做法：类型名给外面，结构体定义只留在 .c 里（CoreFoundation 全系列都这样）。
// 外面拿到的只是一个指针，看不见字段，也构造不出来。
typedef struct CLOpaque *CLOpaqueRef;

// ------------------------------------------------------------ 函数指针类型
// 命名清楚一点，后面三处（qsort 比较、回调表、Swift 的 @convention(c)）都要用。
typedef int (*CLCompare)(int, int);
typedef int (*CLIntMap)(int);

// ============================================================
// 下面每个函数都只回答一个可以直接断言的问题。
// 返回类型一律用整型/浮点，不返回指针 —— 打印地址会把「每次运行都不同」的东西
// 带进输出，本章只打差值和布尔。
// ============================================================

// ---- §1 数据类型：尺寸、范围、转换 ----
size_t      CLSizeofChar(void);
size_t      CLSizeofShort(void);
size_t      CLSizeofInt(void);
size_t      CLSizeofLong(void);          // 注意：Windows(LLP64) 上是 4，Apple 是 8
size_t      CLSizeofLongLong(void);      // 这个才是「哪台机器都是 8」的那一个
size_t      CLSizeofFloat(void);
size_t      CLSizeofDouble(void);
size_t      CLSizeofIntPtr(void);        // 指针尺寸和 int 是不是同宽，全靠这一条量
size_t      CLSizeofSizeT(void);
size_t      CLSizeofPtrDiff(void);
int         CLCharIsSigned(void);        // 裸 char 有没有符号：x86_64 有，arm64 没有
long        CLMaxSignedChar(void);       // SCHAR_MAX
long        CLMinSignedChar(void);       // SCHAR_MIN
long        CLMaxInt(void);              // INT_MAX
long        CLUnsignedWrapAfterMax(void);// (unsigned)INT_MAX + 1u：无符号必定回绕
int         CLIntDivTrunc(void);         // 7 / 2
int         CLIntDivNegativeTrunc(void); // -7 / 2：向 0 取整，不是向下
int         CLModNegative(void);         // -7 % 2：符号跟着被除数
int         CLModPositive(void);         //  7 % 2
long        CLPromotionResultSizeof(void);// sizeof((char)1 + (char)2) —— 结果是 int，不是 char
int         CLFloatToIntTrunc(void);     // (int)3.9
int         CLNegativeFloatToIntTrunc(void); // (int)-3.9
int         CLDoubleSumEqualsPointThree(void);// 0.1 + 0.2 == 0.3 ？
int         CLFloatCannotHold2To24Plus1(void);// (float)16777217 == (float)16777216 ？
int         CLFloatZeroEqualsNegativeZero(void);// 0.0f == -0.0f？位模式不同但比较相等
int         CLReciprocalOfNegativeZeroIsNegInf(void);// 1.0f / -0.0f 是不是负无穷
int         CLAtan2DistinguishesZeros(void);   // atan2 把 -0.0 与 +0.0 分在 -pi / +pi 两侧
long        CLDoubleToLongBits(void);    // 把 0.1+0.2 的位模式取出来
long        CLDoubleBitsOfPointThree(void); // 0.3 自己的位模式，和上面那条对照
size_t      CLAlignmentOfInt(void);
size_t      CLAlignmentOfDouble(void);
size_t      CLAlignmentOfPackA(void);      // 结构体的对齐 = 最宽成员的对齐；Swift 侧对照 MemoryLayout.alignment

// ---- §2 运算符与控制语句 ----
int         CLPrefixPostfixFirst(void);  // i = 5; a = i++ 里 a 是多少
int         CLPrefixPostfixSecond(void); // 紧接着 b = ++i 里 b 是多少
int         CLPrecedenceSum(void);       // 2 + 3 * 4
int         CLTernaryPrecedence(void);   // a > b ? a : b + 1 真正比的是什么
int         CLBitwiseAnd(void);          // 12 & 10
int         CLBitwiseOr(void);           // 12 | 10
int         CLBitwiseXor(void);          // 12 ^ 10
int         CLBitwiseNotZero(void);      // ~0
int         CLShiftLeftOne31(void);      // 1 << 31 落到有符号 int 里是什么
long        CLShiftLeftOne31Unsigned(void);// 1u << 31
int         CLArithmeticShiftRight(void);// -8 >> 1
int         CLLogicalShiftRight(void);   // (unsigned)-8 >> 1 再转回来
int         CLShortCircuitAndCalls(void);// 0 && sideEffect() —— sideEffect 跑了几次
int         CLShortCircuitOrCalls(void); // 1 || sideEffect()
int         CLShortCircuitAndRunsCalls(void);// 1 && sideEffect() —— 这条必须真跑
int         CLContinueCount(void);       // for 里 continue 跳过了几个
int         CLDoWhileRunsOnce(void);     // 条件一开始就是假，do{}while 仍跑一次
int         CLNestedLoopFlagBreakCount(void);// 双层循环靠 flag 跳出：内层 break 只出一层
int         CLSwitchFallthroughAdds(void);   // switch 少写一个 break 会连着往下跑
int         CLSwitchDefaultFirstValue(void); // default 写在最前面也照样是「兜底」
int         CLGotoCleanupValue(void);    // C 里清理代码的标准形态：goto fail
long        CLForLoopSum0To9(void);      // 最普通的一次遍历
int         CLWhileLoopCount(void);

// ---- §3 数组退化：sizeof 在函数里就不对了 ----
size_t      CLSizeofInt5(void);          // sizeof(int[5])
long        CLIntArrayCount(void);       // sizeof(a)/sizeof(a[0])
long        CLGapInElements(void);       // &a[3] - a
long        CLGapInBytes(void);          // (char*)&a[3] - (char*)&a
long        CLRowGapInBytes(void);       // (char*)&m[1][0] - (char*)&m[0][0]
long        CLWholeArrayPlusOneGap(void);// (char*)(int(*)[5]) 那种加一的字节跨度
long        CLSumViaPointer(void);       // 纯指针算术把 a[0..4] 加起来
int         CLAtRowCol(void);            // m[1][2]，证明行主序没把值挪走
long        CLArrayDecaySizeof(void);    // 传进函数的「数组」的 sizeof
long        CLSizeofRealArray(void);     // 本地真数组的 sizeof（对照组）

// ---- §4 字符数组与 C 字符串 ----
size_t      CLSizeofChineseLiteral(void);// sizeof("中文") —— 字节数 + 1
long        CLUtf8LengthOfChinese(void); // strlen("中文") = 6（UTF-8 每字 3 字节）
long        CLCharArraySizeof(void);     // char s[] = "abc" 的 sizeof
long        CLTruncateToTwo(void);       // 手动补 '\0' 之后 strlen 变几
long        CLAsciiByteLen(void);        // "iOS" 的 strlen
int         CLFirstByteAsChar(void);     // "中" 的第一个字节，按 plain char 取（会翻负）
int         CLFirstByteAsUChar(void);    // 同一个字节，按 unsigned char 取
int         CLStringLiteralsMerged(void);// 同一个 .c 里两处 "abc" 是不是同一个地址
int         CLStrcmpEqual(void);         // strcmp 比内容，不是比地址
int         CLStrcmpSignOfAbcAbd(void);// "abc" vs "abd"：把返回值的符号归一成 -1/0/1

// ---- §5 指针运算 ----
long        CLCharPtrStepBytes(void);    // (char*)p + 1 与 p 的字节差
long        CLIntPtrStepBytes(void);     // int* 加一
long        CLLongPtrStepBytes(void);    // long* 加一
long        CLDoublePtrStepBytes(void);  // double* 加一
int         CLVoidPtrStepBytes(void);    // void* 加一（GNU 扩展按 1 字节！）

// ---- §6 指针的指针与出参 ----
void        CLOutThreeInts(int *a, int *b, int *c);        // 三个出参
int         CLReadThroughDoublePointer(void);              // 二级指针把值取出来
int         CLCallWithNullOut(int *out);                   // 传 NULL 进去：C 函数自己挡不挡

// ---- §7~§9 结构体、联合体、枚举 ----
size_t      CLSizeofPackA(void);
size_t      CLSizeofPackB(void);
size_t      CLSizeofPackC(void);
size_t      CLSizeofRectLike(void);
size_t      CLOffsetIInA(void);
size_t      CLOffsetDInA(void);
size_t      CLOffsetIInB(void);
size_t      CLOffsetExtraInRect(void);
size_t      CLSizeofFloatBits(void);
uint32_t    CLBitsOf(float f);           // 用 union 把一个 float 的位模式取出来
uint32_t    CLSignOfBits(uint32_t bits);      // 只留最高位
uint32_t    CLExponentField(uint32_t bits);   // 指数段（含偏置 127）
uint32_t    CLMantissaField(uint32_t bits);   // 尾数段
size_t      CLSizeofColorEnum(void);
long        CLColorValue(enum CLColor c);      // 传进去再打出来，看它就是个整数
size_t      CLSizeofSignedEnum(void);
long        CLColorSubtractWrapped(void);   // (long)(enum CLColor)(RED - BLUE)：无符号底会回绕成正数
long        CLSignedSubtractWrapped(void);  // (long)(enum CLSigned)(NEG - POS)：有符号底就是负数

// ---- §10 不透明句柄：手写一套 Create/Retain/Release ----
CLOpaqueRef CLOpaqueCreate(int seed);    // malloc 出来的，引用计数 1
void        CLOpaqueRetain(CLOpaqueRef h);
void        CLOpaqueRelease(CLOpaqueRef h);   // 计数归零才真 free
long        CLOpaqueRefCount(CLOpaqueRef h);
int         CLOpaqueSeed(CLOpaqueRef h);
long        CLOpaqueAliveObjects(void);  // 进程内还活着的句柄个数（只在本章用，见判定纪律）

// ---- §11~§13 函数：值传递、可变参数、函数指针表 ----
void        CLTrySwap(int x, int y);     // 故意只在函数内部换，验证「值传递换不动外面」
int         CLSumVarargs(int count, ...);      // va_start/va_arg/va_end
int         CLMaxOfVarargs(int count, ...);
int         CLAddFunc(int a, int b);
int         CLMulFunc(int a, int b);
int         CLFibonacci(int n);          // 递归
int         CLDoubleOf(int x);           // 回调表里的三个函数
int         CLSquareOf(int x);
int         CLNegateOf(int x);
CLIntMap    CLMapAt(int index);          // 按下标从表里取函数指针（越界给 NULL）
const char *CLMapNameAt(int index);      // 表里存的名字（只打名字，不打指针）
int         CLApplyTable(int index, int value);  // 取不到函数时静默返回 -9999
long        CLTableSize(void);           // 表里有几项
int         CLCompareAsc(const void *pa, const void *pb);   // qsort 要的签名
void        CLSortInts(int *arr, int count);                // 内部调 qsort
int         CLSearchSorted(int *arr, int count, int key);   // 内部调 bsearch，找不到给 -1

// ---- §14 memcpy / memmove 与重叠 ----
void        CLCopyNonOverlap(char *dst, const char *src);      // 正常拷贝
void        CLCopyOverlapWithMemmove(char *buf);               // 重叠区用 memmove（定义行为）
void        CLFillBuffer(char *buf, int len);                  // 给上面两个准备初始内容

// ---- §15 malloc 家族 ----
long        CLCallocZeroed(void);        // calloc 之后第一个元素是不是 0
int         CLMallocHugeIsNull(void);    // 尺寸写死在源码里：-O2 会把整次分配连判空一起删掉
int         CLMallocIsNullForSize(size_t n); // 尺寸换成形参，同样的写法仍然被折
int         CLMallocUsedIsNull(size_t n, long *readBack); // 真的写入再读回：这一版仍然被折
// 上面三版全在同一个函数里「分配 + 判空」，-O2 于是能把整次分配删掉。这一版把分配单独放进
// 一个编译单元，判空写在另一个编译单元（CLCollect.m 与 Swift），编译器就看不穿、删不动了。
// 这是本章唯一两个返回 void * 的 C 函数 —— 不是疏忽，是这一节要的正是「指针必须活着离开这个函数」。
// 这是本章唯一两个「把指针交给调用方」的函数 —— 文件开头那条「不返回指针」的纪律在这里
// 故意破了：只有让指针活着离开这个函数，编译器才删不掉那次分配，量到的才是分配器的答案。
// 调用方拿到之后只判空、只写自己选的常数，绝不打印它的地址。
void        *CLMallocRaw(size_t n);
void         CLFreeRaw(void *p);

// ---- §16 宏：文本替换的账 ----
int         CLTwiceFunc(int v);          // 函数版的「乘二」，和 CL_TWICE 宏对照
void        CLResetSideEffects(void);
int         CLSideEffectOnce(void);      // 调一次计数加一，返回 10 * 当前计数
int         CLMacroTwiceValue(void);     // CL_TWICE(CLSideEffectOnce()) -> 10 + 20
int         CLMacroTwiceSideEffects(void);// 同一次调用里副作用发生了几次
int         CLFuncTwiceValue(void);      // CLTwiceFunc(CLSideEffectOnce()) -> 10 + 10
int         CLFuncTwiceSideEffects(void);// 函数版只发生 1 次
int         CLMacroSqrOfSum(int base);   // #define SQR(x) x*x 传 base+1 的结果
int         CLMacroSafeSqrOfSum(int base);   // 带括号的版本
int         CLMacroDoWhileCount(int base);   // do{...}while(0) 多语句宏
const char *CLStringifyName(void);       // # 把宏参数变成字符串字面量
int         CLPastedInto(void);          // ## 拼标识符
const char *CLCurrentFuncName(void);     // __func__
long        CLConditionBranchId(void);   // #if defined(__LP64__) 之类走的是哪一支

// ---- §17 跨界接口：C 提供、OC/Swift 各自调一遍 ----
// 这一组的返回值都是「可以直接断言的数」，同一个函数会被 OC 侧和 Swift 侧各调一次，
// 两边打印出来的必须一模一样 —— 结构上是同一份声明，不是两处重复实现。
void        CLFillPackB(struct CLPackB *out);   // C 往调用方给的结构体里写
struct CLPackB CLMakePackB(void);               // C 按值返回一个结构体（跨界传结构体的形态）
int         CLSumPackB(const struct CLPackB *s);// 收 const 指针：只读约定
const char *CLStaticCString(void);              // C 拥有的字符串，外面只读不 free
void        CLBumpEach(int *arr, int count);    // 就地改调用方的内存
int         CLCountBelow(const int *arr, int count, int limit);
int         CLCallMap(CLIntMap fn, int value);      // 收一个函数指针进来调（NULL 要挡）
int         CLApplyTwice(CLIntMap fn, int value);   // 同一个指针调两次，验证「纯函数结果可复现」
int         CLSameFunctionPointer(CLIntMap a, CLIntMap b); // 是不是同一个实现（只打布尔）
void        CLPreparePackA(struct CLPackA *out, int c, int i, int d); // 连 padding 一起清零再赋值

#endif /* CLTypes_h */
