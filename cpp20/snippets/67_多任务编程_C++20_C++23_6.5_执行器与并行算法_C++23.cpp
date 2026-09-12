#include <execution>
#include <vector>
#include <algorithm>
#include <iostream>

int main() {
    std::vector<int> v(1000);
    std::iota(v.begin(), v.end(), 0);

    // 并行执行
    std::ranges::sort(v, std::less{},
        std::execution::par,  // 并行执行
        [] (int a) { return a; });
}
