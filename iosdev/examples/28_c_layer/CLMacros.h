// ============================================================
// 28 章 · 宏 playground（纯 C 头文件）
//
// 这一节的每一个宏都**真的被调用**，结果由 CLLayout.c 取走交给上层打印。
// 宏的全部麻烦都在「它是编译前的文本替换」这一条上，所以这里刻意写成
// 三种经典坑：不加括号、展开两次、多语句。对照写法一起放着，好比较。
// ============================================================
#ifndef CLMacros_h
#define CLMacros_h

// 坑 1：不带括号。传 a+b 进去，乘号的位置就变了
#define CL_SQR_BAD(x) x *x

// 同样的表达式，加括号只解决了「优先级」，没解决「展开两次」
#define CL_SQR_PAREN(x) ((x) * (x))

// 坑 2：参数会被**展开两次**。传带副作用的表达式进去，副作用就发生两次。
// 这里刻意不用 i++（两次自增之间没有顺序点，是未定义行为，结果不作证据），
// 改用一个「每次调用都返回不同值」的函数 —— 它有明确定义，且展开次数直接写在返回值里。
#define CL_TWICE(x) ((x) + (x))

// 同一个表达式的函数版本（声明在 CLTypes.h）：参数在调用前求值一次，所以副作用只有一次

// 多语句宏的正确写法：包进 do{...}while(0)，调用点才能当一条语句用
#define CL_BUMP_TWO(target)  do { (target) += 1; (target) += 1; } while (0)

// # 把宏参数变成字符串字面量（日志宏的原料）
#define CL_STRINGIFY(x) #x

// ## 把两个记号拼成一个标识符
#define CL_PASTE(a, b) a##b

// 条件编译：本章在 x86_64 与 arm64 上会走不同的分支，打印「走了哪一支」而不是分支内容
#if defined(__LP64__)
#  define CL_WORD_BRANCH 1        // 64 位（模拟器与真机都是这一支）
#else
#  define CL_WORD_BRANCH 0
#endif

// __has_include 是「这个头文件在不在」的编译期检查，跨 SDK 版本写兼容代码就靠它
#if defined(__has_include)
#  if __has_include(<stdint.h>)
#    define CL_HAS_STDINT 1
#  else
#    define CL_HAS_STDINT 0
#  endif
#else
#  define CL_HAS_STDINT -1
#endif

// 用 ## 拼出来的标识符：CL_PASTE(CL_, answer) -> CL_answer
#define CL_answer 77

#endif /* CLMacros_h */
