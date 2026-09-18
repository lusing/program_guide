// atomic.cpp —— Boost.Atomic：无锁编程的入口（std::atomic 直系 + 独有增量）
// 对应文档：docs/10-atomic.md
#include <boost/atomic.hpp>
#include <atomic>
#include <iostream>
#include <thread>
#include <vector>

// boost::atomic_flags 用无锁自旋保护的非原子计数器演示
boost::atomic<int> counter{0};
boost::atomic<bool> ready{false};

int main() {
    // 1) 基本面：fetch_add 是 RMW（读-改-写）原子操作的代表
    boost::atomic<int> a{10};
    int prev = a.fetch_add(5);
    std::cout << "fetch_add 前值 = " << prev << " 现值 = " << a.load() << '\n';

    // CAS：compare_exchange 弱/强循环（无锁数据结构的基石）
    int expected = 15;
    bool ok = a.compare_exchange_strong(expected, 20);
    std::cout << "CAS(15→20) 成功? " << std::boolalpha << ok << " 现值 = " << a.load() << '\n';

    // 2) 内存序：从松到严
    //    relaxed 只保原子性；acquire/release 建立同步；seq_cst 全局一致（默认）
    a.store(100, boost::memory_order_relaxed);
    std::cout << "relaxed 读回 = " << a.load(boost::memory_order_relaxed) << '\n';

    // 3) 发布/订阅模式：release store + acquire load 的最小同步对
    int payload = 0;
    std::thread producer([&] {
        payload = 42;                                       // 普通写
        ready.store(true, boost::memory_order_release);     // 发布
    });
    std::thread consumer([&] {
        while (!ready.load(boost::memory_order_acquire)) { // 订阅
            std::this_thread::yield();
        }
        // 走到这里 payload == 42 有保证（happens-before 由内存序建立）
        std::cout << "消费者看到 payload = " << payload << "（acquire/release 保证）\n";
    });
    producer.join();
    consumer.join();

    // 4) 多线程计数：4 线程各加 10000，结果必须是 40000（原子的意义）
    std::vector<std::thread> ts;
    for (int t = 0; t < 4; ++t) {
        ts.emplace_back([] {
            for (int i = 0; i < 10000; ++i) counter.fetch_add(1, boost::memory_order_relaxed);
        });
    }
    for (auto& t : ts) t.join();
    std::cout << "4 线程 ×10000 计数 = " << counter.load() << "（一个不丢）\n";

    // 5) boost 独有：is_lock_free 探测 + atomic_ref（C++20 std 也有了的回声）
    boost::atomic<double> d{3.14};
    std::cout << "double 原子 lock-free? " << d.is_lock_free() << '\n';
    std::atomic<int> sa{1};
    std::cout << "std 版同构: " << (sa.fetch_add(1), sa.load()) << '\n';

    // 6) boost::atomic_ref：把**已有**变量临时按原子访问（C++20 std::atomic_ref 对应）
    int plain = 0;
    boost::atomic_ref<int> ar(plain);
    ar.fetch_add(7);
    std::cout << "atomic_ref 作用后普通变量 = " << plain << '\n';

    std::cout << "自检通过\n";
    return 0;
}
