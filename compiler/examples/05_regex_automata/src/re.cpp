// file: src/re.cpp
// 第 5 章配套：re.hpp 全部算法的实现。
#include "re.hpp"

#include <algorithm>
#include <cassert>
#include <sstream>

namespace tip {

// ---------- 语法树构造 ----------
std::unique_ptr<RE> RE::eps() {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Eps;
    return r;
}
std::unique_ptr<RE> RE::sym(char c) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Sym;
    r->ch = c;
    return r;
}
std::unique_ptr<RE> RE::alt(std::unique_ptr<RE> a, std::unique_ptr<RE> b) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Alt;
    r->lhs = std::move(a);
    r->rhs = std::move(b);
    return r;
}
std::unique_ptr<RE> RE::concat(std::unique_ptr<RE> a, std::unique_ptr<RE> b) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Concat;
    r->lhs = std::move(a);
    r->rhs = std::move(b);
    return r;
}
std::unique_ptr<RE> RE::star(std::unique_ptr<RE> a) {
    auto r = std::make_unique<RE>();
    r->kind = REKind::Star;
    r->lhs = std::move(a);
    return r;
}

// ---------- 正则串的递归下降解析 ----------
namespace {
struct REParser {
    const std::string &s;
    size_t i = 0;
    explicit REParser(const std::string &src) : s(src) {}

    [[noreturn]] void fail(const char *why) const {
        std::ostringstream os;
        os << "regex 位置 " << i << ": " << why;
        throw std::runtime_error(os.str());
    }

    std::unique_ptr<RE> expr() {
        auto t = term();
        while (i < s.size() && s[i] == '|') {
            ++i;
            t = RE::alt(std::move(t), term());
        }
        return t;
    }
    std::unique_ptr<RE> term() {
        if (i >= s.size() || s[i] == '|' || s[i] == ')')
            return RE::eps();           // 空并置 = ε（允许 "(a|)" 这类宽松写法）
        auto f = factor();
        while (i < s.size() && s[i] != '|' && s[i] != ')')
            f = RE::concat(std::move(f), factor());
        return f;
    }
    std::unique_ptr<RE> factor() {
        auto a = atom();
        while (i < s.size() && s[i] == '*') {
            ++i;
            a = RE::star(std::move(a)); // 连续星 a** 同样合法：等价于 a*
        }
        return a;
    }
    std::unique_ptr<RE> atom() {
        if (i >= s.size()) fail("意外结束");
        if (s[i] == '\\') {          // 转义：下一个字符一律按字面量处理
            ++i;
            if (i >= s.size()) fail("转义后意外结束");
            return RE::sym(s[i++]);
        }
        if (s[i] == '(') {
            ++i;
            auto e = expr();
            if (i >= s.size() || s[i] != ')') fail("缺右括号");
            ++i;
            return e;
        }
        if (s[i] == ')' || s[i] == '|') fail("缺操作数");
        return RE::sym(s[i++]);
    }
};
}  // namespace

std::unique_ptr<RE> parseRE(const std::string &pat) {
    REParser p(pat);
    auto re = p.expr();
    if (p.i != pat.size()) p.fail("尾部有多余字符");
    return re;
}

// ---------- Thompson 构造（Algorithm 3.2） ----------
namespace {
struct Builder {
    NFA n;

