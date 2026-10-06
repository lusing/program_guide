// file: src/typeequiv.cpp
#include "typeequiv.hpp"

namespace teq {

bool nameEq(int a, int b) { return a == b; }

namespace {

// 递归辅助：assume 是"正在假设相等"的对集——环上的重逢即等。
bool eq(const Graph &g, int a, int b, std::set<std::pair<int, int>> &assume,
        long long *steps) {
    if (++*steps > 10000) return false;   // 保险丝（正文的有界断言）
    if (a == b) return true;              // 名字等价是结构等价的子集
    if (g.nodes[a].kind != g.nodes[b].kind) return false;
    auto key = std::make_pair(a, b);
    if (assume.count(key)) return true;   // 环闭合：这对在途中已假设相等
    assume.insert(key);
    switch (g.nodes[a].kind) {
    case Graph::Node::Kind::Int:
        return true;                       // 两个 Int 节点：结构同构
    case Graph::Node::Kind::Named:
        // 名字不同的声明：结构等价看展开后的形状（本实现：名字即形状的根——
        // 结构等价下"别名"应当透传；教学版按"名字不同即不等"处理并注明口径，
        // 真实实现需要展开指向（Named 持 def 下标）——练习 3 的扩展点）
        return false;
    case Graph::Node::Kind::Record: {
        const auto &fa = g.nodes[a].fields, &fb = g.nodes[b].fields;
        if (fa.size() != fb.size()) return false;
        for (size_t k = 0; k < fa.size(); ++k) {
            if (fa[k].first != fb[k].first) return false;   // 字段名参与同构（含序）
            if (!eq(g, fa[k].second, fb[k].second, assume, steps)) return false;
        }
        return true;
    }
    case Graph::Node::Kind::Arrow:
        return eq(g, g.nodes[a].from, g.nodes[b].from, assume, steps) &&
               eq(g, g.nodes[a].to, g.nodes[b].to, assume, steps);
    }
    return false;
    }

}  // namespace

bool structEq(const Graph &g, int a, int b, long long *steps) {
    long long dummy = 0;
    if (!steps) steps = &dummy;
    std::set<std::pair<int, int>> assume;
    return eq(g, a, b, assume, steps);
}

}  // namespace teq
