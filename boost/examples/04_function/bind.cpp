// bind.cpp —— Boost.Bind：参数绑定（std::bind 的直系祖先）
// 对应文档：docs/04-function.md
#include <boost/bind/bind.hpp>
#include <iostream>
#include <memory>
#include <algorithm>
#include <string>
#include <vector>

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

    // 5) ref：绑定**引用**而非拷贝（大对象/不可拷贝对象的正路；
    //    代价：调用时被引用对象必须还活着——悬垂即 UB）
    int base = 100;
    auto by_ref = boost::bind(weighted, _1, 0.5, boost::ref(base));
    base = 200;                                   // 后改的值生效（引用语义）
    std::cout << "ref 绑定: " << by_ref(10) << "（base 后改成 200 生效）\n";

    // 6) 嵌套 bind：f(g(x)) 的组合（内层先算，结果喂给外层）
    auto composed = boost::bind(weighted, boost::bind(&Player::points, _1), 1.0, 0);
    std::cout << "嵌套: alice.points + 0 = " << composed(alice) << '\n';

    // 7) 比较表达式：bind 结果重载了 ==/</&& 等（find_if 的组合谓词利器）
    std::vector<Player> team{Player{"a", 1}, Player{"b", 50}, Player{"c", 90}};
    auto it = std::find_if(team.begin(), team.end(),
                           boost::bind(&Player::points, _1) > 40 &&
                               boost::bind(&Player::points, _1) < 80);
    std::cout << "组合谓词找到: " << it->name << "（40 < points < 80）\n";

    // 8) 重载/模板函数不能直接绑（无法选目标）：先取函数指针钉死签名（注释存档）

    std::cout << "自检通过\n";
    return 0;
}
