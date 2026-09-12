#include <memory>

// std::make_shared_for_overwrite
auto p1 = std::make_shared_for_overwrite<int[]>(10);

// std::atomic_shared_ptr
std::atomic_shared_ptr<int> atomic_ptr;

// std::shared_ptr::unique() 已废弃，使用 use_count() == 1
