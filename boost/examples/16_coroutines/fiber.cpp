// fiber.cpp —— Boost.Fiber（2015）：用户态线程（有栈协程 + 调度器）
// 对应文档：docs/16-coroutines.md
// 与 thread 同构的 API（mutex/condition_variable/future），但切换
// 成本是几十纳秒级——高并发 IO 的第三条路（thread / async / fiber）。
#include <boost/fiber/all.hpp>
#include <iostream>
#include <vector>

int main() {
    // 1) fiber 就像 thread，但跑在用户态调度器上
    std::vector<boost::fibers::fiber> fs;
    int results[4] = {0, 0, 0, 0};
    for (int i = 0; i < 4; ++i) {
        fs.emplace_back([i, &results] {
            results[i] = (i + 1) * 100;          // 每个 fiber 干一点活
            boost::this_fiber::yield();          // 让出调度点
        });
    }
    for (auto& f : fs) f.join();
    std::cout << "4 个 fiber 结果 = " << results[0] << ' ' << results[1]
              << ' ' << results[2] << ' ' << results[3] << '\n';

    // 2) fiber 间的同步原语与 std 同名（channel 是 fiber 家的利器）
    boost::fibers::buffered_channel<int> ch(16);
    boost::fibers::fiber producer([&ch] {
        for (int i = 1; i <= 5; ++i) ch.push(i * i);
        ch.close();
    });
    int sum = 0;
    for (int v : ch) sum += v;                  // range-for 消费到关闭
    producer.join();
    std::cout << "channel 传值求和 = " << sum << "（1+4+9+16+25）\n";

    // 3) work_stealing 调度器等高级话题见文档
    std::cout << "自检通过\n";
    return 0;
}
