#include <memory>
#include <memory_resource>

// 使用自定义分配器
std::pmr::polymorphic_allocator<int> alloc{};

auto p = std::allocate_shared_for_overwrite<int,
    std::pmr::polymorphic_allocator<int>>(alloc, 100);
