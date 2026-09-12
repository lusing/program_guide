#include <memory>
#include <atomic>
#include <thread>

std::atomic<std::shared_ptr<int>> atomic_ptr;

void producer() {
    auto new_ptr = std::make_shared<int>(42);
    // 原子地替换指针
    auto old_ptr = atomic_ptr.exchange(new_ptr);
}

void consumer() {
    // 原子地加载指针
    auto ptr = atomic_ptr.load(std::memory_order_acquire);
    if (ptr) {
        std::cout << "Value: " << *ptr << "\n";
    }
}
