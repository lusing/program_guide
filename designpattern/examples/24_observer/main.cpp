// 24 观察者。
#include <cassert>
#include <print>
#include <vector>

#include "observer.hpp"

int main() {
    using namespace dp;

    // ---- 两块显示板订阅气象站 ----
    Subject station;
    DisplayA a;
    DisplayB b;
    station.attach(&a);
    station.attach(&b);
    assert(station.count() == 2);

    station.notify(25.5);
    assert(a.last == 25.5);                      // A 收到
    assert(b.last == 25.5 && b.received);        // B 收到且标记
    std::println("观察者: notify(25.5) 后 A/B 各自更新");

    // ---- detach A：此后只有 B 收到 ----
    station.detach(&a);
    assert(station.count() == 1);
    station.notify(30.0);
    assert(a.last == 25.5);                      // A 停在旧值——没再收到
    assert(b.last == 30.0);                      // B 跟上
    std::println("观察者: detach A 后再 notify，仅 B 更新");

    // ---- 现代对照：function 订阅 ----
    FunctionHub hub;
    std::vector<double> got;
    hub.subscribe([&got](double t) { got.push_back(t); });
    hub.subscribe([](double) {});                // 静默订阅者
    assert(hub.count() == 2);
    hub.notify(25.5);
    hub.notify(30.0);
    assert((got == std::vector<double>{25.5, 30.0}));
    std::println("信号: function 订阅 lambda 收值 25.5/30.0");

    std::println("自检通过");
}
