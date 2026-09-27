#include <print>

#include "util.h"
#include "util.h"   // 故意包含两次：没有 include guard 这里就重复定义、编译报错

// 25 预处理器与翻译单元：宏、条件编译、ODR 与链接性

// 宏拼出的变量名：## 把 token 粘成 my_rank ——元编程时代之前的主流技巧
int CAT(my_, rank) = 9;

int main() {
    // ═══ 25.1 宏替换与它的现代替代 ═══
    std::println("APP_NAME = {}（宏：纯文本替换）", APP_NAME);
    std::println("k_max_retry = {}（constexpr：有类型、守作用域）", k_max_retry);
    std::println("STR(1 + 2) = \"{}\"（# 把实参原样变成字符串，不求值）", STR(1 + 2));
    std::println("CAT 拼出的变量 my_rank = {}", my_rank);
    TRACE("这条只有定义了 SHOW_TRACE 才会打印");

    // ═══ 25.2 头文件的 inline 定义 + 跨文件的外部实体 ═══
    std::println("twice(21) = {}（头文件里 inline 定义的函数）", twice(21));
    int first_bump = app::bump();    // 带副作用的调用先落地为变量——别指望实参求值顺序
    int second_bump = app::bump();
    std::println("app::bump() = {}，再来一次 = {}（定义在别的翻译单元）",
                 first_bump, second_bump);
    std::println("visits = {}（extern 变量：定义在 util.cpp）", visits);
    std::println("shared_hits() = {}（内部链接的 static/匿名空间对你是隐形的）", shared_hits());

    // ═══ 25.3 预定义宏与编译期探测 ═══
    std::println("本行源码行号 __LINE__ = {}", __LINE__);
    std::println("编译器标准 ≥ C++23？{}", __cplusplus >= 202302L);
#if __has_include(<version>)
    std::println("有 <version> 头（可用 __cpp_lib_* 特性宏探测库特性）: true");
#else
    std::println("有 <version> 头: false");
#endif
#ifdef __cpp_lib_ranges
    std::println("__cpp_lib_ranges = {}（数字是特性入标的年月）", __cpp_lib_ranges);
#endif
    static_assert(sizeof(void*) >= 8, "需要 64 位平台");   // 编译期断言：不满足直接构建失败

    std::println("自检通过");
}
