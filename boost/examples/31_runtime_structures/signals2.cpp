// signals2.cpp —— Boost.Signals2（2007）：类型安全的信号-槽（观察者模式库化）。
// 对应文档：docs/31-runtime-structures.md
#include <boost/signals2.hpp>
#include <iostream>
#include <string>

namespace sig = boost::signals2;

struct Clicked {
    int id;
};

int main() {
    // 1) 声明信号：签名即模板参数
    sig::signal<void(const std::string&)> on_message;

    // 2) 连接多个槽（订阅者）
    on_message.connect([](const std::string& m) {
        std::cout << "  [控制台] " << m << '\n';
    });
    on_message.connect([](const std::string& m) {
        std::cout << "  [日志] 收到 \"" << m << "\"\n";
    });

    // 3) 触发：所有槽按连接序执行
    std::cout << "触发 1:\n";
    on_message("hello");

    // 4) 管理连接：断开特定槽
    {
        sig::connection c = on_message.connect(0, [](const std::string& m) {
            std::cout << "  [优先槽] " << m << '\n';
        });
        std::cout << "触发 2（带优先槽）:\n";
        on_message("world");
        c.disconnect();                       // 精确断开
    }
    std::cout << "触发 3（已断开）:\n";
    on_message("again");

    // 5) 带返回值的聚合（combiner）：默认 optional，可自定义（取最大值等）
    sig::signal<int()> ask;
    ask.connect([] { return 10; });
    ask.connect([] { return 42; });
    auto answer = ask();                       // 默认 combiner 返回最后一个非空
    std::cout << "聚合返回 = " << *answer << "（默认取最后）\n";

    // 6) 线程安全是 2 版的主题：析构竞态由 slot 的 tracked 对象机制解决
    std::cout << "自检通过\n";
    return 0;
}
