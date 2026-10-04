#pragma once
// 对象适配器：用组合把旧接口（LegacyStack）适配成目标接口（StackLike）。
#include <cstddef>

namespace dp {

// Adaptee：已有代码，接口不合用（pop 同时返回并移除，但没有 empty）。
class LegacyStack {
public:
    void push(int v) { data_[count_++] = v; }
    int pop() { return data_[--count_]; }        // 前置条件：非空（调用方保证）
    [[nodiscard]] int top() const { return data_[count_ - 1]; }
    [[nodiscard]] size_t size() const { return count_; }

private:
    int data_[64]{};
    size_t count_ = 0;
};

// Target：调用方想要的接口。
struct StackLike {
    virtual ~StackLike() = default;
    virtual void push(int) = 0;
    virtual int pop() = 0;
    [[nodiscard]] virtual bool empty() const = 0;
};

// Adapter：持有 Adaptee 的引用/指针，把新接口的每个请求转发/翻译给旧对象。
class StackAdapter final : public StackLike {
public:
    explicit StackAdapter(LegacyStack& legacy) : legacy_(&legacy) {}

    void push(int v) override { legacy_->push(v); }      // 直通
    int pop() override { return legacy_->pop(); }        // 直通
    [[nodiscard]] bool empty() const override {
        return legacy_->size() == 0;                     // 翻译：size==0 扮演 empty
    }

private:
    LegacyStack* legacy_;
};

}  // namespace dp
