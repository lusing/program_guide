// 22 中介者。
#include <cassert>
#include <print>
#include <string>
#include <string_view>
#include <vector>

#include "mediator.hpp"

int main() {
    using namespace dp;

    // ---- 网状 vs 星型：3 个用户全经中介者，无任何直连 ----
    ChatRoom room;
    room.join("alice");
    room.join("bob");
    room.join("carol");
    assert(room.members() == 3);

    User alice{"alice", &room};
    User bob{"bob", &room};
    User carol{"carol", &room};

    alice.say("hello");
    bob.say("hi");
    assert(room.log_size() == 2);                 // 两条消息都进日志
    assert(room.log()[0] == "alice->hello");
    assert(room.log()[1] == "bob->hi");
    std::println("中介者: 3 人房间 2 条消息，日志含 -> 行");

    // alice 不需要认识 bob/carol——say 只把消息交给 room
    carol.say("gg");
    assert(room.log_size() == 3);
    std::println("星型: 同事互不相识，全部通信经 ChatRoom 枢纽");

    // ---- 现代对照：信号槽广播 ----
    SignalHub hub;
    std::vector<std::string> inbox_bob;
    std::vector<std::string> inbox_carol;

    hub.subscribe("alice", [](std::string_view, std::string_view) {});   // 自己也订阅
    hub.subscribe("bob", [&](std::string_view from, std::string_view msg) {
        inbox_bob.push_back(std::format("{}:{}", from, msg));
    });
    hub.subscribe("carol", [&](std::string_view from, std::string_view msg) {
        inbox_carol.push_back(std::format("{}:{}", from, msg));
    });
    assert(hub.subscriber_count() == 3);

    hub.publish("alice", "ping");
    assert(inbox_bob.size() == 1);                // bob 收到 1 条（alice->ping）
    assert(inbox_carol.size() == 1);              // carol 同样
    std::println("信号槽: 发布 1 条，2 个订阅者各收到 1 条（不回声给发布者）");

    hub.publish("bob", "pong");
    assert(inbox_bob.size() == 1);                // bob 不收自己的消息
    assert(inbox_carol.size() == 2);
    std::println("信号槽: bob 发布后自己不回声，carol 收到第 2 条");

    std::println("自检通过");
}
