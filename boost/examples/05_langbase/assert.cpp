// assert.cpp —— Boost.Assert：三档断言宏（库作者写给使用者的防线）
// 对应文档：docs/05-langbase.md
#include <boost/assert.hpp>
#include <iostream>

int checked_div(int a, int b) {
    // BOOST_ASSERT：NDEBUG 未定义时断言，定义了就整个消失（零开销）
    BOOST_ASSERT(b != 0);
    return a / b;
}

int logged_div(int a, int b) {
    // BOOST_ASSERT_MSG：带消息版本（报错时多一句人话）
    BOOST_ASSERT_MSG(b != 0, "除数为 0：上游数据管道坏了");
    return a / b;
}

int tolerant_div(int a, int b) {
    // BOOST_VERIFY：Release 也要执行表达式（用它的副作用），只断言其真值
    // 典型用途：检查返回值又被优化掉的 C API 调用
    BOOST_VERIFY(b != 0);
    return b == 0 ? 0 : a / b;
}

int main() {
    std::cout << checked_div(10, 2) << '\n';
    std::cout << logged_div(9, 3) << '\n';
    std::cout << tolerant_div(8, 4) << '\n';

    // 自定义处理器：断言失败时走你的函数（接日志/崩溃报告系统）
    // （默认行为是 assert()；教程以正常路径运行为主，不主动触发失败）
    std::cout << "断言三档：ASSERT(消失)/ASSERT_MSG(带话)/VERIFY(保留副作用)\n";

    std::cout << "自检通过\n";
    return 0;
}
