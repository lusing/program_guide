#include <memory>

void const_example(const std::shared_ptr<int> p) {
    auto count = p.use_count();  // C++20 前需要非const，C++20起可以是const
}
