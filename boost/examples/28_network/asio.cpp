// asio.cpp —— Boost.Asio（2005）：C++ 异步 IO 的事实标准。
// Chris Kohlhoff 二十年的作品；C++26 std::execution 的精神源头。
// 对应文档：docs/28-network.md
#include <boost/asio.hpp>
#include <chrono>
#include <iostream>
#include <thread>

namespace asio = boost::asio;

int main() {
    asio::io_context io;

    // 1) 同步定时器：最简单的异步原语
    asio::steady_timer t(io, std::chrono::milliseconds(20));
    t.wait();                             // 同步等
    std::cout << "同步定时器到点\n";

    // 2) 异步回调 + run()：事件循环的骨架
    int fired = 0;
    asio::steady_timer t2(io, std::chrono::milliseconds(10));
    t2.async_wait([&fired](const boost::system::error_code& ec) {
        if (!ec) ++fired;
    });
    io.run();                             // 阻塞直到没有待处理工作
    std::cout << "异步回调触发? " << (fired == 1) << '\n';

    // 3) 多线程事件循环：io_context 是线程安全的调度中心
    asio::io_context io2;
    asio::steady_timer t3(io2, std::chrono::milliseconds(10));
    std::atomic<int> count{0};
    t3.async_wait([&](const boost::system::error_code&) { ++count; });
    std::thread runner([&] { io2.run(); });
    runner.join();
    std::cout << "跨线程事件循环? " << (count == 1) << '\n';

    // 4) 工作守卫：防止 run() 在没有任务时立刻返回
    asio::io_context io3;
    auto guard = asio::make_work_guard(io3);
    std::thread bg([&] { io3.run(); });   // 有 guard，run 不退出
    asio::post(io3, [] { std::cout << "post 的任务被执行\n"; });
    std::this_thread::sleep_for(std::chrono::milliseconds(50));
    guard.reset();                        // 放行
    bg.join();

    // 5) C++26 展望：std::execution（P2300）是这套执行模型的标准化，
    //    作者同源；在那之前 asio 就是答案
    std::cout << "自检通过\n";
    return 0;
}
