#include <memory>
#include <algorithm>

// C++14/17: 需要自定义删除器
std::unique_ptr<int[], void(*)(int*)> arr(
    new int[100],
    [](int* p) { delete[] p; }
);

// C++20: 更简单的方式
auto arr2 = std::make_unique<int[]>(100);
std::fill_n(arr2.get(), 100, 0);

// RAII 封装
template<typename T>
class ManagedArray {
    std::unique_ptr<T[]> data;
    size_t size_;
public:
    ManagedArray(size_t n) : data(std::make_unique<T[]>(n)), size_(n) {}
    T& operator[](size_t i) { return data[i]; }
    const T& operator[](size_t i) const { return data[i]; }
    size_t size() const { return size_; }
};
