#include <generator>
#include <coroutine>
#include <iostream>

std::generator<int> async_read() {
    co_yield 1;
    co_yield 2;
    co_yield 3;
}

int main() {
    for (int val : async_read()) {
        std::cout << "Read: " << val << "\n";
    }
}

