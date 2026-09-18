// compat.cpp —— Boost.Compat：反向毕业，把新 std 特性带回老标准
// 对应文档：docs/04-function.md
// 别的库是"从 Boost 毕业进 std"，这个库反着走：把 std 的新组件
// 回移植到 C++11，让老代码库也能用上现代接口。
#include <boost/compat/function_ref.hpp>
#include <boost/compat/bind_front.hpp>
#include <boost/compat/move_only_function.hpp>
#include <iostream>
#include <memory>

int add(int a, int b) { return a + b; }

// function_ref：C++26 std::function_ref 的预演——
// 不拥有可调用物的"视图"。比 std::function 轻一个数量级（无分配）
int apply(boost::compat::function_ref<int(int, int)> f, int a, int b) {
    return f(a, b);
}

int main() {
    // 1) function_ref 接住任何可调用物，零所有权、零分配
    std::cout << "function_ref+函数指针: " << apply(add, 3, 4) << '\n';
    std::cout << "function_ref+lambda:   " << apply([](int a, int b) { return a * b; }, 3, 4) << '\n';

    // 2) bind_front：C++20 std::bind_front 的回移植
    auto add7 = boost::compat::bind_front(add, 7);
    std::cout << "bind_front(add, 7)(8) = " << add7(8) << '\n';

    // 3) move_only_function：C++23 std::move_only_function 的回移植——
    //    能装 move-only 的可调用物（std::function 装不了的 unique_ptr 捕获）
    boost::compat::move_only_function<int()> task =
        [p = std::make_unique<int>(55)] { return *p; };
    std::cout << "move_only_function 持 unique_ptr: " << task() << '\n';
    // auto stolen = task;   // 编译错误：move_only_function 只能移动
    auto moved = std::move(task);   // 移动后原对象为空
    std::cout << "移动后调用: " << (moved ? moved() : -1) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
