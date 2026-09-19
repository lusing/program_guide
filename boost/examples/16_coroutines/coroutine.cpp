// coroutine.cpp —— Boost.Coroutine（2012，旧版）：栈对称协作的元老
// 对应文档：docs/16-coroutines.md
// 注意：这是旧接口（coroutine<T>），新代码看 coroutine2；本例讲清
// "对称/非对称"与 push/pull 双向管道两个核心概念。
#include <boost/coroutine/all.hpp>
#include <iostream>

int main() {
    using co_t = boost::coroutines::coroutine<int(int)>;

    // 1) 经典生产者：pull 型（协程推出来，主循环拉）
    boost::coroutines::coroutine<int>::pull_type source(
        [](boost::coroutines::coroutine<int>::push_type& sink) {
            for (int i = 1; i <= 5; ++i) sink(i * i);
        });
    std::cout << "平方序列:";
    for (int x : source) std::cout << ' ' << x;
    std::cout << '\n';

    // 2) 经典消费者：push 型（主循环推进去）
    boost::coroutines::coroutine<std::string>::push_type writer(
        [](boost::coroutines::coroutine<std::string>::pull_type& in) {
            while (in) {
                std::cout << "  收到: " << in.get() << '\n';
                in();
            }
        });
    writer("hello");
    writer("coroutine");
    writer("world");

    std::cout << "自检通过\n";
    return 0;
}
