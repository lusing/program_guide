// lambda.cpp —— Boost.Lambda（已弃用）：C++11 之前的"内联小函数"
// 对应文档：docs/04-function.md
// 这个库 2002 年诞生，用表达式模板在 C++03 里模拟 lambda——
// C++11 的语言级 lambda 让它退役（1.92 里还在，标了 deprecated）。
#include <boost/lambda/lambda.hpp>
#include <algorithm>
#include <iostream>
#include <vector>

int main() {
    using namespace boost::lambda;   // _1, _2, _3 占位符

    std::vector<int> v{1, 2, 3, 4, 5};

    // _1 + 10 整体是个表达式模板对象，不是值——传给 for_each 才实例化
    std::for_each(v.begin(), v.end(), std::cout << _1 * 2 << ' ');
    std::cout << '\n';

    int sum = 0;
    std::for_each(v.begin(), v.end(), sum += _1);   // 可变状态也能写进表达式
    std::cout << "sum=" << sum << '\n';

    // 同一件事的 C++11 写法（对比着看，体会语言级 lambda 赢在哪）：
    int sum2 = 0;
    std::for_each(v.begin(), v.end(), [&sum2](int x) { sum2 += x; });
    std::cout << "C++11 lambda: sum2=" << sum2 << '\n';

    std::cout << "自检通过\n";
    return 0;
}
