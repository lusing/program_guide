// circular_buffer.cpp —— Boost.CircularBuffer（1999→2016 重制）：
// 定容环形缓冲——最新 N 条日志/滑动窗口/生产消费队列的骨架。
// 对应文档：docs/21-container-core.md
#include <boost/circular_buffer.hpp>
#include <iostream>

int main() {
    // 1) 定容 3：满后新元素顶掉最老的
    boost::circular_buffer<int> cb(3);
    cb.push_back(1);
    cb.push_back(2);
    cb.push_back(3);
    cb.push_back(4);       // 顶掉 1
    cb.push_back(5);       // 顶掉 2

    std::cout << "内容:";
    for (int x : cb) std::cout << ' ' << x;
    std::cout << "（size=" << cb.size() << " capacity=" << cb.capacity() << "）\n";

    // 2) 首尾访问（环形语义：back 永远是最新）
    std::cout << "最新 = " << cb.back() << " 最老 = " << cb.front() << '\n';

    // 3) 滑动窗口统计（最近 3 个数的均值）
    boost::circular_buffer<double> win(3);
    double data[] = {10, 20, 30, 40, 50};
    for (double d : data) {
        win.push_back(d);
        double sum = 0;
        for (double w : win) sum += w;
        std::cout << "  窗口均值 = " << sum / win.size() << '\n';
    }

    // ── 4) 环形结构的三件专用操作 ──
    boost::circular_buffer<int> ring(5);
    for (int x : {1, 2, 3, 4, 5}) ring.push_back(x);    // 定容 5，已满
    std::cout << "满容: full? " << ring.full() << " size==capacity? "
              << (ring.size() == ring.capacity()) << '\n';
    // linearize：把"逻辑环"整理成首尾连续的内存块（给 C API/连续算法用）
    int* mem = ring.linearize();
    std::cout << "线性化后连续访问: mem[0]=" << mem[0] << " mem[3]=" << mem[3]
              << " 已线性? " << ring.is_linearized() << '\n';
    // rotate：以某迭代器为新起点整体旋转（不改元素只改"哪里算开头"）
    ring.rotate(ring.begin() + 2);
    std::cout << "rotate(+2) 后:";
    for (int x : ring) std::cout << ' ' << x;
    std::cout << '\n';
    // 【坑】迭代器不环形：只在 begin..end 内有效，越过 end 即失效断言
    // std::cout << *(ring.begin() + 7);   // 越界 → 断言/UB

    // ── 5) space_optimized：元素少时少占内存的适配版 ──
    boost::circular_buffer_space_optimized<int> eco(10);
    for (int i = 1; i <= 4; ++i) eco.push_back(i);
    std::cout << "space_optimized: size=" << eco.size()
              << " capacity=" << eco.capacity() << "（满额才用满 10 块）\n";

    // 线程安全版：手动配锁；无锁场景看 lockfree::spsc_queue
    std::cout << "std 无对应（deque 不是环形语义）\n";

    std::cout << "自检通过\n";
    return 0;
}