    int fresh() {
        n.st.emplace_back();
        return static_cast<int>(n.st.size()) - 1;
    }
    // 基础：单符号 a → 两个状态一条实边；ε → 两个状态一条 ε 边。
    // 归纳：R|S 与 R* 各加两个新状态、四条 ε 边；RS 把出口 ε 直连入口。
    // 每个部件“单一入口、单一出口、入口无入边、出口无出边”的
    // 不变式由构造本身维持——这正是归纳证明能成立的原因。
    void build(const RE &re, int &entry, int &exit_) {
        switch (re.kind) {
        case REKind::Eps: {
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, exit_, 0, -1, false};
            break;
        }
        case REKind::Sym: {
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {re.ch, exit_, 0, -1, false};
            break;
        }
        case REKind::Alt: {
            int e1, x1, e2, x2;
            build(*re.lhs, e1, x1);
            build(*re.rhs, e2, x2);
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, e1, 0, e2, false};
            n.st[x1] = {0, exit_, 0, -1, false};
            n.st[x2] = {0, exit_, 0, -1, false};
            break;
        }
        case REKind::Concat: {
            int e1, x1, e2, x2;
            build(*re.lhs, e1, x1);
            build(*re.rhs, e2, x2);
            // 绿龙原文：“把 N2 的入口识别为 N1 的出口，后者消失”——
            // 状态合并而不是 ε 直连，这正是书上例子状态数更少的原因。
            // 入口不变式保证没有边指向 e2 的“内部”，只需全局改指。
            n.st[x1] = n.st[e2];   // x1 继承 e2 的（至多两条）出边
            for (auto &q : n.st) {
                if (q.to1 == e2) q.to1 = x1;
                if (q.to2 == e2) q.to2 = x1;
            }
            entry = e1;
            exit_ = x2;
            break;
        }
        case REKind::Star: {
            int e1, x1;
            build(*re.lhs, e1, x1);
            entry = fresh();
            exit_ = fresh();
            n.st[entry] = {0, e1, 0, exit_, false};
            n.st[x1] = {0, e1, 0, exit_, false};
            break;
        }
        }
    }
};
}  // namespace

NFA thompson(const RE &re) {
    Builder b;
    int entry, exit_;
    b.build(re, entry, exit_);
    b.n.st[exit_].accept = true;
    b.n.start = entry;
    b.n.finish = exit_;
    // 压实：concat 的状态合并会留下不可达的孤儿入口，
    // 从 start 做一次可达性重编号，状态数才与绿龙例子的口径一致。
    NFA &n = b.n;
    std::vector<int> num(n.st.size(), -1);
    std::vector<int> stack = {n.start};
    num[n.start] = 0;
    int cnt = 1;
    while (!stack.empty()) {
        int s = stack.back();
        stack.pop_back();
        for (int t : {n.st[s].to1, n.st[s].to2}) {
            if (t != -1 && num[t] == -1) {
                num[t] = cnt++;
                stack.push_back(t);
            }
        }
    }
    NFA packed;
    packed.st.resize(cnt);
    for (int s = 0; s < static_cast<int>(n.st.size()); ++s)
        if (num[s] != -1) {
            packed.st[num[s]] = n.st[s];
            auto &st = packed.st[num[s]];
            if (st.to1 != -1) st.to1 = num[st.to1];
            if (st.to2 != -1) st.to2 = num[st.to2];
        }
    packed.start = 0;                       // 重编号从 start 出发，start 必为 0
    packed.finish = num[n.finish];
    return packed;
}

// ---------- ε 闭包与子集构造（Algorithm 3.1） ----------
namespace {
// ε-CLOSURE(T)：从 T 出发只沿 ε 边可达的状态集（含 T 自身）。
// 绿龙 Fig 3.9 的栈式搜索——它就是第 24 章工作表算法的袖珍版。
std::set<int> epsClosure(const NFA &n, const std::set<int> &t) {
    std::set<int> got = t;
    std::vector<int> stack(t.begin(), t.end());
    while (!stack.empty()) {
        int s = stack.back();
        stack.pop_back();
        const auto &st = n.st[s];
        if (st.sym1 == 0 && st.to1 != -1 && !got.count(st.to1)) {
            got.insert(st.to1);
            stack.push_back(st.to1);
        }
        if (st.sym2 == 0 && st.to2 != -1 && !got.count(st.to2)) {
            got.insert(st.to2);
            stack.push_back(st.to2);
        }
    }
    return got;
}
}  // namespace

