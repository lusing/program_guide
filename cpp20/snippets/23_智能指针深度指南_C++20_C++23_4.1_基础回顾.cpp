#include <memory>
#include <iostream>

std::weak_ptr<int> global_weak;

void test_weak() {
    auto p = std::make_shared<int>(42);
    global_weak = p;  // 不增加引用计数

    {
        auto lock = global_weak.lock();  // 尝试获取 shared_ptr
        if (lock) {
            std::cout << "Value: " << *lock << "\n";
        }
    }

    // p 析构后，weak_ptr 变为过期
    if (global_weak.expired()) {
        std::cout << "Pointer has expired\n";
    }
}
