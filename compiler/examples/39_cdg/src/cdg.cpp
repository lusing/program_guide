// file: src/cdg.cpp
// 第 39 章配套：后支配、控制依赖、SSA 退出实现。
#include "cdg.hpp"

namespace tip {

DomInfo postDominators(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    // 出口块（无后继者；教学程序单出口）
    std::vector<int> exits;
    for (size_t b = 0; b < n; ++b)
        if (adj[b].empty()) exits.push_back(static_cast<int>(b));
    // 迭代：pdom[exit]={exit}；pdom[b]={b} ∪ ⌂ pdom[s∈后继]。
    // 与 33 章支配同骨架，方向相 反：交的角色对“往后走”的后继取。
    std::set<int> all;
    for (size_t k = 0; k < n; ++k) all.insert(static_cast<int>(k));
    DomInfo di;
    di.dom.assign(n, all);
    for (int e : exits) di.dom[e] = {e};
    bool changed = true;
    while (changed) {
        changed = false;
        for (size_t b = 0; b < n; ++b) {
            bool isExit = false;
            for (int e : exits)
                if (e == static_cast<int>(b)) isExit = true;
            if (isExit) continue;
            std::set<int> acc = all;
            for (int s : adj[b]) {
                std::set<int> keep;
                for (int x : acc)
                    if (di.dom[s].count(x)) keep.insert(x);
                acc = keep;
            }
            acc.insert(static_cast<int>(b));
            if (acc != di.dom[b]) {
                di.dom[b] = acc;
                changed = true;
            }
        }
    }
    // idom（此处即“直接后支配者”）：严格后支配者中最贴近的
    di.idom.assign(n, -1);
    for (size_t b = 0; b < n; ++b) {
        int best = -1;
        size_t bestSize = 0;
        for (int d : di.dom[b]) {
            if (d == static_cast<int>(b)) continue;
            if (di.dom[d].size() >= bestSize) {
                bestSize = di.dom[d].size();
                best = d;
            }
        }
        di.idom[b] = best;
    }
    di.children.assign(n, {});
    for (size_t b = 0; b < n; ++b)
        if (di.idom[b] >= 0) di.children[di.idom[b]].push_back(static_cast<int>(b));
    return di;
}

CdgInfo controlDependence(const std::vector<std::vector<int>> &adj, const DomInfo &pdom) {
    size_t n = adj.size();
    CdgInfo cdg;
    cdg.preds.assign(n, {});
    cdg.succs.assign(n, {});
    // Ferrante–Ottenstein–Warren：对每条边 c→s，
    // runner 从 s 沿后支配树上行到“后支配 c”为止，途经节点都控制依赖 c。
    // 与支配边界（CHK）完全同型——一个沿支配树上行管“汇合”，
    // 一个沿后支配树上行管“分岔”。
    for (size_t c = 0; c < n; ++c) {
        for (int s : adj[c]) {
            int runner = s;
            while (runner >= 0) {
                if (runner == static_cast<int>(c)) break;             // c 后支配自己：到站
                if (pdom.dom[c].count(runner)) break;                 // runner 严格后支配 c：到站
                cdg.preds[runner].insert(static_cast<int>(c));        // runner 依赖 c
                cdg.succs[c].insert(runner);                          // c 支配 runner
                runner = pdom.idom[runner];
            }
        }
    }
    return cdg;
}

SsaBackResult ssaBack(const SsaProgram &ssa) {
    SsaBackResult res;
    size_t n = ssa.blocks.size();
    // φ 拆账：前驱 p 的块尾要交的复制（dst, arg）
    std::vector<std::vector<std::pair<std::string, std::string>>> bills(n);
    for (size_t b = 0; b < n; ++b)
        for (const auto &inst : ssa.blocks[b].body) {
            if (inst.phiArgs.empty()) continue;
            for (size_t p = 0; p < ssa.preds[b].size(); ++p)
                bills[ssa.preds[b][p]].push_back({inst.dst, inst.phiArgs[p]});
        }
    // 并行复制串行化：右值 ∩ 左值 = 环名 → 先搬临时（虎书 §19.6 的 swap 问题）
    auto clashOf = [&](size_t b) {
        std::set<std::string> dsts, srcs, clash;
        for (const auto &kv : bills[b]) {
            dsts.insert(kv.first);
            srcs.insert(kv.second);
        }
        for (const auto &d : dsts)
            if (srcs.count(d)) clash.insert(d);
        return clash;
    };
    // 最终长度表（块内加行 ⇒ 目标重贴要不漂移）
    std::vector<int> len(n, 0);
    for (size_t b = 0; b < n; ++b) {
        int phiCount = 0;
        for (const auto &inst : ssa.blocks[b].body)
            if (!inst.phiArgs.empty()) ++phiCount;
        len[b] = static_cast<int>(ssa.blocks[b].body.size()) - phiCount
                 + static_cast<int>(bills[b].size())
                 + static_cast<int>(clashOf(b).size());
    }
    std::vector<int> pos(n, 0);
    int cursor = 0;
    for (size_t b = 0; b < n; ++b) {
        pos[b] = cursor;
        cursor += len[b];
    }
    // 发射：先结算前驱账（环名走临时），再发原体（φ 略去），目标重贴
    std::vector<Quad> out;
    for (size_t b = 0; b < n; ++b) {
        // 顺序：体（除终结符）→ φ 账（含环临时）→ 终结符。
        // 账必须在块尾、跳转之前结算：φ 实参读的是块出口处的值，
        // 放块首会读到本块体还没写的新值（开发时踩过的实坑）。
        const SsaInst *term = nullptr;
        for (const auto &inst : ssa.blocks[b].body) {
            if (!inst.phiArgs.empty()) continue;
            if (inst.op == TOp::Goto || inst.op == TOp::IfGt || inst.op == TOp::IfEq) {
                term = &inst;
                continue;
            }
            Quad q;
            q.op = inst.op;
            q.dst = inst.dst;
            q.a = inst.a;
            q.b = inst.b;
            out.push_back(q);
        }
        auto clash = clashOf(b);
        std::map<std::string, std::string> shadow;
        if (!clash.empty()) {
            ++res.swaps;
            for (const auto &d : clash) {
                shadow[d] = "sb" + std::to_string(res.swaps) + "_" + d;
                out.push_back(Quad{TOp::Copy, shadow[d], d, "", -1});
            }
        }
        for (const auto &kv : bills[b]) {
            std::string src = kv.second;
            if (clash.count(src)) src = shadow[src];
            if (!src.empty() && src.back() == 'u') src = "0";   // ⊥ 名按全 0 初值
            out.push_back(Quad{TOp::Copy, kv.first, src, "", -1});
            ++res.copies;
        }
        if (term) {
            Quad q;
            q.op = term->op;
            q.dst = term->dst;
            q.a = term->a;
            q.b = term->b;
            q.target = pos[term->target];   // SSA 的 target 是块号
            out.push_back(q);
        }
    }
    res.code = std::move(out);
    return res;
}

}  // namespace tip
