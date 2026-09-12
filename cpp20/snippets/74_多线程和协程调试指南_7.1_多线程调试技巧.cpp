#include <thread>
#include <iostream>
#include <atomic>

// 存在数据竞争的代码
int global_counter = 0;

void buggy_increment() {
    std::vector<std::thread> threads;
    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([] {
            for (int j = 0; j < 1000; ++j) {
                global_counter++;  // 数据竞争！
            }
        });
    }
    for (auto& t : threads) t.join();
}

// 正确的实现
std::atomic<int> atomic_counter{0};

void correct_increment() {
    std::vector<std::thread> threads;
    for (int i = 0; i < 10; ++i) {
        threads.emplace_back([] {
            for (int j = 0; j < 1000; ++j) {
                atomic_counter.fetch_add(1, std::memory_order_relaxed);
            }
        });
    }
    for (auto& t : threads) t.join();
}
