#pragma once
// 原型：以一个对象为模板批量克隆，绕开"逐字段重新配置"的构造开销。
#include <format>
#include <memory>
#include <string>
#include <vector>

namespace dp {

struct Monster {
    virtual ~Monster() = default;
    virtual std::unique_ptr<Monster> clone() const = 0;
    [[nodiscard]] virtual std::string kind() const = 0;   // 比 typeid 可移植的判定
    [[nodiscard]] virtual std::string describe() const = 0;
};

class Goblin : public Monster {
public:
    std::unique_ptr<Monster> clone() const override { return std::make_unique<Goblin>(*this); }
    [[nodiscard]] std::string kind() const override { return "goblin"; }
    [[nodiscard]] std::string describe() const override { return "goblin(hp=10)"; }
};

// 协变返回：子类 clone 声明成返回 unique_ptr<Goblin> 是可以的，
// 但接口统一在 Monster::clone 上，容器里拿到的仍是 unique_ptr<Monster>。
class GoblinChief final : public Goblin {
public:
    GoblinChief() = default;
    explicit GoblinChief(int buffs) : buffs_(buffs) {}
    std::unique_ptr<Monster> clone() const override { return std::make_unique<GoblinChief>(*this); }
    [[nodiscard]] std::string kind() const override { return "chief"; }
    [[nodiscard]] std::string describe() const override {
        return std::format("goblin-chief(buffs={})", buffs_);
    }

private:
    int buffs_ = 1;
};

// 原型的用武之地：复杂配置的对象按模板复制 n 份，调用方不碰构造细节。
inline std::vector<std::unique_ptr<Monster>> spawn_wave(const Monster& proto, size_t n) {
    std::vector<std::unique_ptr<Monster>> wave;
    wave.reserve(n);
    for (size_t i = 0; i < n; ++i) wave.push_back(proto.clone());
    return wave;
}

}  // namespace dp
