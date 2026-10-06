// file: src/snippets.hpp
// 与 L 书 §8.6 案例同款的 C 片段（局部变量版本——书里 x/y 是局部，帧寻址才可复现）。
#ifndef TIP_SNIPPETS_HPP
#define TIP_SNIPPETS_HPP

#include <string>
#include <vector>

namespace rc {

struct FuncSpec {
    const char *name;      // 函数名（也是文件名）
    const char *body;      // 完整 C 函数
    const char *what;      // 对应书上的哪个例子
};

// 六个片段：赋值表达式 / 数组下标 / if / while / 函数定义 / 调用。
// 返回值拼了些 +x +y，防 -O1 把局部变量当死代码删掉（书例只关心模式，不看返回值）。
inline const std::vector<FuncSpec> &snippets() {
    static const std::vector<FuncSpec> v = {
        {"e1", "int e1(void) { int x = 1; return (x = x + 3) + 4 + x; }",
         "L 书 §8.6.1 赋值表达式 (x=x+3)+4"},
        {"e2", "int e2(void) { int i = 1, j = 2; int a[10]; a[0] = 7; a[3] = 5;"
               " return (a[i+1] = 2) + a[j] + i + j; }",
         "L 书 §8.6.1 数组引用 (a[i+1]=2)+a[j]"},
        {"c1", "int c1(void) { int x = 3, y = 2; if (x > y) y++; else x--; return x + y; }",
         "L 书 §8.6.1 if 语句 if(x>y) y++ else x--"},
        {"w1", "int w1(void) { int x = 3, y = 9; while (x < y) y -= x; return y; }",
         "L 书 §8.6.1 while 语句 while(x<y) y-=x"},
        {"f1", "int f1(int x, int y) { return x + y + 1; }",
         "L 书 §8.6.1 函数定义 int f(int x,int y)"},
        {"cf", "int f1(int x, int y); int cf(void) { return f1(2 + 3, 4) + 1; }",
         "L 书 §8.6.1 调用 f(2+3,4)"},
    };
    return v;
}

}  // namespace rc

#endif  // TIP_SNIPPETS_HPP
