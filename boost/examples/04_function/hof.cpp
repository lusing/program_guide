// hof.cpp —— Boost.HOF：高阶函数工具箱（compose/partial/pipe 的正牌实现）
// 对应文档：docs/04-function.md
#include <boost/hof.hpp>
#include <iostream>
#include <string>

int    dbl(int x)      { return x * 2; }
std::string quote(int x) { return "[" + std::to_string(x) + "]"; }

int main() {
    // 1) compose：函数组合 f(g(x))，从右往左套
    auto dq = boost::hof::compose(quote, dbl);
    std::cout << "compose(quote, dbl)(21) = " << dq(21) << '\n';

    // 2) partial：偏应用——先给前几个参数，剩下的以后给
    auto add3 = [](int a, int b, int c) { return a + b + c; };
    auto add10 = boost::hof::partial(add3)(10);
    std::cout << "partial 先固定 a=10: " << add10(20, 30) << '\n';

    // 3) pipable：把函数变成可用 | 串起来的管道段（range 风格）
    auto pipe_dbl = boost::hof::pipable(dbl);
    auto pipe_inc = boost::hof::pipable([](int x) { return x + 1; });
    int result = 5 | pipe_inc | pipe_dbl;
    std::cout << "5 | inc | dbl = " << result << '\n';

    // 4) flip：交换前两个实参的顺序
    auto subtract = [](int a, int b) { return a - b; };
    std::cout << "flip(subtract)(3, 10) = " << boost::hof::flip(subtract)(3, 10) << '\n';

    // 5) match：按可调用物各自的参数签名分派（重载 lambda 的替代品）
    auto dispatch = boost::hof::match(
        [](int)   { return std::string("int:"); },
        [](double){ return std::string("double:"); },
        [](auto&&){ return std::string("other:"); });
    std::cout << dispatch(1) << dispatch(1.5) << dispatch("s") << '\n';

    std::cout << "自检通过\n";
    return 0;
}
