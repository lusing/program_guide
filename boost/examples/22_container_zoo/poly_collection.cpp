// poly_collection.cpp —— Boost.PolyCollection（2017）：多态对象的高性能容器。
// vector<unique_ptr<Base>> 的虚调用跳来跳去毁缓存；poly_collection 把
// 同型元素分段连续存放——迭代全部内联化，快 2-20 倍。
// 对应文档：docs/22-container-zoo.md
#include <boost/poly_collection/base_collection.hpp>
#include <iostream>
#include <memory>
#include <vector>

struct Sprite {
    virtual ~Sprite() = default;
    virtual void render() const = 0;
    virtual int cost() const = 0;
};
struct Warrior : Sprite {
    void render() const override { std::cout << "兵"; }
    int cost() const override { return 1; }
};
struct Archer : Sprite {
    void render() const override { std::cout << "弓"; }
    int cost() const override { return 2; }
};
struct Mage : Sprite {
    void render() const override { std::cout << "法"; }
    int cost() const override { return 3; }
};

int main() {
    boost::base_collection<Sprite> army;

    // 1) 乱序插入——内部自动按实际类型分段
    for (int i = 0; i < 3; ++i) army.insert(Warrior{});
    army.insert(Archer{});
    army.insert(Mage{});
    army.insert(Archer{});

    // 2) 段过滤：只渲染 Archer——段迭代器是一对（begin/end），不是 range
    std::cout << "只看弓手: ";
    for (auto it = army.begin<Archer>(), e = army.end<Archer>(); it != e; ++it) {
        std::cout << "弓";
    }
    std::cout << '\n';

    // 3) 全员遍历：段的顺序是注册顺序，段内连续（缓存命中率高）
    std::cout << "全军: ";
    std::for_each(army.begin(), army.end(), [](const Sprite& s) { s.render(); });
    std::cout << '\n';

    // 4) 聚合统计
    int total = 0;
    std::for_each(army.begin(), army.end(), [&](const Sprite& s) { total += s.cost(); });
    std::cout << "总成本 = " << total << "（3 兵 + 2 弓 + 1 法 = 3+4+3）\n";

    // 5) 对照：vector<unique_ptr> 版（每个元素一次解引用 + 虚跳转）
    std::vector<std::unique_ptr<Sprite>> ref;
    ref.push_back(std::make_unique<Warrior>());
    ref.push_back(std::make_unique<Mage>());
    int rt = 0;
    for (const auto& s : ref) rt += s->cost();
    std::cout << "传统版成本 = " << rt << "（语义同，布局差）\n";

    std::cout << "自检通过\n";
    return 0;
}
