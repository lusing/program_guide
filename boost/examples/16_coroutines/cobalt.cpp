// cobalt.cpp —— Boost.Cobalt（2022）：C++20 co_await 时代的 asio 高层糖衣
// 对应文档：docs/16-coroutines.md
// 作者（Klemens Morgenstern）把"回调/完成令牌"式的 asio 包成了
// 直写的协程函数。需要链接 asio（ws2_32 已在章节配置里）。
#include <boost/cobalt.hpp>
#include <boost/asio.hpp>
#include <chrono>
#include <iostream>

// cobalt::task<T>：协程任务；co_await 直接等异步操作完成
boost::cobalt::task<int> add_later(int a, int b) {
    co_await boost::asio::steady_timer(
        co_await boost::cobalt::this_coro::executor,
        std::chrono::milliseconds(30)).async_wait(boost::cobalt::use_op);
    co_return a + b;
}

boost::cobalt::task<void> main_task() {
    int r = co_await add_later(20, 22);
    std::cout << "co_await 加法 = " << r << '\n';

    // 并发跑两个任务：join 等全部完成（variadic 版返回 tuple）
    auto [r1, r2] = co_await boost::cobalt::join(add_later(1, 2), add_later(3, 4));
    std::cout << "并发: " << r1 << " & " << r2 << '\n';
}

int main() {
    boost::cobalt::run(main_task());     // 起调度器跑完顶协程
    std::cout << "自检通过\n";
    return 0;
}
