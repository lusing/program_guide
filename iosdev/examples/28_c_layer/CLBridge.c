// ============================================================
// 28 章 · 跨界接口（§17）
//
// 这个文件里的函数**不只被 C 自己调**：CLCollect.m 从 ObjC 调一遍，main.swift 从 Swift 调一遍。
// 三份调用看到的是同一个 CLTypes.h 里的同一份声明，所以「C 的返回值在 OC 和 Swift 里一致」
// 这句话在本章不是我说说的，是编译出来的 —— 两边任何一个数字对不上，断言就会 FAIL。
//
// 刻意避开的两件事：
//   1) 不返回指针给外面「拥有」。返回 const char * 的那个函数给的是**字符串字面量**，
//      活在只读数据段，进程结束前一直有效，外面只读不 free —— 这是 C 库最常见也最安全的一种。
//   2) 不接收「外面分配、我来 free」的内存。那种所有权交接是崩的主要来源，
//      本章只在 §10 的不透明句柄里由 C 自己 malloc、自己 free。
// ============================================================
#include "CLTypes.h"
#include <string.h>   // memset

// C 往调用方给的结构体里写值：OC/Swift 都得先造好一个结构体再把地址交进来
void CLFillPackB(struct CLPackB *out) {
    if (out == NULL) { return; }
    out->i = 100;
    out->c = 1;
    out->d = 2;
}

// 按值返回一个结构体：跨界传「小结构体」在 ObjC 里走 objc_msgSend 的老路，在 Swift 里是普通返回值
struct CLPackB CLMakePackB(void) {
    struct CLPackB s;
    s.i = 7;
    s.c = 3;
    s.d = 4;
    return s;
}

// const 指针 = 「我只读，不改你的东西」这个约定在 C 里的写法
int CLSumPackB(const struct CLPackB *s) {
    if (s == NULL) { return -1; }
    return s->i + s->c + s->d;
}

// C 拥有的字符串：外面拿到 const char *，读，不 free
const char *CLStaticCString(void) { return "C 侧的字面量"; }

// 就地改调用方的内存：Swift 传 withUnsafeMutableBufferPointer 的基址进来，
// 函数返回后原数组真的变了 —— 这是「C 函数没有返回值也能改到外面」的正解。
void CLBumpEach(int *arr, int count) {
    if (arr == NULL) { return; }
    for (int i = 0; i < count; i++) { arr[i] += 1; }
}

// 只读地扫一遍调用方的数组
int CLCountBelow(const int *arr, int count, int limit) {
    if (arr == NULL) { return -1; }
    int n = 0;
    for (int i = 0; i < count; i++) { if (arr[i] < limit) { n += 1; } }
    return n;
}

// 收一个函数指针进来调：Swift 侧的 @convention(c) 闭包就是从这里进 C 的
int CLCallMap(CLIntMap fn, int value) {
    if (fn == NULL) { return -1; }      // 函数指针可以为 NULL，所以每一句调用前都要挡
    return fn(value);
}

// 同一个函数调两次：纯函数会得到两个一样的数，带捕获的 block 未必
int CLApplyTwice(CLIntMap fn, int value) {
    if (fn == NULL) { return -1; }
    return fn(value) + fn(value);
}

// 两个函数指针是不是同一个实现：只打布尔，地址本身绝不进输出
int CLSameFunctionPointer(CLIntMap a, CLIntMap b) { return (a == b) ? 1 : 0; }

// 造一个「padding 也清零」的 CLPackA 交给调用方：
// Swift 侧要拿 withUnsafeBytes 数非零字节，如果 padding 里是栈上的脏数据，
// debug 与 release 就会数出两个不同的结果 —— 这个函数存在的唯一理由是把不可复现的内存涂干净。
void CLPreparePackA(struct CLPackA *out, int c, int i, int d) {
    if (out == NULL) { return; }
    memset(out, 0, sizeof(struct CLPackA));
    out->c = (char)c;
    out->i = i;
    out->d = (char)d;
}
