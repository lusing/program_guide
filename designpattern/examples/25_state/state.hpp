#pragma once
// 状态：对象的行为随内部状态改变——每个状态一个类，事件处理与状态切换都封装在状态对象里。
// 自动售货机：Idle（待投币）/ HasCredit（已投足）/ Dispensing（出货中，瞬时态）。
// 结构注记：状态类之间互相切换，因此只声明成员函数、在三个状态都完整后统一内联定义。
#include <memory>
#include <string>

namespace dp {

class Machine;

// State：抽象状态——两事件（coin/crank）+ 过态标记。
struct State {
    virtual ~State() = default;
    virtual std::string coin(Machine& m, int v) = 0;
    virtual std::string crank(Machine& m) = 0;
    virtual bool transient() const { return false; }   // 瞬时态：事件结算后自动退出
    virtual std::string name() const = 0;
};

class Machine {
public:
    Machine();                        // 定义放在三个状态完整之后
    std::string coin(int v) {
        std::string msg = state_->coin(*this, v);
        settle();                     // 出货中的瞬时态就地结算
        return msg;
    }
    std::string crank() {
        std::string msg = state_->crank(*this);
        settle();
        return msg;
    }

    [[nodiscard]] std::string state_name() const { return state_->name(); }
    [[nodiscard]] int credit() const { return credit_; }

    void add_credit(int v) { credit_ += v; }
    void take_25() { credit_ -= 25; }
    void to(std::unique_ptr<State> s) { state_ = std::move(s); }

private:
    void settle();                    // Dispensing -> (HasCredit|Idle)
    std::unique_ptr<State> state_;
    int credit_ = 0;
};

// ---- 具体状态：只声明，定义见下 ----
// 每个状态管两件事：本状态的行为 + 趋向哪个状态。
struct Idle final : State {
    std::string coin(Machine& m, int v) override;
    std::string crank(Machine& m) override;
    std::string name() const override;
};

struct HasCredit final : State {
    std::string coin(Machine& m, int v) override;
    std::string crank(Machine& m) override;
    std::string name() const override;
};

// 瞬时态：进入即由 Machine::settle 结算——本状态的事件处理器正常不会被走到。
struct Dispensing final : State {
    std::string coin(Machine& m, int v) override;
    std::string crank(Machine& m) override;
    bool transient() const override { return true; }
    std::string name() const override;
};

// ---- 成员函数定义（全部类型完整后）----
inline Machine::Machine() : state_(std::make_unique<Idle>()) {}

inline std::string Idle::coin(Machine& m, int v) {
    m.add_credit(v);
    m.to(std::make_unique<HasCredit>());
    return "credited " + std::to_string(v);
}
inline std::string Idle::crank(Machine&) { return "need 25 first"; }
inline std::string Idle::name() const { return "idle"; }

inline std::string HasCredit::coin(Machine& m, int v) {
    m.add_credit(v);
    return "credited " + std::to_string(v);
}
inline std::string HasCredit::crank(Machine& m) {
    if (m.credit() < 25) return "need more credit";   // 余额不足：不出货、不换态
    m.take_25();
    m.to(std::make_unique<Dispensing>());
    return "dispense";
}
inline std::string HasCredit::name() const { return "has_credit"; }

inline std::string Dispensing::coin(Machine&, int) { return "wait"; }
inline std::string Dispensing::crank(Machine&) { return "wait"; }
inline std::string Dispensing::name() const { return "dispensing"; }

inline void Machine::settle() {
    if (state_->transient()) {
        // 出货完：余款够一罐回到 HasCredit，否则回 Idle
        if (credit_ >= 25)
            to(std::make_unique<HasCredit>());
        else
            to(std::make_unique<Idle>());
    }
}

}  // namespace dp