DFA subset(const NFA &n, const std::set<char> &alphabet,
           const std::vector<int> &stateClass) {
    auto cls = [&](int q) -> int {
        if (!stateClass.empty()) return stateClass[q];
        return n.st[q].accept ? 1 : 0;
    };
    DFA d;
    std::map<std::set<int>, int> id;
    std::vector<std::set<int>> work;
    auto nameOf = [&](const std::set<int> &s) {
        auto [it, fresh] = id.emplace(s, static_cast<int>(id.size()));
        if (fresh) {
            d.trans.emplace_back();
            d.color.push_back(0);
            work.push_back(s);
        }
        return it->second;
    };
    d.start = nameOf(epsClosure(n, {n.start}));
    // 只沿实符号转移扩张；ε 已被闭包吸收。
    for (size_t wi = 0; wi < work.size(); ++wi) {
        int cs = id.at(work[wi]);
        for (char c : alphabet) {
            std::set<int> next;
            for (int q : work[wi]) {
                const auto &st = n.st[q];
                if (st.sym1 == c && st.to1 != -1) next.insert(st.to1);
                if (st.sym2 == c && st.to2 != -1) next.insert(st.to2);
            }
            if (next.empty()) continue;
            nameOf(epsClosure(n, next));
            int t = id.at(epsClosure(n, next));
            d.trans[cs][c] = t;
        }
    }
    // 接受类：子集中出现的最小正类（最高优先级）。
    for (const auto &[sub, s] : id) {
        int best = 0;
        for (int q : sub)
            if (cls(q) > 0 && (best == 0 || cls(q) < best)) best = cls(q);
        d.color[s] = best;
    }
    return d;
}

// ---------- 最小化（Algorithm 3.3） ----------
DFA minimize(const DFA &d, const std::set<char> &alphabet) {
    // 初试分割按 color 分组：空串 ε 本身就能区分接受与非接受，
    // 不同优先级的接受态也必须从第一轮起就分居两组。
    auto countGroups = [](const std::vector<int> &g) {
        return static_cast<size_t>(*std::max_element(g.begin(), g.end()) + 1);
    };
    std::vector<int> group(d.states());
    {
        std::map<int, int> colorToGroup;
        for (int s = 0; s < d.states(); ++s) {
            auto [it, fresh] = colorToGroup.emplace(d.color[s],
                                                    static_cast<int>(colorToGroup.size()));
            group[s] = it->second;
        }
    }
    // 反复按“全部输入符号都落进同一组”细化，直到组数不再增长。
    // 签名以旧组号开头，因此每轮只会分裂、不会合并——
    // 单调有界，循环必然停止（与第 23 章不动点的终止论证同型）。
    while (true) {
        std::map<std::pair<int, std::vector<std::pair<char, int>>>, int> sigToGroup;
        std::vector<int> next(d.states());
        for (int s = 0; s < d.states(); ++s) {
            std::vector<std::pair<char, int>> sig;
            sig.reserve(alphabet.size());
            for (char c : alphabet) {
                auto it = d.trans[s].find(c);
                int t = (it == d.trans[s].end()) ? -1 : it->second;
                sig.emplace_back(c, t < 0 ? -1 : group[t]);
            }
            auto [it, fresh] = sigToGroup.emplace(std::make_pair(group[s], sig),
                                                  static_cast<int>(sigToGroup.size()));
            next[s] = it->second;
        }
        if (sigToGroup.size() == countGroups(group)) break;   // 稳定
        group = next;
    }
    // 重建：每组取一个代表态（编号最小者），重定向所有转移。
    int nGroups = static_cast<int>(countGroups(group));
    std::vector<int> rep(nGroups, -1);
    for (int s = 0; s < d.states(); ++s)
        if (rep[group[s]] == -1) rep[group[s]] = s;
    DFA m;
    m.trans.assign(nGroups, {});
    m.color.assign(nGroups, 0);
    m.start = group[d.start];
    for (int g = 0; g < nGroups; ++g) {
        int s = rep[g];
        m.color[g] = d.color[s];
        for (char c : alphabet) {
            auto it = d.trans[s].find(c);
            if (it != d.trans[s].end()) m.trans[g][c] = group[it->second];
        }
    }
    return m;
}

