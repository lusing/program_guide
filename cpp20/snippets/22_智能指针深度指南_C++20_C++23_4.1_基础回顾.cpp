#include <memory>
#include <iostream>

// 创建 shared_ptr
std::shared_ptr<int> p1 = std::make_shared<int>(42);

// 共享所有权
std::shared_ptr<int> p2 = p1;  // 引用计数+1
std::shared_ptr<int> p3 = p1;  // 引用计数+1

std::cout << "Use count: " << p1.use_count() << "\n";  // 3

// 重置
p2.reset();  // 引用计数-1
std::cout << "Use count: " << p1.use_count() << "\n";  // 2
