// file: src/lr1.cpp
// 第 8 章配套：FIRST/FOLLOW、CLOSURE/GOTO（带 lookahead）、规范 LR(1) 造表、
// SLR 对照表、LALR 同心合并、表驱动分析器（鲸书 §3.4.2 + §3.6.2 + §3.7）。
#include "lr1.hpp"

namespace tip {

namespace {

bool isTerm(const Grammar &g, const std::string &s) { return g.terms.count(s) > 0; }

// 单符号的 FIRST（含 ε 传播标记：返回集合里带 "" 表示可空）
std::set<std::string> firstOne(const Grammar &g, const std::string &sym,
                               std::map<std::string, std::set<std::string>> &memo) {
    if (auto it = memo.find(sym); it != memo.end()) return it->second;
    std::set<std::string> out;
    if (isTerm(g, sym) || sym.empty()) {
        out.insert(sym);   // 空串符号 "" 表示 ε
        return out;
    }
    bool nullable = false;
    for (const auto &[lhs, rhs] : g.prods) {
        if (lhs != sym) continue;
        if (rhs.empty()) { nullable = true; continue; }
        bool allNullable = true;
        for (const auto &x : rhs) {
            std::set<std::string> f = firstOne(g, x, memo);
            for (const auto &t : f)
                if (!t.empty()) out.insert(t);
            if (!f.count("")) { allNullable = false; break; }
        }
        if (allNullable) nullable = true;
    }
    if (nullable) out.insert("");
    memo[sym] = out;
    return out;
}

}  // namespace

std::set<std::string> firstOfSeq(const Grammar &g, const std::vector<std::string> &seq,
                                 const std::string &tail) {
    static std::map<std::string, std::set<std::string>> memo;
    memo.clear();
    std::set<std::string> out;
    bool allNullable = true;
    auto feed = [&](const std::vector<std::string> &part) {
        for (const auto &x : part) {
            std::set<std::string> f = firstOne(g, x, memo);
            for (const auto &t : f)
                if (!t.empty()) out.insert(t);
            if (!f.count("")) { allNullable = false; return; }
        }
    };
    feed(seq);
    if (allNullable && !tail.empty()) feed({tail});
    if (out.empty()) out.insert("");   // 全可空 ⇒ ε
    return out;
}

// ---------- CLOSURE / GOTO ----------

namespace {

// CLOSURE：LR(1) 口径传播 lookahead——[A→α·Bβ, a] 为每个 B→γ 与 b∈FIRST(βa) 加项；
// la 为空串（LR(0)/SLR 口径）时不传播 lookahead。
std::set<Item> closure(const Grammar &g, std::set<Item> is) {
    for (bool ch = true; ch;) {
        ch = false;
        std::set<Item> add;
        for (const auto &it : is) {
            const auto &[lhs, rhs] = g.prods[it.prod];
            if (it.dot >= static_cast<int>(rhs.size())) continue;
            const std::string &b = rhs[it.dot];
            if (isTerm(g, b)) continue;
            std::vector<std::string> beta(rhs.begin() + it.dot + 1, rhs.end());
            std::set<std::string> las;
            if (it.la.empty()) las.insert("");   // LR(0)：无 lookahead
            else las = firstOfSeq(g, beta, it.la);
            for (size_t p = 0; p < g.prods.size(); ++p) {
                if (g.prods[p].first != b) continue;
                for (const auto &a : las) {
                    Item ni{static_cast<int>(p), 0, it.la.empty() ? "" : a};
                    if (!is.count(ni)) { add.insert(ni); ch = true; }
                }
            }
        }
        is.insert(add.begin(), add.end());
    }
    return is;
}

Core coreOf(const std::set<Item> &is) {
    Core c;
    for (const auto &it : is) c.insert({it.prod, it.dot});
    return c;
}

}  // namespace —— goTo 移出匿名区：本章仲裁器要重算移进候选（08 章原副本未导出）

// GOTO(I, X)：圆点移过 X 再闭包
std::set<Item> goTo(const Grammar &g, const std::set<Item> &is, const std::string &x) {
    std::set<Item> moved;
    for (const auto &it : is) {
        const auto &rhs = g.prods[it.prod].second;
        if (it.dot < static_cast<int>(rhs.size()) && rhs[it.dot] == x)
            moved.insert(Item{it.prod, it.dot + 1, it.la});
    }
    return moved.empty() ? moved : closure(g, std::move(moved));
}

namespace {  // 匿名区续

// 规范族：BFS；lr1=false 时为 LR(0) 族（SLR 用）
std::vector<std::set<Item>> collection(const Grammar &g, bool lr1) {
    std::vector<std::set<Item>> states;
    std::map<std::set<Item>, int> index;
    std::vector<std::set<Item>> work;
    auto push = [&](std::set<Item> s) -> int {
        auto it = index.find(s);
        if (it != index.end()) return it->second;
        index[s] = static_cast<int>(states.size());
        states.push_back(s);
        work.push_back(s);
        return static_cast<int>(states.size()) - 1;
    };
    push(closure(g, {{0, 0, lr1 ? "$" : ""}}));
    std::set<std::string> symbols = g.terms;
    symbols.insert(g.nonterms.begin(), g.nonterms.end());
    while (!work.empty()) {
        std::set<Item> cur = work.back();
        work.pop_back();
        for (const auto &x : symbols) {
            std::set<Item> nx = goTo(g, cur, x);
            if (!nx.empty()) push(std::move(nx));
        }
    }
    return states;
}

// 填表的公共骨架：遍历项集，移进项发 shift、归约项按 permit 发 reduce 许可证
// （SLR 的 permit=FOLLOW(A)，LR(1) 的 permit=项自身 lookahead）。
// coreLookup 非空时（LALR）：转移目标按"项集的核心"解析——合并态出发的 GOTO
// 只落在核心的某半边项集上，必须按核心回到合并态（同心态的 GOTO 同心）。
void fill(Table &t, const Grammar &g, const std::vector<std::set<Item>> &states,
          const std::map<std::string, std::set<std::string>> *permit,
          const std::map<Core, int> *coreLookup = nullptr) {
    t.states = states;
    std::map<std::set<Item>, int> index;
    for (size_t i = 0; i < states.size(); ++i) index[states[i]] = static_cast<int>(i);
    auto setAct = [&](int s, const std::string &a, Action act) {
        Action &cell = t.action[s][a];
        if (cell == Action{} || cell == act) { cell = act; return; }
        t.conflicts.push_back({s, a});   // 同格两异动作：记冲突，保留先到者
    };
    auto targetOf = [&](const std::set<Item> &nx) -> int {
        if (nx.empty()) return -1;   // 无此转移（如对 S' 的 GOTO）
        if (coreLookup) {
            auto cit = coreLookup->find(coreOf(nx));
            return cit == coreLookup->end() ? -1 : cit->second;
        }
        return index.at(nx);
    };
    for (size_t si = 0; si < states.size(); ++si) {
        for (const auto &it : states[si]) {
            const auto &[lhs, rhs] = g.prods[it.prod];
            if (it.dot < static_cast<int>(rhs.size())) {
                const std::string &x = rhs[it.dot];
                if (!isTerm(g, x)) continue;
                int tgt = targetOf(goTo(g, states[si], x));
                if (tgt >= 0)
                    setAct(static_cast<int>(si), x, Action{Action::Shift, tgt});
            } else if (it.prod == 0) {
                setAct(static_cast<int>(si), "$", Action{Action::Acc, -1});
            } else if (it.prod != 0) {
                // 归约许可证来源：SLR 用 FOLLOW(A)，LR(1) 用 lookahead
                if (permit) {
                    const auto &f = permit->at(lhs);
                    for (const auto &a : f) setAct(static_cast<int>(si), a, Action{Action::Reduce, it.prod});
                } else {
                    setAct(static_cast<int>(si), it.la, Action{Action::Reduce, it.prod});
                }
            }
        }
        for (const auto &b : g.nonterms) {
            int tgt = targetOf(goTo(g, states[si], b));
            if (tgt >= 0)
                t.gotos[static_cast<int>(si)][b] = tgt;
        }
    }
}

}  // namespace


Table buildLR1(const Grammar &g) {
    Table t;
    t.kind = "LR(1)";
    fill(t, g, collection(g, true), nullptr);
    // 记录核心分裂：同一核心对应多少个 LR(1) 状态
    for (size_t i = 0; i < t.states.size(); ++i) t.splits[coreOf(t.states[i])].push_back(static_cast<int>(i));
    return t;
}

Table buildLALR(const Grammar &g, const Table &lr1) {
    Table t;
    t.kind = "LALR(1)";
    // 1) 按核心分组合并，lookahead 求并
    std::map<Core, int> coreId;
    std::vector<std::set<Item>> merged;
    for (const auto &st : lr1.states) {
        Core c = coreOf(st);
        auto it = coreId.find(c);
        if (it == coreId.end()) {
            coreId[c] = static_cast<int>(merged.size());
            merged.push_back(st);
        } else {
            merged[it->second].insert(st.begin(), st.end());
        }
    }
    // 2) 用"核心 → 合并态"索引重建 GOTO/ACTION：转移按核心解析（见 fill 注释）
    fill(t, g, merged, nullptr, &coreId);
    return t;
}

ParseResult tableParse(const Grammar &g, const Table &t, const std::vector<std::string> &words) {
    ParseResult r;
    std::vector<int> stack{0};
    std::vector<std::string> input = words;
    input.push_back("$");
    size_t ip = 0;
    for (;;++r.steps) {
        if (r.steps > 1000) return r;   // 保险丝
        int s = stack.back();
        auto it = t.action.find(s);
        if (it == t.action.end() || !it->second.count(input[ip])) return r;   // 错误
        const Action &a = it->second.at(input[ip]);
        if (a.kind == Action::Shift) {
            stack.push_back(a.target);
            ++ip;
        } else if (a.kind == Action::Reduce) {
            const auto &rhs = g.prods[a.target].second;
            for (size_t k = 0; k < rhs.size(); ++k) stack.pop_back();
            int top = stack.back();
            auto git = t.gotos.find(top);
            if (git == t.gotos.end() || !git->second.count(g.prods[a.target].first)) return r;
            stack.push_back(git->second.at(g.prods[a.target].first));
        } else if (a.kind == Action::Acc) {
            r.accept = true;
            return r;
        } else {
            return r;
        }
    }
}

}  // namespace tip
