// msm.cpp —— Boost.MSM（2010）：极速状态机（模板元编程把迁移表
// 展开成 O(1) 跳转表——比 statechart 快一个数量级）。
// 对应文档：docs/31-runtime-structures.md
#include <boost/mpl/vector.hpp>
#include <boost/msm/front/state_machine_def.hpp>
#include <boost/msm/back/state_machine.hpp>
#include <iostream>

namespace msm = boost::msm;
namespace front = boost::msm::front;

// 事件
struct play {};
struct stop {};
struct pause {};

// 状态（简单态：无行为的空结构）
struct Stopped : front::state<> {};
struct Playing : front::state<> {};
struct Paused : front::state<> {};

// 状态机定义：继承 state_machine_def，写迁移表
struct Player_ : front::state_machine_def<Player_> {
    // 初始状态
    using initial_state = Stopped;

    // 迁移表：行 = 开始状态 + 事件 + 目标状态 + 动作 + 守卫
    struct transition_table : boost::mpl::vector<
        _row<Stopped,  play,   Playing>,
        _row<Playing,  stop,   Stopped>,
        _row<Playing,  pause,  Paused>,
        _row<Paused,   play,   Playing>,
        _row<Paused,   stop,   Stopped>> {};

    // 进入/退出动作（可选钩子）
    // 进入/退出动作（可选钩子；签名要 (事件, 状态机) 两参模板）
    template <class Event, class FSM>
    void on_entry(Event const&, FSM&) { std::cout << "  [进入初始态]\n"; }
};
using Player = msm::back::state_machine<Player_>;

int main() {
    Player p;
    p.start();
    std::cout << "play:\n";    p.process_event(play{});
    std::cout << "pause:\n";   p.process_event(pause{});
    std::cout << "play:\n";    p.process_event(play{});
    std::cout << "stop:\n";    p.process_event(stop{});
    std::cout << "状态机全链路走完\n";

    std::cout << "自检通过\n";
    return 0;
}
