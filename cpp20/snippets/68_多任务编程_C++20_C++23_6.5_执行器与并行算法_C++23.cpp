#include <execution>
#include <vector>
#include <algorithm>
#include <iostream>

void parallel_sum() {
    std::vector<int> v(10000);
    std::iota(v.begin(), v.end(), 1);

    // 并行计算和
    int sum = 0;
    std::for_each(std::execution::par,
                  v.begin(), v.end(),
                  [&sum](int n) { sum += n; });

    std::cout << "Sum: " << sum << "\n";
}
