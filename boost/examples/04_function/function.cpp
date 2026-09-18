// function.cpp —— Boost.Function：可调用物的"万能容器"
// 对应文档：docs/04-function.md
#include <boost/function.hpp>
#include <functional>
#include <iostream>

int add(int a, int b) { return a + b; }

struct Mul {
    int factor;
    int operator()(int x) const { return x * factor; }
};

int main() {
    // 同一个 boost::function 能装三种可调用物：函数指针、仿函数、lambda
    boost::function<int(int, int)> op = add;
    std::cout << "函数指针: " << op(3, 4) << '\n';

    op = [](int a, int b) { return a - b; };
    std::cout << "lambda:   " << op(3, 4) << '\n';

    boost::function<int(int)> m = Mul{10};
    std::cout << "仿函数:   " << m(5) << '\n';

    // 空状态检测：std::function 的 bad_function_call 前哨
    boost::function<int(int, int)> empty;
    std::cout << "empty 可调用? " << std::boolalpha << static_cast<bool>(empty) << '\n';
    try {
        empty(1, 2);                     // 调空的会抛 bad_function_call
    } catch (const boost::bad_function_call&) {
        std::cout << "捕获 boost::bad_function_call\n";
    }

    // 与 std::function 互装：两者类型不同但可互相赋值（都是值语义包装）
    std::function<int(int, int)> stdop = [](int a, int b) { return a * b; };
    boost::function<int(int, int)> fromstd = stdop;
    std::cout << "std→boost: " << fromstd(3, 4) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
