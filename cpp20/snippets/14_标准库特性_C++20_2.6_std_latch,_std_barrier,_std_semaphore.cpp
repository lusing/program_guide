#include <latch>
#include <barrier>
#include <semaphore>

// Latch: 一次性的计数器
std::latch latch(5);
std::vector<std::thread> threads;

for (int i = 0; i < 5; ++i) {
    threads.emplace_back([&latch, i] {
        std::cout << "Thread " << i << " ready\n";
        latch.count_down();
    });
}

latch.wait();
std::cout << "All threads ready!\n";

// Barrier: 可重用的屏障
std::barrier barrier(5);
for (int i = 0; i < 5; ++i) {
    threads.emplace_back([&barrier, i] {
        std::cout << "Phase 1 - Thread " << i << "\n";
        barrier.arrive_and_wait();
        std::cout << "Phase 2 - Thread " << i << "\n";
    });
}
