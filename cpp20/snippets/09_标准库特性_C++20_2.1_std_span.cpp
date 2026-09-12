#include <span>

void process(std::span<int> data) {
    for (int x : data) {
        std::cout << x << " ";
    }
}

int arr[] = {1, 2, 3, 4, 5};
process(arr);                    // 传递数组
process(std::span{arr});         // 显式创建 span

std::vector v = {1, 2, 3};
process(v);                      // 传递 vector
process(v.subspan(0, 3));       // 传递子范围
