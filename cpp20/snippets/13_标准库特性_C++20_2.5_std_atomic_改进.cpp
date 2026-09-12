#include <atomic>

std::atomic<int> counter{0};

// C++20 新增方法
counter.fetch_add(1, std::memory_order_relaxed);
counter.store(10, std::memory_order_release);

// 支持任意类型
std::atomic<MyStruct> atomic_struct{};
