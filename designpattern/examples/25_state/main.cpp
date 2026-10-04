// 25 状态。
#include <cassert>
#include <print>
#include <string>

#include "state.hpp"
#include "variant_state.hpp"

int main() {
    using namespace dp;

    // ---- 经典版：完整事件序列 ----
    Machine m;
    assert(m.coin(25) == "credited 25");
    assert(m.state_name() == "has_credit" && m.credit() == 25);

    assert(m.crank() == "dispense");
    assert(m.state_name() == "idle" && m.credit() == 0);   // 出货后回 idle
    std::println("状态: coin(25)->crank->dispense，出货后回 idle");

    assert(m.crank() == "need 25 first");                  // 空转提示
    assert(m.coin(10) == "credited 10");
    assert(m.crank() == "need more credit");               // 余额不足
    std::println("状态: 余额 10 不足一罐，crank 提示");

    // ---- 余款跨罐：投两罐，出货后仍在 has_credit ----
    m.coin(15);                                            // 余额 25
    m.coin(25);                                            // 余额 50
    assert(m.crank() == "dispense");
    assert(m.state_name() == "has_credit" && m.credit() == 25);
    std::println("状态: 余款 25 跨罐保留在 has_credit");

    // ---- variant 版：同一序列逐事件同输出、同状态名 ----
    VMachine2 v;
    assert(v.coin(25) == "credited 25" && v.state_name() == "has_credit");
    assert(v.crank() == "dispense" && v.state_name() == "idle" && v.credit() == 0);
    assert(v.crank() == "need 25 first");
    assert(v.coin(10) == "credited 10" && v.crank() == "need more credit");
    assert(v.coin(15) == "credited 15" && v.coin(25) == "credited 25");
    assert(v.crank() == "dispense" && v.state_name() == "has_credit" && v.credit() == 25);
    std::println("variant: 全序列与经典版逐事件同输出");

    std::println("自检通过");
}
