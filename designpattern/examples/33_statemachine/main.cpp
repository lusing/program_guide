// 33 状态机实战：编译期 static_assert 定转移表，运行期 walk 解释事件序列。
#include <cassert>
#include <print>
#include <vector>

#include "fsm.hpp"

int main() {
    using namespace dp;

    // 静态表：coin,crank 两步 -> idle,paid,dispensing
    const std::vector<Ev> main_evs{Ev::coin, Ev::crank};
    const auto path = walk(kTable, St::idle, main_evs);
    assert((path == std::vector<St>{St::idle, St::paid, St::dispensing}));
    std::println("主路径: coin,crank -> idle,paid,dispensing（与断言一致）");

    // 非法事件 crank@idle：拒绝、停原地；拒绝计数 = 事件数 - 消耗数
    const std::vector<Ev> evs2{Ev::crank, Ev::coin, Ev::crank};
    const auto path2 = walk(kTable, St::idle, evs2);
    assert((path2 == std::vector<St>{St::idle, St::paid, St::dispensing}));
    const int rejected =
        static_cast<int>(evs2.size()) - (static_cast<int>(path2.size()) - 1);
    assert(rejected == 1);
    std::println("拒绝线: crank@idle 被拒 1 次，其余事件照常推进");

    // reset 路径：paid --reset--> idle；dispensing --reset--> idle
    const std::vector<Ev> evs3{Ev::coin, Ev::reset};
    const auto path3 = walk(kTable, St::idle, evs3);
    assert((path3 == std::vector<St>{St::idle, St::paid, St::idle}));

    const std::vector<Ev> evs4{Ev::coin, Ev::crank, Ev::reset};
    const auto path4 = walk(kTable, St::idle, evs4);
    assert((path4 == std::vector<St>{St::idle, St::paid, St::dispensing, St::idle}));
    std::println("回退线: 两处 reset 均回 idle，路径与断言一致");

    std::println("自检通过");
}
