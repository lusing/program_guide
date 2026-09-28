#ifndef GUIDE_UTIL_H        // include guard：同一个翻译单元里重复 #include 也只生效一次
#define GUIDE_UTIL_H        // （没有它，二次包含 = 二次定义 = ODR 违规、编译报错）
                           // #pragma once 是主流编译器的等价简写，但标准没有它

// ── 宏：C 时代的“常量”与现代替代 ──────────────────────────
#define APP_NAME "guide"    // 三宗罪：无类型、无作用域、纯文本盲替换 → 新代码用 constexpr
inline constexpr int k_max_retry = 3;   // constexpr：有类型、守作用域、可调试

// ── 头文件里的定义必须 inline（ODR：定义在每个包含处出现，必须允许）──
inline int twice(int x) { return 2 * x; }
inline const char* app_label() { return APP_NAME; }   // 宏只在预处理期替换，产物是普通函数

// ── 声明与定义分离：声明进头文件，定义留在 util.cpp ──
int shared_hits();                    // 外部函数：默认外部链接
extern int visits;                    // extern：变量“定义在别处”的声明（定义在 util.cpp）

namespace app {                       // 命名空间给名称上“户口”
    int bump();
}

// ── 条件编译：发布构建常见的开关宏 ──
#ifdef SHOW_TRACE
#define TRACE(msg) std::println("[trace] {}", msg)
#else
#define TRACE(msg) ((void)0)          // 关掉时替换成空操作：零开销
#endif

// ── 预处理操作符：# 字符串化、## 拼接 ──
#define STR(x) #x
#define CAT(a, b) a##b

#endif // GUIDE_UTIL_H
