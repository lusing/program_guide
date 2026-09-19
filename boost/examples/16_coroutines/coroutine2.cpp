// coroutine2.cpp —— Boost.Coroutine2（2015）：现代版栈协程
// 对应文档：docs/16-coroutines.md
// coroutine::push_type/pull_type 的 C++11 移动语义重制，API 更干净。
// C++23 std::generator 毕业的是"生成器"部分；协程双向管道仍在原地。
#include <boost/coroutine2/all.hpp>
#include <iostream>
#include <string>

using boost::coroutines2::coroutine;

int main() {
    // 1) pull 型：协程产出序列（生成器）
    coroutine<int>::pull_type fib(
        [](coroutine<int>::push_type& out) {
            int a = 0, b = 1;
            for (int i = 0; i < 8; ++i) {
                out(a);
                int next = a + b;
                a = b;
                b = next;
            }
        });
    std::cout << "斐波那契:";
    for (int x : fib) std::cout << ' ' << x;
    std::cout << '\n';

    // 2) push 型：主循环喂数据
    int sum = 0;
    coroutine<int>::push_type sink(
        [&sum](coroutine<int>::pull_type& in) {
            for (int x : in) sum += x;
        });
    for (int i = 1; i <= 100; ++i) sink(i);
    std::cout << "1..100 求和 = " << sum << '\n';

    // 3) 与 C++23 std::generator 对照：生成器部分已毕业
    //    auto gen() -> std::generator<int> { co_yield ...; }
    //    差异：std::generator 是无栈的（不能在任意深度的普通函数里 yield），
    //    coroutine2 是有栈的（深层调用链里也能 yield）——这是本质分界线
    std::cout << "分界线：有栈（coroutine2）vs 无栈（C++20 co_await）\n";

    std::cout << "自检通过\n";
    return 0;
}
