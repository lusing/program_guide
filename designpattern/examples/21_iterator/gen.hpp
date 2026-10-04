#pragma once
// 迭代器的现代形态：协程生成器——"遍历"从"管理游标"变成"yield 一个值"。
// Task 1 探针已确认 MSVC/clang 双通道支持 <generator>（C++23）。
#include <generator>

namespace dp {

// 斐波那契前 n 项：协程体即遍历逻辑，co_yield 处暂停。
inline std::generator<int> fib_gen(int n) {
    int a = 0, b = 1;
    for (int i = 0; i < n; ++i) {
        co_yield a;
        int next = a + b;
        a = b;
        b = next;
    }
}

}  // namespace dp
