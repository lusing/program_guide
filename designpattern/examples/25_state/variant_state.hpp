#pragma once
// 状态的 variant 形态：StateV = variant<IdleS, HasCreditS, DispensingS>，
// 事件处理 = visit + if constexpr 按状态分支；"趋向状态"作为 visit 的返回值带出来，
// visit 结束后再赋回——visit 进行中不得改写被访问的 variant（会销毁正绑定的备选项）。
#include <string>
#include <string_view>
#include <utility>
#include <variant>

namespace dp {

struct IdleS {};
struct HasCreditS {};
struct DispensingS {};

using StateV = std::variant<IdleS, HasCreditS, DispensingS>;

// 机器持 variant + 余额；事件 -> 消息 + 状态自转。
// settle 规则与经典版一致：出货完成后按余款回 HasCredit 或 Idle。
class VMachine2 {
public:
    std::string coin(int v) {
        std::string msg;
        StateV next = std::visit([&](auto& s) -> StateV {
            using T = std::decay_t<decltype(s)>;
            if constexpr (std::is_same_v<T, IdleS>) {
                credit_ += v;
                msg = "credited " + std::to_string(v);
                return StateV{HasCreditS{}};
            } else if constexpr (std::is_same_v<T, HasCreditS>) {
                credit_ += v;
                msg = "credited " + std::to_string(v);
                return s;                            // 留在原状态
            } else {
                msg = "wait";                        // DispensingS
                return s;
            }
        }, state_);
        state_ = std::move(next);                    // visit 结束后才能写 state_
        settle();                                    // 瞬时态就地结算（与经典版同时序）
        return msg;
    }

    std::string crank() {
        std::string msg;
        StateV next = std::visit([&](auto& s) -> StateV {
            using T = std::decay_t<decltype(s)>;
            if constexpr (std::is_same_v<T, IdleS>) {
                msg = "need 25 first";
                return s;
            } else if constexpr (std::is_same_v<T, HasCreditS>) {
                if (credit_ < 25) {                      // 余额不足：不出货、不换态
                    msg = "need more credit";
                    return s;
                }
                credit_ -= 25;
                msg = "dispense";
                return StateV{DispensingS{}};
            } else {
                msg = "wait";                        // DispensingS
                return s;
            }
        }, state_);
        state_ = std::move(next);
        settle();
        return msg;
    }

    [[nodiscard]] std::string state_name() const {
        static constexpr std::string_view names[] = {"idle", "has_credit", "dispensing"};
        return std::string{names[state_.index()]};
    }
    [[nodiscard]] int credit() const { return credit_; }

private:
    void settle() {
        if (std::holds_alternative<DispensingS>(state_))
            state_ = (credit_ >= 25) ? StateV{HasCreditS{}} : StateV{IdleS{}};
    }

    StateV state_ = IdleS{};
    int credit_ = 0;
};

}  // namespace dp
