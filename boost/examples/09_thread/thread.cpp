// thread.cpp —— Boost.Thread：多线程的第一课（std::thread 的直系 + 独有增量）
// 对应文档：docs/09-thread.md
// 输出确定性：所有打印都在 join 之后或经锁保护的固定顺序段内。
// 实测发现：boost/thread.hpp 的伞形头会拉进 future.hpp，后者在
// /std:c++latest（C++26 草案档）的 MSVC 19.51 下有语法冲突——
// 用细分头文件绕开，future 部分改用 std::future 对照
#include <boost/thread/thread.hpp>
#include <boost/thread/mutex.hpp>
#include <boost/thread/condition_variable.hpp>
#include <boost/chrono.hpp>
#include <chrono>
#include <future>
#include <iostream>
#include <mutex>
#include <string>
#include <thread>

std::mutex g_io_mutex;

int main() {
    // 1) 基本面：launch + join（与 std::thread 同构）
    boost::thread worker([] {
        boost::lock_guard<std::mutex> lk(g_io_mutex);
        std::cout << "  工作线程跑在另一个核上\n";
    });
    worker.join();

    // 2) 带参数/带返回（thread + future；boost::future 在本机 c++latest 下
    //    编不过，用 std 同构接口演示——两者 API 同源于一个提案）
    int input = 7;
    std::packaged_task<int()> task([input] { return input * input; });
    std::future<int> fut = task.get_future();
    std::thread runner(std::move(task));
    std::cout << "  7 的平方 = " << fut.get() << '\n';
    runner.join();

    // 3) interruption_point：Boost.Thread 的独门绝技（std 线程不能从外部取消！）
    boost::thread sleeper([] {
        try {
            for (int i = 0; i < 100; ++i) {
                boost::this_thread::sleep_for(boost::chrono::milliseconds(100));
                boost::this_thread::interruption_point();   // 收到中断就抛 thread_interrupted
            }
        } catch (const boost::thread_interrupted&) {
            boost::lock_guard<std::mutex> lk(g_io_mutex);
            std::cout << "  长任务被外部中断（std::thread 做不到）\n";
        }
    });
    boost::this_thread::sleep_for(boost::chrono::milliseconds(80));
    sleeper.interrupt();
    sleeper.join();

    // 4) 同步原语全家福：mutex/condition_variable
    boost::condition_variable cv;
    boost::mutex m;
    bool ready = false;
    boost::thread waiter([&] {
        boost::unique_lock<boost::mutex> lk(m);
        cv.wait(lk, [&] { return ready; });
        std::cout << "  条件满足， waiter 继续\n";
    });
    {
        boost::lock_guard<boost::mutex> lk(m);
        ready = true;
    }
    cv.notify_one();
    waiter.join();

    // 5) C++20 对照：jthread 自动 join + stop_token 协作取消
    //    （中断的标准化答案，语义上就是 boost 的 interruption 机制）
    {
        std::jthread jt([](std::stop_token st) {
            int waited = 0;
            while (!st.stop_requested()) {
                std::this_thread::sleep_for(std::chrono::milliseconds(10));
                if (++waited > 200) break;
            }
            std::lock_guard<std::mutex> lk(g_io_mutex);
            std::cout << "  jthread 收到 stop_request，自行退出\n";
        });
        std::this_thread::sleep_for(std::chrono::milliseconds(50));
        jt.request_stop();
    }   // 析构自动 join——忘 join 的经典 bug 被 RAII 消灭

    std::cout << "自检通过\n";
    return 0;
}
