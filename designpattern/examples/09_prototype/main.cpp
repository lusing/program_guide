// 09 原型。
#include <cassert>
#include <print>

#include "prototype.hpp"

int main() {
    using namespace dp;

    // ---- 从一个模板克隆一队 ----
    GoblinChief chief{3};                        // 带配置的模板：buffs=3
    auto wave = spawn_wave(chief, 3);
    assert(wave.size() == 3);
    for (const auto& m : wave) {
        assert(m->kind() == "chief");
        assert(m->describe() == "goblin-chief(buffs=3)");
    }
    std::println("原型: 波次 {} 个，描述 {}", wave.size(), wave[0]->describe());

    // ---- 克隆是独立副本：改一个不影响其余 ----
    wave[0] = chief.clone();                     // 再克隆一个比较基准
    assert(wave[1]->describe() == "goblin-chief(buffs=3)");

    // ---- kind() 判定克隆保真：Goblin 克出来还是 Goblin ----
    Goblin plain;
    auto g = plain.clone();
    assert(g->kind() == "goblin" && g->describe() == "goblin(hp=10)");
    std::println("克隆保真: chief={}, goblin={}", wave[0]->kind(),
                 g->kind());

    std::println("自检通过");
}
