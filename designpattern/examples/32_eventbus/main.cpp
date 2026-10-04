// 32 事件总线：订阅/发布/退订全链路 + id 单调性 + 无人话题静默。
#include <cassert>
#include <print>
#include <string>

#include "eventbus.hpp"

int main() {
    using namespace dp;

    EventBus bus;
    int a1 = 0, a2 = 0, b1 = 0;
    std::string last_payload;

    // 订阅 3 个：topicA 两路，topicB 一路
    const auto id1 = bus.subscribe("topicA", [&](const Evt& e) { ++a1; last_payload = e.payload; });
    const auto id2 = bus.subscribe("topicA", [&](const Evt&) { ++a2; });
    const auto id3 = bus.subscribe("topicB", [&](const Evt&) { ++b1; });
    assert(id1 < id2 && id2 < id3);        // id 全局单调递增（只比大小，不打印）

    // 发布 topicA 两条：两路各收 2 条，topicB 收 0 条
    bus.publish({"topicA", "first"});
    bus.publish({"topicA", "second"});
    assert(a1 == 2 && a2 == 2 && b1 == 0);
    assert(last_payload == "second");      // handler 收到完整事件

    bus.publish({"topicB", "for-b"});
    assert(b1 == 1);

    // 退订 topicA 的第二路：此后只有第一路增长
    assert(bus.unsubscribe(id2));
    assert(!bus.unsubscribe(id2));         // 重复退订：false
    bus.publish({"topicA", "third"});
    assert(a1 == 3 && a2 == 2);

    // 无人订阅的话题：静默通过，不崩
    bus.publish({"no-such-topic", "x"});

    std::println("事件总线: 3 订阅 / 5 发布 / 1 退订，计数与 id 单调性全部符合预期");
    std::println("自检通过");
}
