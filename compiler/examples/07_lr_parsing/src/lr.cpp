// file: src/lr.cpp
// 第 7 章配套：SLR 引擎实现。
#include "lr.hpp"

#include <cassert>
#include <sstream>

namespace tip {

SLR::SLR(const Grammar &g) : g(g) {
    // 增广文法：新产生式 0 号 = <start>' -> start。
    // 它的唯一使命是给“接受”一个可以识别的时机。
    aug.push_back({g.start + "'", {g.start}});
    for (const auto &p : g.prods) aug.push_back(p);
}

std::string SLR::showItem(const Item &it) const {
    const auto &p = aug[it.prod];
    std::ostringstream os;
    os << p.lhs << " ->";
    for (size_t k = 0; k < p.rhs.size(); ++k) {
        os << ' ';
        if (static_cast<int>(k) == it.dot) os << "· ";
        os << p.rhs[k];
    }
    if (static_cast<int>(p.rhs.size()) == it.dot) os << " ·";
    if (p.rhs.empty() && it.dot == 0) os << " ·";
    return os.str();
}

// ---------- CLOSURE（绿龙 Fig 6.5） ----------
// 点右边的非终结符“期望看到它推导的东西”，
// 于是它的所有产生式以点在最左端的形态加入。
// 绿龙提示用 ADDED[非终结符] 布尔表避免重复扫——
// 一旦某非终结符的全部产生式已加入，就不必再看它。
std::set<Item> SLR::closure(std::set<Item> i) const {
    std::map<std::string, bool> added;
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &it : i) {
            const auto &rhs = aug[it.prod].rhs;
            if (it.dot >= static_cast<int>(rhs.size())) continue;
            const std::string &B = rhs[it.dot];
            if (!g.isNonterm(B) || added[B]) continue;
            added[B] = true;
            for (size_t pi = 0; pi < aug.size(); ++pi)
                if (aug[pi].lhs == B) {
                    Item ni{static_cast<int>(pi), 0};
                    if (!i.count(ni)) { i.insert(ni); changed = true; }
                }
        }
    }
    return i;
}

std::set<Item> SLR::goTo(const std::set<Item> &i, const std::string &X) const {
    std::set<Item> moved;
    for (const auto &it : i) {
        const auto &rhs = aug[it.prod].rhs;
        if (it.dot < static_cast<int>(rhs.size()) && rhs[it.dot] == X)
            moved.insert({it.prod, it.dot + 1});
    }
    return moved;   // 调用方需要再取 closure
}

// ---------- ITEMS（绿龙 Fig 6.6）：规范 LR(0) 项集族 ----------
// 眼尖的读者会认出这就是第 5 章的子集构造：
// 项是 NFA 的状态（点移动=实边、点后非终结符=ε 扇出），
// CLOSURE 就是 ε 闭包，ITEMS 就是不动点扩张。
void SLR::buildItems() {
    states.clear();
    gotof.clear();
    states.push_back(closure({{0, 0}}));
    for (size_t si = 0; si < states.size(); ++si) {
        std::vector<std::string> syms = g.terms;
        for (const auto &n : g.nonterms) syms.push_back(n);
        for (const auto &X : syms) {
            std::set<Item> t = closure(goTo(states[si], X));
            if (t.empty()) continue;
            int idx = -1;
            for (size_t k = 0; k < states.size(); ++k)
                if (states[k] == t) { idx = static_cast<int>(k); break; }
            if (idx < 0) {
                states.push_back(t);
                idx = static_cast<int>(states.size()) - 1;
            }
            gotof[{static_cast<int>(si), X}] = idx;
        }
    }
}

// ---------- FOLLOW（SLR 规则 2 需要，算法与第 6 章相同） ----------
namespace {
void computeFirst(const std::vector<Production> &aug, const Grammar &g,
                  std::map<std::string, std::set<std::string>> &first) {
    for (const auto &A : g.nonterms) first[A] = {};
    auto firstOfSeq = [&](const std::vector<std::string> &beta) {
        std::set<std::string> out;
        bool allEps = true;
        for (const auto &x : beta) {
            std::set<std::string> fx;
            if (g.isTerm(x)) fx = {x};
            else if (first.count(x)) fx = first[x];
            for (const auto &t : fx)
                if (t != "ε") out.insert(t);
            if (!fx.count("ε")) { allEps = false; break; }
        }
        if (allEps) out.insert("ε");
        return out;
    };
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : aug) {
            if (!g.isNonterm(p.lhs)) continue;
            auto &F = first[p.lhs];
            size_t before = F.size();
            for (const auto &t : firstOfSeq(p.rhs)) F.insert(t);
            if (F.size() != before) changed = true;
        }
    }
}
}  // namespace

