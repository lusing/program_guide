#include <memory>

// 传统方式：初始化为0
auto p1 = std::make_shared<std::vector<int>>(1000);  // 初始化1000个0

// C++20 方式：不初始化，提高性能
auto p2 = std::make_shared_for_overwrite<std::vector<int>>(1000);
p2->at(0) = 42;  // 手动赋值

// 对于数组
auto arr = std::make_shared_for_overwrite<int[]>(1000);
arr[0] = 1;
