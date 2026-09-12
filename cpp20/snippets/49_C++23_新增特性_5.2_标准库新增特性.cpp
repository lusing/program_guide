#include <generator>

std::generator<int> fibonacci() {
    int a = 0, b = 1;
    while (true) {
        co_yield a;
        int temp = a;
        a = b;
        b = temp + b;
    }
}

// 使用生成器
for (int n : fibonacci() | std::views::take(10)) {
    std::cout << n << " ";  // 0 1 1 2 3 5 8 13 21 34
}
