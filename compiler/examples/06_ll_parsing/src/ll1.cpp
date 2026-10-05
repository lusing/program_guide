// file: src/ll1.cpp
// 第 6 章配套：LL(1) 引擎实现——FIRST/FOLLOW/表/冲突/预测分析。
#include "ll1.hpp"

#include <cassert>

namespace tip {

LL1::LL1(const Grammar &g) : g(g) {}

// ---------- FIRST ----------
// 绿龙的口径：对每个非终结符反复套用三条规则，直到没有任何集合再变大。
// 这是“从下界出发、单调上升、有限高度”的迭代——第 27 章的不动点骨架。
std::set<std::string> LL1::firstOf(const std::vector<std::string> &beta) const {
    std::set<std::string> out;
    bool allEps = true;
    for (const auto &x : beta) {
        std::set<std::string> fx;
        if (g.isTerm(x) || x == DOLLAR) {
            fx = {x};
        } else {
            auto it = first.find(x);
            if (it != first.end()) fx = it->second;
        }
        for (const auto &t : fx)
            if (t != EPS) out.insert(t);
        if (!fx.count(EPS)) {
            allEps = false;
            break;
        }
    }
    if (allEps) out.insert(EPS);
    return out;
}

void LL1::computeFirst() {
    for (const auto &A : g.nonterms) first[A] = {};
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : g.prods) {
            auto &F = first[p.lhs];
            size_t before = F.size();
            for (const auto &t : firstOf(p.rhs)) F.insert(t);
            if (F.size() != before) changed = true;
        }
    }
}

// ---------- FOLLOW ----------
void LL1::computeFollow() {
    for (const auto &A : g.nonterms) follow[A] = {};
    follow[g.start].insert(DOLLAR);
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : g.prods) {
            for (size_t i = 0; i < p.rhs.size(); ++i) {
                const auto &B = p.rhs[i];
                if (!g.isNonterm(B)) continue;
                auto &FB = follow[B];
                size_t before = FB.size();
                // 规则 2：后面紧跟的串的 FIRST（去掉 ε）进 FOLLOW
                std::vector<std::string> rest(p.rhs.begin() + i + 1, p.rhs.end());
                auto fr = firstOf(rest);
                for (const auto &t : fr)
                    if (t != EPS) FB.insert(t);
                // 规则 3：尾部可推空，则左部的 FOLLOW 传递下来
                if (fr.count(EPS) || rest.empty()) {
                    for (const auto &t : follow[p.lhs]) FB.insert(t);
                }
                if (FB.size() != before) changed = true;
            }
        }
    }
}

// ---------- 表构造（绿龙 Algorithm 5.4） ----------
namespace {
// “最近 else”消解：候选里若有右端以 a 开头者（即会吃掉当前 token 的产生式，
// 相当于移进 else），选它——绿龙对文法 (5.11) 的经典裁决：
// 选 S'→eS 让 else 与最内层 then 配对；选 ε 会让 else 永远无法被消费。
int pickWinner(const tip::Grammar &g, const std::string &a,
               int oldIdx, int newIdx, bool resolveClosestElse) {
    if (!resolveClosestElse) return oldIdx;
    if (!g.prods[oldIdx].rhs.empty() && g.prods[oldIdx].rhs[0] == a) return oldIdx;
    if (!g.prods[newIdx].rhs.empty() && g.prods[newIdx].rhs[0] == a) return newIdx;
    return oldIdx;
}
}  // namespace

void LL1::buildTable(bool resolveClosestElse) {
    auto put = [&](const std::string &A, const std::string &a, int idx) {
        auto cell = std::make_pair(A, a);
        auto it = table.find(cell);
        if (it == table.end()) {
            table[cell] = idx;
        } else if (it->second != idx) {
            int winner = pickWinner(g, a, it->second, idx, resolveClosestElse);
            conflicts.push_back({A, a, {it->second, idx}, winner});
            it->second = winner;
        }
    };
    for (size_t idx = 0; idx < g.prods.size(); ++idx) {
        const auto &p = g.prods[idx];
        auto fs = firstOf(p.rhs);
        for (const auto &a : fs)
            if (a != EPS) put(p.lhs, a, static_cast<int>(idx));
        if (fs.count(EPS))
            for (const auto &b : follow[p.lhs])
                put(p.lhs, b, static_cast<int>(idx));
    }
}

// ---------- 预测分析器（绿龙 Fig 5.23） ----------
ParseResult predict(const LL1 &ll, const std::vector<std::string> &input) {
    ParseResult r;
    std::vector<std::string> stack = {DOLLAR, ll.g.start};
    size_t ip = 0;
    while (true) {
        std::string X = stack.back();
        std::string a = ip < input.size() ? input[ip] : DOLLAR;
        if (X == DOLLAR && a == DOLLAR) {
            r.ok = true;
            return r;
        }
        if (ll.g.isTerm(X) || X == DOLLAR) {
            if (X == a) {
                stack.pop_back();
                ++ip;
            } else {
                r.error = "栈顶 " + X + " 期待 " + a;
                r.consumed = ip;
                return r;
            }
        } else {
            auto it = ll.table.find({X, a});
            if (it == ll.table.end()) {
                r.error = "无 " + X + " 的产生式可匹配 " + a;
                r.consumed = ip;
                return r;
            }
            stack.pop_back();
            const auto &rhs = ll.g.prods[it->second].rhs;
            for (auto rit = rhs.rbegin(); rit != rhs.rend(); ++rit) stack.push_back(*rit);
            r.usedProds.push_back(it->second);
        }
    }
}

}  // namespace tip
