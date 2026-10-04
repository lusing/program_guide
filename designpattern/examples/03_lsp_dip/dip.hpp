#pragma once
// 依赖倒置：高层 Switch 只认抽象 Switchable。
#include <string>

namespace dp {

class Switchable {
public:
    virtual ~Switchable() = default;
    virtual void on() = 0;
    virtual void off() = 0;
};

class Light final : public Switchable {
public:
    void on() override { state_ = "light-on"; }
    void off() override { state_ = "light-off"; }
    [[nodiscard]] const std::string& state() const { return state_; }
private:
    std::string state_ = "light-off";
};

class Fan final : public Switchable {
public:
    void on() override { state_ = "fan-on"; }
    void off() override { state_ = "fan-off"; }
    [[nodiscard]] const std::string& state() const { return state_; }
private:
    std::string state_ = "fan-off";
};

class Switch {
public:
    explicit Switch(Switchable& dev) : dev_(dev) {}
    void toggle() {
        on_ = !on_;
        if (on_) dev_.on(); else dev_.off();
    }
    [[nodiscard]] bool is_on() const { return on_; }
private:
    Switchable& dev_;
    bool on_ = false;
};

}  // namespace dp
