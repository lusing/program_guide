#include <memory>
#include <new>

// C++23: 使用 start_lifetime_as 显式开始对象生命周期
void* storage = ::operator new(sizeof(int) * 10);

// 使用 start_lifetime_as（如果编译器支持）
// int* ptr = std::start_lifetime_as<int>(storage);

// 传统方式：placement new
int* ptr = static_cast<int*>(storage);
for (int i = 0; i < 10; ++i) {
    new(ptr + i) int(i);
}

// 手动析构
for (int i = 0; i < 10; ++i) {
    (ptr + i)->~int();
}

// 释放内存
::operator delete(storage);
