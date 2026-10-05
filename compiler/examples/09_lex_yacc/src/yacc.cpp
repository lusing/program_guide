// yacc 心脏实现。表构造完全复用 08 章副本（buildLR1/buildLALR），
// 本文件只做三件 08 章没有的事：值栈平行推进、优先级仲裁、嵌入动作改写。
#include "yacc.hpp"

#include <stdexcept>

namespace tip {

namespace {

bool isTerminal(const Grammar &g, const std::string &s) { return g.terms.count(s) > 0; }

}  // namespace

MiniYacc::MiniYacc(std::vector<YaccRule> rules, const std::string &startSym,
                   std::vector<std::string> terminals)
    : rules_(std::move(rules)) {
    for (size_t i = 0; i < rules_.size(); ++i)
        g_.nonterms.insert(rules_[i].lhs);   // 先收集 lhs：#chk 这类 ε 非终结符靠它放行
    for (size_t i = 0; i < rules_.size(); ++i)
        for (const auto &s : rules_[i].rhs)
            if (s.rfind("#", 0) == 0 && !g_.nonterms.count(s))
                throw std::runtime_error("MiniYacc: 嵌入动作须先经 rewriteEmbedded 展开: " + s);
    terminals.push_back("$");
    g_.terms.insert(terminals.begin(), terminals.end());
    g_.start = "S'";
    g_.prods.push_back({"S'", {startSym}});
    g_.nonterms.insert("S'");
    g_.nonterms.insert(startSym);
    for (const auto &r : rules_) {
        g_.prods.push_back({r.lhs, r.rhs});
        g_.nonterms.insert(r.lhs);
    }
    for (const auto &r : rules_)
        for (const auto &s : r.rhs)
            if (!isTerminal(g_, s) && !g_.nonterms.count(s))
                throw std::runtime_error("MiniYacc: 悬空符号 " + s);
    buildTable();
}

void MiniYacc::setPrec(const std::string &term, int level, YaccAssoc assoc) {
    prec_[term] = {level, assoc};
}

void MiniYacc::buildTable() {
    Table lr1 = buildLR1(g_);
    tab_ = buildLALR(g_, lr1);
    cstats_.raw = static_cast<int>(tab_.conflicts.size());
    // 仲裁不在此处：setPrec 的声明可能在构造后才到达（ensureResolved 惰性触发）。
    // 早期版本这里漏了一次 resolveConflicts()——账本被"无声明一遍 + 有声明一遍"
    // 双重计入，表动作正确而计数翻倍（§9.7.5 坑五的教训：删调用要删干净）。
}

// 产生式优先级 = %prec 覆盖，否则最右终结符的声明级（无则 0）——§5.5.3 规则。
int MiniYacc::prodPrecOf(int p) const {
    if (rules_[p].rulePrec > 0) return rules_[p].rulePrec;
    const auto &rhs = g_.prods[p + 1].second;   // +1 跳过增广产生式
    for (auto it = rhs.rbegin(); it != rhs.rend(); ++it) {
        if (!isTerminal(g_, *it)) continue;
        auto pi = prec_.find(*it);
        return pi == prec_.end() ? 0 : pi->second.first;
    }
    return 0;
}

void MiniYacc::resolveConflicts() {
    if (tab_.conflicts.empty()) return;
    // 状态定位表：goTo 的落点按项集相等找回编号（LALR 合并族仍封闭）。
    std::map<std::set<Item>, int> index;
    for (size_t i = 0; i < tab_.states.size(); ++i) index[tab_.states[i]] = static_cast<int>(i);

    std::set<std::pair<int, std::string>> seen;   // 同格多次入账只裁一次
    for (const auto &[s, a] : tab_.conflicts) {
        if (!seen.insert({s, a}).second) continue;
        // 候选 1：移进——重算 goTo(states[s], a)。
        int shiftTgt = -1;
        auto nx = goTo(g_, tab_.states[s], a);
        if (!nx.empty()) {
            auto it = index.find(nx);
            if (it != index.end()) shiftTgt = it->second;
        }
        // 候选 2：归约——态内 dot 到底、lookahead 覆盖 a 的项。
        std::vector<int> reduces;
        for (const auto &it : tab_.states[s]) {
            const auto &rhs = g_.prods[it.prod].second;
            if (it.prod == 0 || it.dot != static_cast<int>(rhs.size())) continue;
            if (it.la != a) continue;
            reduces.push_back(it.prod);
        }
        if (reduces.empty() && shiftTgt < 0) { ++cstats_.unresolved; continue; }
        if (reduces.size() >= 2) ++cstats_.ruleOrder;   // reduce/reduce：先声明者胜
        if (reduces.empty()) {                           // 纯 shift 之争：保留现状
            tab_.action[s][a] = Action{Action::Shift, shiftTgt};
            continue;
        }
        int best = reduces[0];                           // prods 升序即声明序
        if (shiftTgt < 0) {                              // 纯归约之争
            tab_.action[s][a] = Action{Action::Reduce, best};
            continue;
        }
        // shift/reduce 投票
        int tp = 0, pp = 0;
        YaccAssoc ta = YaccAssoc::None;
        auto pi = prec_.find(a);
        if (pi != prec_.end()) { tp = pi->second.first; ta = pi->second.second; }
        pp = prodPrecOf(best - 1);                       // rules_ 下标 = prod-1
        if (tp > 0 && pp > 0) {
            if (tp > pp) { tab_.action[s][a] = Action{Action::Shift, shiftTgt}; ++cstats_.byPrec; }
            else if (tp < pp) { tab_.action[s][a] = Action{Action::Reduce, best}; ++cstats_.byPrec; }
            else if (ta == YaccAssoc::Left) { tab_.action[s][a] = Action{Action::Reduce, best}; ++cstats_.byAssoc; }
            else if (ta == YaccAssoc::Right) { tab_.action[s][a] = Action{Action::Shift, shiftTgt}; ++cstats_.byAssoc; }
            else { tab_.action[s][a] = Action{Action::Shift, shiftTgt}; ++cstats_.defaultShift; }
        } else {
            tab_.action[s][a] = Action{Action::Shift, shiftTgt};   // 一方无级：缺省移进
            ++cstats_.defaultShift;
        }
    }
}

MiniYacc::RunResult MiniYacc::parse(
    const std::vector<std::pair<std::string, std::string>> &toks, bool runActions) {
    ensureResolved();
    RunResult r;
    std::vector<int> stateStack{0};
    std::vector<YaccValue> valueStack{YaccValue::empty()};
    size_t i = 0;
    std::string kind = i < toks.size() ? toks[i].first : "$";
    std::string text = i < toks.size() ? toks[i].second : "";
    // 步数口径与 08 章 tableGenerate 对齐：本轮完成才计数（for 头自增）。
    for (;; ++r.steps) {
        int s = stateStack.back();
        Action act;
        auto row = tab_.action.find(s);
        if (row != tab_.action.end()) {
            auto cell = row->second.find(kind);
            if (cell != row->second.end()) act = cell->second;
        }
        if (act.kind == Action::Err) return r;                    // 拒绝
        if (act.kind == Action::Acc) { r.accept = true; r.result = valueStack.back(); return r; }
        if (act.kind == Action::Shift) {
            stateStack.push_back(act.target);
            YaccValue v = YaccValue::empty();
            if (kind == "NUM") v = YaccValue::ofNum(std::stod(text));
            else if (kind == "ID") v = YaccValue::ofStr(text);
            valueStack.push_back(v);
            ++i;
            kind = i < toks.size() ? toks[i].first : "$";
            text = i < toks.size() ? toks[i].second : "";
        } else {                                                   // Reduce
            int p = act.target;
            const auto &rhs = g_.prods[p].second;
            std::vector<YaccValue> vals(valueStack.end() - static_cast<long>(rhs.size()),
                                       valueStack.end());
            stateStack.resize(stateStack.size() - rhs.size());
            valueStack.resize(valueStack.size() - rhs.size());
            const YaccRule &rule = rules_[p - 1];
            r.reduceLog.push_back(showProd(g_, p));
            YaccValue got;
            if (rule.action && runActions) {
                r.actionLog.push_back(rule.actionName);
                got = rule.action(vals);
            } else if (!rhs.empty()) {
                got = vals[0];                                     // 缺省 $$ = $1
            }
            int tgt = tab_.gotos.at(stateStack.back()).at(g_.prods[p].first);
            stateStack.push_back(tgt);
            valueStack.push_back(got);
        }
    }
}

std::pair<std::vector<YaccRule>, int> rewriteEmbedded(
    std::vector<YaccRule> rules,
    std::map<std::string, std::pair<YaccAction, std::string>> embeds) {
    int added = 0;
    std::set<std::string> emitted;
    for (auto &r : rules)
        for (auto &s : r.rhs) {
            if (s.rfind("#", 0) != 0) continue;
            if (!emitted.insert(s).second) continue;
            auto it = embeds.find(s);
            if (it == embeds.end())
                throw std::runtime_error("rewriteEmbedded: 占位符缺动作 " + s);
            YaccRule eps;
            eps.lhs = s;                       // 占位符名即 ε 非终结符名
            eps.rhs = {};
            eps.action = it->second.first;
            eps.actionName = it->second.second;
            rules.push_back(eps);
            ++added;
        }
    return {std::move(rules), added};
}

std::string showProd(const Grammar &g, int p) {
    const auto &[lhs, rhs] = g.prods[p];
    std::string s = std::to_string(p) + ": " + lhs + " → ";
    if (rhs.empty()) return s + "ε";
    for (size_t i = 0; i < rhs.size(); ++i) s += rhs[i] + (i + 1 < rhs.size() ? " " : "");
    return s;
}

}  // namespace tip
