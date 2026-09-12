#include <thread>
#include <barrier>
#include <iostream>

int main() {
    std::barrier barrier(5);
    std::vector<std::thread> threads;

    for (int i = 0; i < 5; ++i) {
        threads.emplace_back([&barrier, i] {
            // 阶段1
            std::cout << "Phase 1 - Thread " << i << "\n";
            barrier.arrive_and_wait();

            // 阶段2
            std::cout << "Phase 2 - Thread " << i << "\n";
            barrier.arrive_and_wait();

            // 阶段3
            std::cout << "Phase 3 - Thread " << i << "\n";
        });
    }

    for (auto& t : threads) {
        t.join();
    }
}
