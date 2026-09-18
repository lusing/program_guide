// bind.cpp —— Boost.Bind：参数绑定（std::bind 的直系祖先）
// 对应文档：docs/04-function.md
#include <boost/bind/bind.hpp>
#include <iostream>
#include <memory>
#include <string>

struct Player {
    std::string name;
    int points = 0;
    int score(Player* other) const { return other->points; }
};

int weighted(int base, double w, int bonus) { return base + static_cast<int>(w * bonus); }

int main() {
    using namespace boost::placeholders;   // _1, _2, ...（1.69 起要显式引入）

    // 1) 绑定成员函数：bind(成员指针, 对象, 参数...)
    Player alice{"alice", 42};
    Player bob{"bob", 0};
    auto get_score = boost::bind(&Player::score, &bob, _1);
    std::cout << "成员函数: " << get_score(&alice) << '\n';

    // 2) 参数重排与预绑定：_1/_2 是占位符
    auto w = boost::bind(weighted, _1, 0.5, 100);   // 固定 w 和 bonus
    std::cout << "预绑定: " << w(10) << '\n';

    auto reordered = boost::bind(weighted, _2, 1.0, _1);   // 交换前两个参数位
    std::cout << "重排: " << reordered(7, 20) << '\n';

    // 3) 绑定数据成员指针：把成员访问变成一元函数
    auto name_of = boost::bind(&Player::name, _1);
    std::cout << "成员指针: " << name_of(alice) << '\n';

    // 4) 绑定 shared_ptr 管理的对象（Boost.Bind 的看家本领，早年 std::bind 不会）
    auto sp = std::make_shared<Player>(Player{"carol", 0});
    auto sp_score = boost::bind(&Player::score, sp, _1);
    std::cout << "shared_ptr: " << sp_score(&alice) << '\n';

    std::cout << "自检通过\n";
    return 0;
}
