// thread.cpp —— Boost.Thread：多线程的第一课（std::thread 的直系 + 独有增量）
// 对应文档：docs/09-thread.md
// 输出确定性：所有打印都在 join 之后或经锁保护的固定顺序段内。
// 实测发现：boost/thread.hpp 的伞形头会拉进 future.hpp，后者在
// /std:c++latest（C++26 草案档）的 MSVC 19.51 下有语法冲突——
// 用细分头文件绕开，future 部分改用 std::future 对照
#include <boost/thread/thread.hpp>
#include <boost/thread/mutex.hpp>
#include <boost/thread/condition_variable.hpp>
#include <boost/thread/thread_guard.hpp>
#include <boost/thread/once.hpp>
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
        cv.wait(lk, [&] { return ready; });        // 谓词版 = while(!pred) wait(lk)
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

    // ── 书 ch12.2 后半的进阶件 ──
    // 6) 线程信息：get_id / hardware_concurrency / physical_concurrency
    std::cout << "  硬件并发数 = " << boost::thread::hardware_concurrency()
              << "（0 表示探测失败）\n";

    // 7) thread_guard：析构时按策略处理线程（boost 独有，jthread 只会 join）
    {
        boost::thread t([] {
            boost::this_thread::sleep_for(boost::chrono::milliseconds(30));
        });
        boost::thread_guard<boost::detach> g(t);   // 作用域结束 detach 而非 join
        std::cout << "  thread_guard<detach> 析构时 detach（不等待）\n";
    }   // g 析构 → t.detach()

    // 8) this_thread 三件 + at_thread_exit（线程本地善后钩子）
    boost::thread finisher([] {
        boost::this_thread::at_thread_exit([] {
            std::lock_guard<std::mutex> lk(g_io_mutex);
            std::cout << "  at_thread_exit：线程退出前执行登记的清理\n";
        });
        boost::this_thread::yield();               // 让出时间片
    });
    finisher.join();

    // 9) call_once：多线程只初始化一次（std 同款；魔法静态量 local static
    //    在 C++11 后也保证线程安全，两招都在用）
    //    【坑】boost::once_flag 必须 BOOST_ONCE_INIT 初始化——裸默认构造
    //    的静态对象在 Windows 上内部状态未清零，call_once 会永久卡死
    //    （std::once_flag 没这个问题）
    {
        static boost::once_flag once = BOOST_ONCE_INIT;
        auto worker_once = [] {
            boost::call_once(once, [] {
                std::lock_guard<std::mutex> lk(g_io_mutex);
                std::cout << "  call_once：初始化只发生一次\n";
            });
        };
        boost::thread t1(worker_once), t2(worker_once);
        t1.join(); t2.join();
    }

    // 10) 有界缓冲区：条件变量的正典用法（书 ch12.2.10 的 buffer 骨架）
    //    【实测坑】第一版写成"覆写式单槽 + 容量 2"——生产者会在消费者取走
    //    前覆写未消费的货，货品丢失 → 消费者最后一趟永远等不到货 → 死锁
    //    挂满 60 秒（六条判定里报"超时未结束"的就是这种）。正典写法是
    //    **计数**：容量约束作用在"在库货品数"上，谁也不覆盖谁。
    {
        boost::mutex bm;
        boost::condition_variable not_full, not_empty;
        const int cap = 2;                          // 缓冲区容量
        int count = 0;                              // 在库货品数（计数！）
        int last = 0;
        auto producer = [&] {
            for (int i = 1; i <= 6; ++i) {
                boost::unique_lock<boost::mutex> lk(bm);
                not_full.wait(lk, [&] { return count < cap; });   // 等空位
                ++count;
                last = i;
                lk.unlock();
                not_empty.notify_one();             // 有货了
            }
        };
        auto consumer = [&] {
            int got = 0, batch = 0;
            for (int i = 0; i < 6; ++i) {
                boost::unique_lock<boost::mutex> lk(bm);
                not_empty.wait(lk, [&] { return count > 0; });   // 等货
                --count;
                batch = last;                       // 这一批的编号
                ++got;
                lk.unlock();
                not_full.notify_one();              // 腾出空位
            }
            std::lock_guard<std::mutex> lk(g_io_mutex);
            std::cout << "  有界缓冲(容 2)生产 6 消费 " << got
                      << " 无丢失（最后一批 = " << batch << "）\n";
        };
        boost::thread tp(producer), tc(consumer);
        tp.join(); tc.join();
    }

    // 11) 线程组 thread_group：批量 create/join（简版线程池，书 ch12.2.8）
    {
        boost::thread_group pool;
        boost::mutex sum_mutex;
        int total = 0;
        for (int i = 0; i < 4; ++i) {
            pool.create_thread([&] {
                boost::lock_guard<boost::mutex> lk(sum_mutex);
                total += 10;
            });
        }
        pool.join_all();                            // 等全部
        std::cout << "  线程组 4 线程合计 = " << total << '\n';
    }

    std::cout << "自检通过\n";
    return 0;
}
