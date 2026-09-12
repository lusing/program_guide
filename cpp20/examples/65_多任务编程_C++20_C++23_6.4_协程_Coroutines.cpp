#include <generator>
#include <iostream>

std::generator<int> range(int start, int end) {
    for (int i = start; i < end; ++i) {
        co_yield i;
    }
}

int main() {
    for (int n : range(0, 10)) {
        std::cout << n << " ";
    }
    // 输出: 0 1 2 3 4 5 6 7 8 9
}

