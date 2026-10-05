// file: src/reach.cpp
// 第 31 章配套：到达定值实现。
#include "reach.hpp"

#include <cctype>

namespace tip {

namespace {
bool defInstr(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

ReachInfo reaching(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    ReachInfo ri;
    size_t n = blocks.size();
    ri.in.assign(n, {});
    ri.out.assign(n, {});
    ri.gen.assign(n, {});
    ri.kill.assign(n, {});
    for (int i = 0; i < static_cast<int>(code.size()); ++i)
        if (defInstr(code[i])) ri.defVar[i] = code[i].dst;
    // gen[B]：块内“向下冒出来”的定值（同块更晚的同变量定值会遮蔽更早的）；
    // kill[B]：块内定值变量的其它全部定值。
    for (size_t b = 0; b < n; ++b) {
        for (int i = blocks[b].begin; i < blocks[b].end; ++i) {
            auto it = ri.defVar.find(i);
            if (it == ri.defVar.end()) continue;
            const std::string &v = it->second;
            ri.gen[b].insert(i);
            for (int j = blocks[b].begin; j < i; ++j)
                if (ri.defVar.count(j) && ri.defVar.at(j) == v) ri.gen[b].erase(j);
            for (const auto &d : ri.defVar)
                if (d.second == v && d.first != i) ri.kill[b].insert(d.first);
        }
    }
    // 前向 may：in = ∪ 前驱 out；out = gen ∪ (in − kill)。迭代至稳定——
    // 值只会增（may 半格上单调上升），有限高度保证终止（第 27 章的论证）。
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = 0; b < n; ++b) {
            std::set<int> in;
            for (size_t q = 0; q < n; ++q)
                for (int s : blocks[q].succs)
                    if (s == blocks[b].begin)
                        in.insert(ri.out[q].begin(), ri.out[q].end());
            std::set<int> out = ri.gen[b];
            for (int d : in)
                if (!ri.kill[b].count(d)) out.insert(d);
            if (in != ri.in[b] || out != ri.out[b]) {
                ri.in[b] = in;
                ri.out[b] = out;
                changed = true;
            }
        }
    }
    return ri;
}

std::set<int> udChain(const ReachInfo &ri, const std::vector<Block> &blocks,
                      int i, const std::string &v) {
    // IN 里的 v 定值，加上块内 i 之前 v 的最后定值（它遮蔽 IN）。
    std::set<int> out;
    size_t b = 0;
    for (size_t k = 0; k < blocks.size(); ++k)
        if (i >= blocks[k].begin && i < blocks[k].end) { b = k; break; }
    for (int d : ri.in[b])
        if (ri.defVar.at(d) == v) out.insert(d);
    for (int j = blocks[b].begin; j < i; ++j)
        if (ri.defVar.count(j) && ri.defVar.at(j) == v) {
            out.clear();
            out.insert(j);
        }
    return out;
}

}  // namespace tip
