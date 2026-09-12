#include <memory>
#include <atomic>
#include <thread>
#include <iostream>

std::atomic<std::shared_ptr<int>> atomic_ptr;

void producer() {
    auto ptr = std::make_shared<int>(42);
    atomic_ptr.store(ptr, std::memory_order_release);
}

void consumer() {
    std::shared_ptr<int> ptr;
    atomic_ptr.load(ptr, std::memory_order_acquire);
    if (ptr) {
        std::cout << "Value: " << *ptr << "\n";
    }
}
