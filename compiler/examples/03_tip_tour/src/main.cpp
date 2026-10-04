// 第 03 章配套程序：TIP 语法构造总览 + 用三种方式计算 5 的阶乘。
// iter  —— 对应 TIP 的 ite：while 循环
// recf  —— 对应 TIP 的 rec：递归调用
// foop  —— 模拟 TIP 的 foo：指针参数 + alloc 出来的辅助单元
#include <iostream>
#include <memory>

int iter(int n) {
    int f = 1;
    while (n > 0) {
        f = f * n;
        n = n - 1;
    }
    return f;
}

int recf(int n) {
    int f;
    if (n == 0) { f = 1; }
    else { f = n * recf(n - 1); }
    return f;
}

// 对应 foo(p, x)：p 指向输入值，沿指针读条件；
// q 模拟 alloc 0 得到的辅助单元。
int foop(int x) {
    auto p = std::make_unique<int>(x);
    int result;
    if (*p == 0) {
        result = 1;
    } else {
        auto q = std::make_unique<int>(0);
        *q = *p - 1;
        result = (*p) * foop(*q);
    }
    return result;
}

int main() {
    using namespace std;

    cout << "TIP 语法构造总览:\n";
    cout << "  表达式: 整数字面量/变量/input | 二元算术与比较 | 函数调用\n";
    cout << "          alloc/&/*/null (指针) | 记录字面量与字段访问\n";
    cout << "  语句:   赋值 | output | if-else | while | 块 | return\n";
    cout << "  程序:   函数声明的集合; main 的参数从输入流依次读入\n\n";

    int a = iter(5), b = recf(5), c = foop(5);
    cout << "factorial: " << a << ' ' << b << ' ' << c << '\n';
    if (a != 120 || b != 120 || c != 120) {
        cerr << "factorial mismatch\n";
        return 1;
    }
    cout << "[chapter 03 OK]\n";
    return 0;
}