// ---------- scanner ----------
Scanner::Scanner(std::vector<TokenRule> rules, std::set<char> alphabet)
    : rules_(std::move(rules)), alpha_(std::move(alphabet)) {
    // 多模式并联：公共起点只留两条 ε 出边位（Thompson 的形状约定），
    // 因此像表达式 a|b|c|d 一样做“两两合并”的平衡树：
    // 规则 k 的入口挂到树的第 k 个叶子上，树根是整个大 NFA 的入口。
    std::vector<NFA> parts;
    std::vector<int> partStart;
    for (const auto &r : rules_) {
        NFA one = thompson(*parseRE(r.pat));
        partStart.push_back(one.start);     // 部件入口要存“部件内的编号”
        parts.push_back(std::move(one));
    }
    NFA big;
    auto fresh = [&]() {
        big.st.emplace_back();
        nfaStateRule_.push_back(-1);
        return static_cast<int>(big.st.size()) - 1;
    };
    auto offset = [&](NFA &host, int idx, int base) {
        for (auto &st : host.st) {
            if (st.to1 != -1) st.to1 += base;
            if (st.to2 != -1) st.to2 += base;
        }
        (void)idx;
    };
    // 逐个搬入并改相对编号；接受态记录所属规则（0 起的最高优先级）。
    std::vector<int> shiftedRoots;
    for (size_t k = 0; k < parts.size(); ++k) {
        int base = static_cast<int>(big.st.size());
        offset(parts[k], static_cast<int>(k), base);
        for (size_t q = 0; q < parts[k].st.size(); ++q) {
            big.st.push_back(parts[k].st[q]);
            nfaStateRule_.push_back(parts[k].st[q].accept ? static_cast<int>(k) : -1);
        }
        shiftedRoots.push_back(base + partStart[k]);
    }
    // 平衡树式并联：每合并两棵子树加一个 ε 分叉状态。
    while (shiftedRoots.size() > 1) {
        std::vector<int> next;
        for (size_t i = 0; i < shiftedRoots.size(); i += 2) {
            if (i + 1 < shiftedRoots.size()) {
                int join = fresh();
                big.st[join] = {0, shiftedRoots[i], 0, shiftedRoots[i + 1], false};
                next.push_back(join);
            } else {
                next.push_back(shiftedRoots[i]);
            }
        }
        shiftedRoots = next;
    }
    big.start = shiftedRoots[0];
    // NFA 态着色：规则号+1（0 仍表示非接受）。
    std::vector<int> stateClass;
    for (int k : nfaStateRule_) stateClass.push_back(k < 0 ? 0 : k + 1);
    dfa_ = minimize(subset(big, alpha_, stateClass), alpha_);
}

std::vector<std::string> Scanner::lex(const std::string &src) const {
    std::vector<std::string> out;
    size_t i = 0;
    while (i < src.size()) {
        if (src[i] == ' ' || src[i] == '\n' || src[i] == '\t' || src[i] == '\r') {
            ++i;
            continue;
        }
        int s = dfa_.start;
        size_t j = i;
        size_t lastAcc = std::string::npos;
        int lastColor = 0;
        if (dfa_.color[s] > 0) { lastAcc = i; lastColor = dfa_.color[s]; }
        while (j < src.size()) {
            auto it = dfa_.trans[s].find(src[j]);
            if (it == dfa_.trans[s].end()) break;
            s = it->second;
            ++j;
            if (dfa_.color[s] > 0) { lastAcc = j; lastColor = dfa_.color[s]; }
        }
        if (lastAcc == std::string::npos) {
            std::ostringstream os;
            os << "ERR('" << src[i] << "')";
            out.push_back(os.str());
            ++i;
        } else {
            std::ostringstream os;
            os << rules_[lastColor - 1].name << "('" << src.substr(i, lastAcc - i) << "')";
            out.push_back(os.str());
            i = lastAcc;
        }
    }
    return out;
}

std::string Scanner::stats() const {
    std::ostringstream os;
    os << "rules=" << rules_.size() << " alphabet=" << alpha_.size()
       << " dfa_states=" << dfa_.states();
    return os.str();
}

}  // namespace tip
