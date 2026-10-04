#pragma once
// 装饰：以"同一接口的包装层"为对象逐层附加职责，替代继承的子类爆炸。
#include <format>
#include <string>
#include <string_view>

namespace dp {

// Component：被装饰对象的统一接口。
struct Stream {
    virtual ~Stream() = default;
    [[nodiscard]] virtual std::string write(std::string_view s) const = 0;
};

// ConcreteComponent：没有任何装饰的原件。
struct PlainStream final : Stream {
    [[nodiscard]] std::string write(std::string_view s) const override {
        return std::string{s};
    }
};

// Decorator 基类（本例两类装饰共用包装骨架）：持有内层 Stream。
// 每层装饰 = 转发给内层 + 自己附加的职责（前/后加工）。
class UpperDecorator final : public Stream {
public:
    explicit UpperDecorator(const Stream& inner) : inner_(&inner) {}
    [[nodiscard]] std::string write(std::string_view s) const override {
        std::string in = inner_->write(s);    // 装饰 = 先转发内层，再附加职责
        std::string out;
        out.reserve(in.size());
        for (char c : in) out += static_cast<char>(c >= 'a' && c <= 'z' ? c - 32 : c);
        return out;
    }

private:
    const Stream* inner_;
};

class TimestampDecorator final : public Stream {
public:
    explicit TimestampDecorator(const Stream& inner) : inner_(&inner) {}
    // 静态递增计数代替 chrono：输出确定性（本书约定）
    [[nodiscard]] std::string write(std::string_view s) const override {
        return std::format("[T{}]{}", seq_++, inner_->write(s));
    }

private:
    const Stream* inner_;
    inline static int seq_ = 0;   // 教学简化：跨对象共享计数，保证输出可预测
};

}  // namespace dp
