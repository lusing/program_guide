#include <memory>
#include <iostream>

void test_shared() {
    auto p1 = std::make_shared<int>(42);
    auto p2 = p1;  // 共享所有权

    std::cout << "p1 use_count: " << p1.use_count() << "\n";  // 2

    p2.reset();
    std::cout << "After p2.reset(), p1 use_count: "
              << p1.use_count() << "\n";  // 1
}
