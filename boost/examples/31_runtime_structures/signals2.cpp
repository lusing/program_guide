// signals2.cpp —— Boost.Signals2（2007）：类型安全的信号-槽（观察者模式库化）。
// 对应文档：docs/31-runtime-structures.md
#include <boost/signals2.hpp>
#include <boost/make_shared.hpp>
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

    // 6) 进阶全家（书 ch11.4 后半）：组号排序 + scoped + 阻塞 + track
    {
        sig::signal<void()> g;
        g.connect(1, [] { std::cout << "  组1"; });    // 组号小的先调
        g.connect(3, [] { std::cout << " 组3"; });
        g.connect(3, [] { std::cout << " 组3'"; });    // 同组内按连接序
        g.connect(0, [] { std::cout << "前置 "; });    // 未编组 at_front 在最前
        g();                                            // 前置 组1 组3 组3'
        std::cout << '\n';
    }
    {   // scoped_connection：作用域即连接生命期（RAII 版 connection）
        sig::signal<void()> s;
        s.connect([] { std::cout << "常驻 "; });
        {
            sig::scoped_connection sc =
                s.connect([] { std::cout << "临时 "; });
            s();                                        // 常驻 临时
        }                                               // ← 离开作用域自动断开
        s();                                            // 常驻
        std::cout << '\n';
    }
    {   // shared_connection_block：临时屏蔽不断开（区别于 disconnect）
        sig::signal<void()> s;
        sig::connection c = s.connect([] { std::cout << "A"; });
        s();                                            // A
        {
            sig::shared_connection_block block(c);      // 屏蔽
            s();                                        // （A 不响）
        }                                               // ← 解除屏蔽
        s();                                            // A
        std::cout << '\n';
    }
    {   // track：槽的宿主对象死了 → 连接自动断开（防悬垂调用的关键机制）
        // 【实测坑】track 只认 boost 指针体系（boost::shared_ptr 的弱引用
        // 特化）；std::shared_ptr/std::weak_ptr 传进去编不过——1.92 仍未收编
        sig::signal<int()> ask2;
        boost::shared_ptr<int> host(new int(1));
        ask2.connect(sig::signal<int()>::slot_type(
                         [&host] { (void)host; return 7; })
                         .track(host));
        std::cout << "存活时调用 = " << *ask2() << ' ';
        host.reset();                                   // 宿主销毁
        std::cout << "销毁后槽数 = " << ask2.num_slots()
                  << "（连接自动断开）\n";
    }

    std::cout << "自检通过\n";
    return 0;
}
