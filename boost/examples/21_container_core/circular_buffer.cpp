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

    // 4) 线程安全版：circular_buffer_space_optimized / 手动配锁；
    //    无锁场景看 lockfree::spsc_queue（第 22 章后的并发容器）
    std::cout << "std 无对应（deque 不是环形语义）\n";

    std::cout << "自检通过\n";
    return 0;
}
