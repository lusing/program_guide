#include <memory>
#include <iostream>

void debug_shared_ptr() {
    auto p1 = std::make_shared<int>(42);
    std::cout << "Initial use_count: " << p1.use_count() << "\n";

    auto p2 = p1;
    std::cout << "After copy: " << p1.use_count() << "\n";

    p2.reset();
    std::cout << "After reset: " << p1.use_count() << "\n";
}
