#pragma once
// 合成复用：武器是"拥有"的不是"是"的。
#include <memory>
#include <string>

namespace dp {

struct Weapon {
    virtual ~Weapon() = default;
    virtual int attack() const = 0;
    virtual std::string name() const = 0;
};

class Sword final : public Weapon {
public:
    int attack() const override { return 10; }
    std::string name() const override { return "sword"; }
};

class Axe final : public Weapon {
public:
    int attack() const override { return 25; }
    std::string name() const override { return "axe"; }
};

class Player {
public:
    explicit Player(std::unique_ptr<Weapon> w) : weapon_(std::move(w)) {}
    void rearm(std::unique_ptr<Weapon> w) { weapon_ = std::move(w); }
    int strike() const { return weapon_->attack(); }
    std::string armed_with() const { return weapon_->name(); }

private:
    std::unique_ptr<Weapon> weapon_;  // 组合：运行期可换，继承做不到
};

}  // namespace dp
