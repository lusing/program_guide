// heap.cpp —— Boost.Heap（2011）：优先队列的可选型超市。
// std::priority_queue 是二叉堆且不可迭代不可合并——这里四个变体各有绝活。
// 对应文档：docs/22-container-zoo.md
// C4702：binomial_heap.hpp 在新 MSVC 下有不可达代码（库自身问题）
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(push)
#pragma warning(disable : 4702)
#endif
#include <boost/heap/priority_queue.hpp>
#include <boost/heap/d_ary_heap.hpp>
#include <boost/heap/binomial_heap.hpp>
#include <boost/heap/fibonacci_heap.hpp>
#if defined(_MSC_VER)   // MSVC 专用：clang/GCC 认不出会报 -Wunknown-pragmas
#pragma warning(pop)
#endif
#include <iostream>

int main() {
    // 1) priority_queue：std 同款二叉堆（但可迭代！）
    boost::heap::priority_queue<int> pq;
    for (int x : {5, 1, 9, 3, 7}) pq.push(x);
    std::cout << "二叉堆顶 = " << pq.top() << " 可迭代（std 版不行）:";
    for (int x : pq) std::cout << ' ' << x;
    std::cout << '\n';

    // 2) d-ary 堆：d=4 缓存更友好（图算法 Dijkstra 的常用配置）
    boost::heap::d_ary_heap<int, boost::heap::arity<4>> d4;
    for (int x : {5, 1, 9, 3, 7}) d4.push(x);
    std::cout << "4 叉堆顶 = " << d4.top() << '\n';

    // 3) 二项堆：O(log) 合并（merge）——多队列归并场景
    boost::heap::binomial_heap<int> bh1, bh2;
    bh1.push(10); bh1.push(30);
    bh2.push(20); bh2.push(40);
    bh1.merge(bh2);                       // 把 bh2 整个并进来（bh2 清空）
    std::cout << "合并后堆顶 = " << bh1.top() << " 大小 = " << bh1.size() << '\n';

    // 4) 斐波那契堆：句柄式调整 O(1) 摊还——Dijkstra 理论最优配置。
    //    注意：boost::heap 全家默认最大堆——increase 才是"向堆顶调整"
    boost::heap::fibonacci_heap<int> fh;
    auto h1 = fh.push(50);
    fh.push(60);
    fh.push(70);
    std::cout << "fib 堆初始顶 = " << fh.top() << "（最大堆）\n";
    fh.increase(h1, 80);                  // 50 → 80，摊还 O(1)，直接跳顶
    std::cout << "increase(50→80) 后顶 = " << fh.top() << '\n';
    fh.decrease(h1, 40);                  // 80 → 40，同样 O(1) 级
    std::cout << "decrease(80→40) 后顶 = " << fh.top() << '\n';

    std::cout << "自检通过\n";
    return 0;
}
