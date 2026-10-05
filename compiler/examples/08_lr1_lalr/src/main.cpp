// file: src/main.cpp
// 第 8 章驱动（无参运行，走"简单程序"对账协议）：
//   绿龙 L=R 文法 → SLR 造表（冲突对照）→ 规范 LR(1) 造表（无冲突）→
//   LALR 同心合并（状态数下降）→ 两表分析对账（接受/拒绝一致）。
#include "lr1.hpp"

#include <iostream>

namespace {

// 绿龙的 L=R 文法：S→L=R | R; L→*R | id; R→L
// 第 7 章用它演示"SLR 的 FOLLOW 许可证太宽"——本章看 LR(1) 如何精确化。
tip::Grammar lrdGrammar() {
    tip::Grammar g;
    g.prods = {
        {"S'", {"S"}},          // 0: 增广开始
        {"S", {"L", "=", "R"}}, // 1
        {"S", {"R"}},           // 2
        {"L", {"*", "R"}},      // 3
        {"L", {"id"}},          // 4
        {"R", {"L"}},           // 5
    };
    g.terms = {"=", "*", "id", "$"};
    for (const auto &p : g.prods) g.nonterms.insert(p.first);
    return g;
}

std::string showItem(const tip::Grammar &g, const tip::Item &it) {
    const auto &[lhs, rhs] = g.prods[it.prod];
    std::string s = lhs + " → ";
    for (size_t i = 0; i <= rhs.size(); ++i) {
        if (static_cast<int>(i) == it.dot) s += "·";
        if (i < rhs.size()) s += rhs[i] + " ";
    }
    if (!it.la.empty()) s += ", " + it.la;
    return s;
}

std::vector<std::string> split(const std::string &s) {
    std::vector<std::string> out;
    std::string cur;
    for (char c : s) {
        if (c == ' ') { if (!cur.empty()) out.push_back(cur); cur.clear(); }
        else cur += c;
    }
    if (!cur.empty()) out.push_back(cur);
    return out;
}

}  // namespace

int main() {
    tip::Grammar g = lrdGrammar();

    std::cout << "== 文法（增广后）==\n";
    for (size_t i = 0; i < g.prods.size(); ++i) {
        const auto &[lhs, rhs] = g.prods[i];
        std::cout << "  " << i << ": " << lhs << " →";
        for (const auto &x : rhs) std::cout << " " << x;
        std::cout << "\n";
    }

    // ---------- SLR：FOLLOW 发证 ----------
    tip::Table slr = tip::buildSLR(g);
    std::cout << "== SLR(1)（LR(0) 族 + FOLLOW 许可证）==\n";
    std::cout << "  状态数=" << slr.states.size()
              << " 冲突=" << slr.conflicts.size() << "\n";
    for (const auto &[s, a] : slr.conflicts) {
        std::cout << "  状态 " << s << " 上 '" << a << "' 冲突，状态项:\n";
        for (const auto &it : slr.states[s]) std::cout << "    " << showItem(g, it) << "\n";
    }

    // ---------- 规范 LR(1) ----------
    tip::Table lr1 = tip::buildLR1(g);
    std::cout << "== 规范 LR(1)（项带 lookahead）==\n";
    std::cout << "  状态数=" << lr1.states.size()
              << " 冲突=" << lr1.conflicts.size() << "\n";
    int splitCores = 0, shown = 0;
    for (const auto &[core, ids] : lr1.splits) {
        if (ids.size() < 2) continue;
        ++splitCores;
        if (shown < 2) {
            std::cout << "  核心分裂例（同一 LR(0) 核心被 lookahead 拆成 "
                      << ids.size() << " 个 LR(1) 状态）:\n";
            for (int id : ids)
                for (const auto &it : lr1.states[id])
                    std::cout << "    [" << id << "] " << showItem(g, it) << "\n";
            ++shown;
        }
    }
    std::cout << "  分裂核心数=" << splitCores << "\n";

    // ---------- LALR：同心合并 ----------
    tip::Table lalr = tip::buildLALR(g, lr1);
    std::cout << "== LALR(1)（同心合并，lookahead 求并）==\n";
    std::cout << "  合并前状态数=" << lr1.states.size()
              << " 合并后=" << lalr.states.size()
              << " 冲突=" << lalr.conflicts.size() << "\n";

    // ---------- 分析对账 ----------
    std::cout << "== 分析对账（LR(1) vs LALR）==\n";
    struct Case { const char *s; bool want; };
    const Case cases[] = {
        {"id = id", true}, {"id = * id", true}, {"* id = id", true},
        {"id =", false}, {"id id", false},
    };
    bool agree = true;
    for (const auto &c : cases) {
        auto words = split(c.s);
        tip::ParseResult a = tip::tableParse(g, lr1, words);
        tip::ParseResult b = tip::tableParse(g, lalr, words);
        bool ok = a.accept == c.want && b.accept == c.want && a.accept == b.accept;
        agree = agree && ok;
        std::cout << "  \"" << c.s << "\" 期望=" << (c.want ? "接受" : "拒绝")
                  << "  LR(1)=" << (a.accept ? "接受" : "拒绝") << "(" << a.steps << "步)"
                  << "  LALR=" << (b.accept ? "接受" : "拒绝") << "(" << b.steps << "步)"
                  << (ok ? "" : "  ←不一致!") << "\n";
    }

    // ---------- 断言 ----------
    std::cout << "== 对账 ==\n";
    bool ok1 = !slr.conflicts.empty() && lr1.conflicts.empty();
    bool ok2 = lalr.states.size() < lr1.states.size();
    bool ok3 = lalr.states.size() == slr.states.size();   // 同心 ⇒ 状态数回到 LR(0)/SLR
    bool ok4 = agree;
    std::cout << "  SLR 有冲突而 LR(1) 无冲突: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  LALR 状态数 < LR(1): " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  LALR 状态数 == SLR(同心回到 LR(0) 族): " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  LR(1) 与 LALR 接受性一致: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
