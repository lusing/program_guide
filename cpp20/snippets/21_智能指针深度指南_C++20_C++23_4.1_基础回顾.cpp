#include <memory>
#include <iostream>

// 创建 unique_ptr
std::unique_ptr<int> p1 = std::make_unique<int>(42);

// 转移所有权
std::unique_ptr<int> p2 = std::move(p1);  // p1 变为空

// 自定义删除器
auto custom_deleter = [](int* p) {
    std::cout << "Deleting: " << *p << "\n";
    delete p;
};
std::unique_ptr<int, decltype(custom_deleter)> p3(new int(10), custom_deleter);

// 数组版本
std::unique_ptr<int[]> arr = std::make_unique<int[]>(5);
arr[0] = 1;
