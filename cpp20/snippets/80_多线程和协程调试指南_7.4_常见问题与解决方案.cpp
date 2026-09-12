#include <thread>
#include <mutex>
#include <iostream>
#include <vector>

// 检测工具辅助代码
#ifdef DEBUG_RACE
    #define TRACE(msg) \
        std::lock_guard<std::mutex> lock(trace_mutex); \
        std::cout << "[" << std::this_thread::get_id() << "] " << msg << "\n"
    std::mutex trace_mutex;
#else
    #define TRACE(msg)
#endif

void safe_counter() {
    std::atomic<int> counter{0};
    std::vector<std::thread> threads;

    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([&] {
            for (int j = 0; j < 1000; ++j) {
                TRACE("Incrementing");
                counter.fetch_add(1, std::memory_order_relaxed);
            }
        });
    }

    for (auto& t : threads) t.join();
    std::cout << "Final counter: " << counter << "\n";
}
