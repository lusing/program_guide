// 推荐：make_unique 更安全（单次内存分配）
auto p1 = std::make_unique<std::string>("Hello");

// 不推荐：可能抛出异常导致内存泄漏
auto p2 = std::unique_ptr<std::string>(new std::string("Hello"));

// C++20: make_shared_for_overwrite 提高性能
auto p3 = std::make_shared_for_overwrite<std::vector<int>>(10000);
// 避免初始化为0，直接使用
