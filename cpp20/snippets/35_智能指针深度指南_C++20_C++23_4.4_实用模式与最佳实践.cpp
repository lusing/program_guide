#include <memory>
#include <memory_resource>

// 使用 pool_resources 减少内存碎片
std::pmr::pool_resource pool;

auto p1 = std::allocate_shared<int, std::pmr::polymorphic_allocator<int>>(
    pool, 42);

auto p2 = std::allocate_shared<int, std::pmr::polymorphic_allocator<int>>(
    pool, 84);

// 一次性释放所有分配的内存
pool.release();
