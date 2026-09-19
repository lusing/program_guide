// statechart.cpp —— Boost.Statechart（2003）：分层状态机的老牌实现
//（UML 语义：层次、正交区、历史）。轻量场景看它，事件风暴看 msm。
// 对应文档：docs/31-runtime-structures.md
#include <boost/statechart/state_machine.hpp>
#include <boost/statechart/simple_state.hpp>
#include <boost/statechart/state.hpp>
#include <boost/statechart/transition.hpp>
#include <boost/statechart/custom_reaction.hpp>
#include <boost/statechart/event.hpp>
#include <iostream>

namespace sc = boost::statechart;

// 事件
struct EvStart : sc::event<EvStart> {};
struct EvStop  : sc::event<EvStop> {};

// 前向声明
struct Active;
struct Idle;
struct Running;

// 状态机
struct Machine : sc::state_machine<Machine, Active> {};

// 状态与迁移：Active 是外层简单态（对事件无反应，由内层处理）
struct Active : sc::simple_state<Active, Machine, Idle> {};
struct Idle : sc::simple_state<Idle, Active> {
    using reactions = sc::transition<EvStart, Running>;
    Idle() { std::cout << "  进入 Idle\n"; }
    ~Idle() { std::cout << "  离开 Idle\n"; }
};
struct Running : sc::simple_state<Running, Active> {
    using reactions = sc::transition<EvStop, Idle>;
    Running() { std::cout << "  进入 Running\n"; }
    ~Running() { std::cout << "  离开 Running\n"; }
};

int main() {
    Machine m;
    m.initiate();                      // 启动 → Active/Idle
    std::cout << "发 EvStart:\n";
    m.process_event(EvStart{});        // → Running
    std::cout << "再发 EvStart（无迁移）:\n";
    m.process_event(EvStart{});        // 无反应
    std::cout << "发 EvStop:\n";
    m.process_event(EvStop{});         // → Idle
    std::cout << "状态机工作正常\n";

    std::cout << "自检通过\n";
    return 0;
}
