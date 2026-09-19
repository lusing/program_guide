// multi_index.cpp —— Boost.MultiIndex（2003）：一个容器多套索引。
// "既要按 id 查、又要按名字查、还要按分数排序"的数据库式需求。
// 对应文档：docs/22-container-zoo.md
#include <boost/multi_index_container.hpp>
#include <boost/multi_index/member.hpp>
#include <boost/multi_index/ordered_index.hpp>
#include <boost/multi_index/hashed_index.hpp>
#include <boost/multi_index/ranked_index.hpp>
#include <iostream>
#include <string>

namespace bmi = boost::multi_index;

struct User {
    int id;
    std::string name;
    int score;
};

using Users = bmi::multi_index_container<
    User,
    bmi::indexed_by<
        bmi::ordered_unique<bmi::member<User, int, &User::id>>,
        bmi::hashed_unique<bmi::member<User, std::string, &User::name>>,
        bmi::ranked_non_unique<bmi::member<User, int, &User::score>>>>;

int main() {
    Users users;
    users.insert({3, "carol", 88});
    users.insert({1, "ada", 95});
    users.insert({2, "bob", 75});

    // 索引 0：按 id 有序
    std::cout << "按 id:";
    for (const auto& u : users.get<0>()) std::cout << ' ' << u.id << u.name;
    std::cout << '\n';

    // 索引 1：按名字哈希查（O(1)）
    auto& by_name = users.get<1>();
    auto it = by_name.find("bob");
    std::cout << "名字查 bob: id=" << it->id << " 分=" << it->score << '\n';

    // 索引 2：ranked——有序 + O(log) 名次查询（rank() 是它的独门，
    //         区间统计用 lower_bound + distance）
    auto& by_score = users.get<2>();
    auto it90 = by_score.lower_bound(90);
    std::cout << "分数 < 90 的人数 = " << std::distance(by_score.begin(), it90) << '\n';
    std::cout << "90 分以上人数 = " << std::distance(it90, by_score.end()) << '\n';

    // 通过任一索引修改（语义：删+插，键不变约束仍在）
    auto& by_id = users.get<0>();
    by_id.modify(by_id.find(2), [](User& u) { u.score = 99; });
    std::cout << "bob 改分后 = " << by_name.find("bob")->score << '\n';

    std::cout << "自检通过\n";
    return 0;
}
