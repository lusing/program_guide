#pragma once
// 责任链：请求沿处理者链传递，每个处理者决定"处理"或"传给下一个"。
#include <functional>
#include <memory>
#include <optional>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <vector>

namespace dp {

// Handler 骨架：链的"下一环"由基类统一管理，子类只回答"能不能批、怎么批"。
class Approver {
public:
    virtual ~Approver() = default;
    void set_next(std::unique_ptr<Approver> n) { next_ = std::move(n); }

    std::string handle(int amount) {
        if (amount <= limit())
            return approve(amount);          // 我能批
        if (next_)
            return next_->handle(amount);    // 超权限：传给下一环
        return "rejected";                   // 链尾无人接：默认拒绝
    }

protected:
    [[nodiscard]] virtual std::string approve(int) const = 0;
    [[nodiscard]] virtual int limit() const = 0;

private:
    std::unique_ptr<Approver> next_;
};

class Manager final : public Approver {
protected:
    [[nodiscard]] std::string approve(int) const override { return "manager"; }
    [[nodiscard]] int limit() const override { return 1000; }
};

class Director final : public Approver {
protected:
    [[nodiscard]] std::string approve(int) const override { return "director"; }
    [[nodiscard]] int limit() const override { return 5000; }
};

class Ceo final : public Approver {
protected:
    [[nodiscard]] std::string approve(int) const override { return "ceo"; }
    [[nodiscard]] int limit() const override { return 100000; }
};

// ---- 现代线：表驱动——处理器数组 + 第一个"接单"者胜出 ----
// 每个处理器回答"我接不接"（bool），接单即处理；没人接走 fallback。
inline std::string handle_with_table(
    std::span<const std::function<std::optional<std::string>(int)>> handlers,
    int amount) {
    for (const auto& h : handlers) {
        if (auto r = h(amount)) return *r;      // 有人接单
    }
    return "rejected";                           // 无人接：与链版同一默认策略
}

}  // namespace dp
