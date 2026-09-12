#include <thread>
#include <latch>
#include <vector>
#include <iostream>

int main() {
    std::latch latch(5);
    std::vector<std::thread> threads;

    for (int i = 0; i < 5; ++i) {
        threads.emplace_back([&latch, i] {
            std::cout << "Thread " << i << " ready\n";
            latch.count_down();  // 计数减1
        });
    }

    latch.wait();  // 等待计数归零
    std::cout << "All threads ready! Proceeding...\n";

    for (auto& t : threads) {
        t.join();
    }
}
