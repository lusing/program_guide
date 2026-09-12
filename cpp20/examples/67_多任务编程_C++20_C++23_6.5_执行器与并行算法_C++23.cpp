#include <execution>
#include <vector>
#include <algorithm>
#include <numeric>
#include <iostream>

int main() {
    std::vector<int> v(1000);
    std::iota(v.begin(), v.end(), 0);

    // 并行执行（execution policy 与 std::sort 搭配）
    std::sort(std::execution::par, v.begin(), v.end(), std::greater<int>{});
    std::cout << "max=" << v.front() << ", min=" << v.back() << "\n";
}