void SLR::buildTable(bool preferShift) {
    conflicts.clear();
    action.clear();
    // FOLLOW（用增广产生式一并算，起始符号的 FOLLOW 恒含 $）
    std::map<std::string, std::set<std::string>> first;
    computeFirst(aug, g, first);
    for (const auto &A : g.nonterms) follow[A] = {};
    follow[g.start].insert(LR_DOLLAR);
    bool changed = true;
    while (changed) {
        changed = false;
        for (const auto &p : aug) {
            for (size_t i = 0; i < p.rhs.size(); ++i) {
                const auto &B = p.rhs[i];
                if (!g.isNonterm(B)) continue;
                auto &FB = follow[B];
                size_t before = FB.size();
                std::vector<std::string> rest(p.rhs.begin() + i + 1, p.rhs.end());
                auto fr = [&] {
                    std::set<std::string> out;
                    bool allEps = true;
                    for (const auto &x : rest) {
                        std::set<std::string> fx;
                        if (g.isTerm(x)) fx = {x};
                        else if (first.count(x)) fx = first[x];
                        for (const auto &t : fx)
                            if (t != "ε") out.insert(t);
                        if (!fx.count("ε")) { allEps = false; break; }
                    }
                    if (allEps) out.insert("ε");
                    return out;
                }();
                for (const auto &t : fr)
                    if (t != "ε") FB.insert(t);
                if (fr.count("ε") || rest.empty())
                    for (const auto &t : follow[p.lhs]) FB.insert(t);
                if (FB.size() != before) changed = true;
            }
        }
    }
    // Algorithm 6.1 的六条规则：
    auto put = [&](int st, const std::string &a, Action act, const std::string &kind) {
        auto key = std::make_pair(st, a);
        auto it = action.find(key);
        if (it == action.end()) { action[key] = act; return; }
        if (it->second.kind == act.kind && it->second.target == act.target) return;
        // 冲突：记录；preferShift 时移进胜出。
        Conflict cf;
        cf.state = st;
        cf.look = a;
        std::vector<int> reds;
        if (it->second.kind == Act::Reduce) reds.push_back(it->second.target);
        if (act.kind == Act::Reduce) reds.push_back(act.target);
        cf.reduceProds = reds;
        cf.kind = kind;
        if (it->second.kind == Act::Shift) cf.shiftTarget = it->second.target;
        if (act.kind == Act::Shift) cf.shiftTarget = act.target;
        if (preferShift && act.kind == Act::Shift) {
            it->second = act;
            cf.resolution = "prefer-shift（最近 else）";
        } else if (preferShift && it->second.kind == Act::Shift) {
            cf.resolution = "prefer-shift（最近 else）";
        } else {
            cf.resolution = "保留先到者";
        }
        conflicts.push_back(cf);
    };
    for (size_t si = 0; si < states.size(); ++si) {
        int st = static_cast<int>(si);
        for (const auto &it : states[si]) {
            const auto &rhs = aug[it.prod].rhs;
            if (it.dot < static_cast<int>(rhs.size())) {
                const std::string &X = rhs[it.dot];
                if (g.isTerm(X)) {   // 规则 1：shift
                    Action a{Act::Shift, gotof.at({st, X})};
                    put(st, X, a, "shift-reduce");
                }
            } else {
                if (it.prod == 0) {   // 规则 3：accept
                    put(st, LR_DOLLAR, {Act::Accept, -1}, "accept");
                } else {              // 规则 2：对 FOLLOW(A) reduce
                    const std::string &A = aug[it.prod].lhs;
                    for (const auto &a : follow[A])
                        put(st, a, {Act::Reduce, it.prod}, "reduce-reduce");
                }
            }
        }
    }
}

// ---------- 移进-归约驱动（绿龙 Fig 6.2/6.4） ----------
SLR::RunResult SLR::run(const std::vector<std::string> &input,
                        std::ostringstream &os) const {
    std::vector<int> sstack = {0};          // 状态栈
    std::vector<std::string> sym;           // 符号栈（只作展示）
    size_t ip = 0;
    int step = 0;
    while (true) {
        int st = sstack.back();
        std::string a = ip < input.size() ? input[ip] : LR_DOLLAR;
        auto it = action.find({st, a});
        Action act = (it == action.end()) ? Action{} : it->second;
        // 打印 move 行
        os << "(" << ++step << ") " << stackText(sstack, sym)
           << " | " << inputText(input, ip) << " | ";
        switch (act.kind) {
        case Act::Shift:
            os << "shift " << act.target << "\n";
            sstack.push_back(act.target);
            sym.push_back(a);
            ++ip;
            break;
        case Act::Reduce: {
            const auto &p = aug[act.target];
            os << "reduce " << p.lhs << " ->";
            if (p.rhs.empty()) os << " ε";
            else for (const auto &x : p.rhs) os << ' ' << x;
            os << "\n";
            for (size_t k = 0; k < p.rhs.size(); ++k) { sstack.pop_back(); sym.pop_back(); }
            int nt = gotof.at({sstack.back(), p.lhs});
            sstack.push_back(nt);
            sym.push_back(p.lhs);
            break;
        }
        case Act::Accept:
            os << "accept\n";
            return {true, ""};
        case Act::Err:
            os << "error\n";
            return {false, "状态 " + std::to_string(st) + " 遇到 " + a + " 无动作"};
        }
    }
}

std::string SLR::stackText(const std::vector<int> &s,
                            const std::vector<std::string> &sym) const {
    std::ostringstream os;
    os << s[0];
    for (size_t k = 0; k < sym.size(); ++k)
        os << ' ' << sym[k] << ' ' << s[k + 1];
    return os.str();
}

std::string SLR::inputText(const std::vector<std::string> &input, size_t ip) const {
    std::ostringstream os;
    for (size_t k = ip; k < input.size(); ++k) os << input[k] << ' ';
    os << LR_DOLLAR;
    return os.str();
}

}  // namespace tip
