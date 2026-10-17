// bimap.cpp —— Boost.BiMap（2004）：双向 map——键值都可查。
// std::map 是单向的；bimap<int, std::string> 两边都是键。
// 对应文档：docs/22-container-zoo.md
#include <boost/bimap.hpp>
#include <boost/bimap/list_of.hpp>
#include <boost/bimap/multiset_of.hpp>
#include <boost/bimap/set_of.hpp>
#include <boost/bimap/set_of.hpp>
#include <boost/bimap/unordered_set_of.hpp>
#include <boost/bimap/vector_of.hpp>
#include <boost/bimap/support/lambda.hpp>   // _key / _data（modify 用）
#include <boost/assign/list_of.hpp>
#include <iostream>
#include <string>

int main() {
    boost::bimap<int, std::string> bm;

    // ── 1) 两边都是唯一键 ──
    bm.insert({1, "one"});
    bm.insert({2, "two"});
    bm.insert({3, "three"});
    std::cout << "左查(1) = " << bm.left.at(1)
              << " 右查(three) = " << bm.right.at("three") << '\n';
    // 双向的代价：两边都必须唯一，且迭代器给的是 pair<const, const>——
    // 不能像 std::map 那样改 value
    auto r = bm.insert({9, "one"});
    std::cout << "重复右值插入成功? " << r.second
              << "（大小仍 " << bm.size() << "）\n";
    // 没有 operator[]/at（关联数组语义与"两边都是键"矛盾）

    // ── 2) 关系视图：遍历拿到的是 relation（左/右两个投影）──
    for (const auto& rel : bm) {
        std::cout << "  " << rel.left << " ↔ " << rel.right << '\n';
        if (rel.left == 2) break;   // 打印到 2 就够
    }

    // ── 3) 集合类型可配置：左/右各选一种 ──
    // set_of(默认)/multiset_of/unordered_set_of/unordered_multiset_of/
    // list_of(序列，只能做"值")/vector_of/unconstrained_set_of(无约束)
    boost::bimap<boost::bimaps::set_of<int>,
                 boost::bimaps::multiset_of<std::string>> bm2;
    bm2.insert({1, "a"});
    bm2.insert({2, "a"});       // 右值 "a" 重复——multiset 右侧允许
    bm2.insert({1, "b"});       // 左键 1 重复——仍被拒（左侧是 set_of）
    std::cout << "multiset 右侧: \"a\" 映 " << bm2.right.count("a")
              << " 个左键（大小 " << bm2.size() << "）\n";
    // 右侧是 vector_of 时左视图还能用 operator[]/at（关联数组形态）：
    boost::bimap<boost::bimaps::set_of<int>,
                 boost::bimaps::vector_of<std::string>> bm3;
    bm3.left.insert({1, "111"});
    bm3.left[2] = "222";                 // vector 侧可下标
    bm3.left[300] = "bimap";
    std::cout << "vector 右侧: " << bm3.left.at(300) << '\n';

    // ── 4) 标签：给两个视图起名字（比 left/right 更达意）──
    {
        using namespace boost::bimaps;
        bimap<tagged<int, struct id>, tagged<std::string, struct name>> tb;
        tb.by<id>().insert({1, "mario"});
        tb.by<id>().insert({2, "peach"});
        tb.by<name>().insert({"yoshi", 5});     // 名字侧也能插
        std::cout << "by<id>(2) = " << tb.by<id>().at(2)
                  << " by<name>(yoshi) = " << tb.by<name>().at("yoshi") << '\n';
    }

    // ── 5) 查找、替换与修改 ──
    using bm_t = boost::bimap<int, std::string>;
    bm_t prod = boost::assign::list_of<bm_t::relation>(1, "mario")(2, "peach");
    auto pos = prod.left.find(1);
    prod.left.replace_key(pos, 111);          // 替换键：1 → 111（失败返回 false）
    prod.left.replace_data(pos, "luigi");     // 替换值
    std::cout << "replace 后: [111]=" << prod.left.at(111) << '\n';
    // modify_*：更快，但违反唯一约束时**元素被删**（不抛异常！）
    auto pos2 = prod.left.find(2);
    std::size_t before = prod.size();
    prod.left.modify_key(pos2, boost::bimaps::_key = 111);   // 撞车 → 元素没了
    std::cout << "modify 撞车: " << before << " → " << prod.size()
              << "（peach 被删，找不到? "
              << (prod.right.find("peach") == prod.right.end()) << "）\n";

    // ── 6) 投射：左视图迭代器 ↔ 右视图迭代器 ──
    auto left_pos = prod.left.find(111);
    auto right_pos = prod.project_right(left_pos);
    std::cout << "投射: 左[111] → 右[" << right_pos->first << "]\n";

    // ── 7) 内建值类型：比 make_pair 少一次拷贝 ──
    bm_t bm4;
    bm4.left.insert(bm_t::left_value_type(7, "seven"));
    bm4.right.insert(bm_t::right_value_type("eight", 8));
    std::cout << "内建值类型: " << bm4.left.at(7) << "/" << bm4.right.at("eight") << '\n';

    std::cout << "自检通过\n";
    return 0;
}
