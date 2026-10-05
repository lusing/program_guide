#include "init.hpp"

#include <algorithm>
#include <deque>
#include <sstream>

#include "pretty.hpp"

namespace tip {
namespace {

// 表达式中出现的变量（与第 33 章的 exprVars 同型，本章自带一份以保持自包含）。
std::set<std::string> usesOf(const Expr *e) {
    std::set<std::string> r;
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        r.insert(x->name);
    } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
        std::set<std::string> l = usesOf(x->l.get());
        r.insert(l.begin(), l.end());
        std::set<std::string> rr = usesOf(x->r.get());
        r.insert(rr.begin(), rr.end());
    } else if (const auto *x = dynamic_cast<const CallE *>(e)) {
        for (const auto &a : x->args) {
            std::set<std::string> s = usesOf(a.get());
            r.insert(s.begin(), s.end());
        }
    }
    return r;  // IntLit/InputE 不读变量
}

// 语句读取了哪些变量（警告定位用：赋值看右值，输出/返回看表达式，分支看条件）。
std::set<std::string> stmtUses(const Stmt *s) {
    if (const auto *a = dynamic_cast<const AssignS *>(s))
        return usesOf(a->value.get());
    if (const auto *o = dynamic_cast<const OutputS *>(s)) return usesOf(o->e.get());
    if (const auto *r = dynamic_cast<const ReturnS *>(s)) return usesOf(r->e.get());
    if (const auto *w = dynamic_cast<const WhileS *>(s)) return usesOf(w->cond.get());
    if (const auto *i = dynamic_cast<const IfS *>(s)) return usesOf(i->cond.get());
    return {};
}

std::string joinSet(const std::set<std::string> &s) {
    if (s.empty()) return "{}";
    std::ostringstream out;
    out << "{";
    bool first = true;
    for (const std::string &v : s) {
        if (!first) out << ",";
        out << v;
        first = false;
    }
    out << "}";
    return out.str();
}

}  // namespace

InitResult runInitAnalysis(const Cfg &cfg, const ProgramA &program) {
    InitResult res;

    // 每个函数的边界条件：声明的局部变量出发时"可能未初始化"，
    // 参数视为已初始化（调用方必然提供实参），所以不在集合里。
    std::map<const FunCfg *, std::set<std::string>> entryState;
    for (size_t i = 0; i < cfg.funs.size(); ++i) {
        const FunCfg &fc = cfg.funs[i];
        const FunDecl &fd = *program.funs[i];
        std::set<std::string> s(fd.vars.begin(), fd.vars.end());
        for (const std::string &p : fd.params) s.erase(p);
        entryState[&fc] = s;
    }

    for (const FunCfg &fc : cfg.funs) {
        // 邻接表：succ[p] = 前向流后继。
        std::map<int, std::vector<int>> preds, succs;
        for (const auto &[a, b] : fc.edges) {
            preds[b].push_back(a);
            succs[a].push_back(b);
        }

        // worklist 不动点：may 分析从空集出发，边界点带函数入口状态。
        std::map<int, std::set<std::string>> out;
        std::deque<int> wl;
        std::set<int> inQ;
        for (const auto &[id, node] : fc.nodes) {
            wl.push_back(id);
            inQ.insert(id);
        }
        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            inQ.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            // 流入 = 各前驱流出状态之并（may）；无前驱时边界 = 入口状态。
            std::set<std::string> in;
            auto pit = preds.find(p);
            if (pit != preds.end()) {
                for (int q : pit->second) {
                    const std::set<std::string> &qs = out[q];
                    in.insert(qs.begin(), qs.end());
                }
            } else {
                in = entryState[&fc];
            }
            res.inState[p] = in;

            // 传递函数：赋值 x = e 时 (S ∖ {x}) ∪ ({x} 若 e 读到 S 中变量)；
            // 其余语句原样传递。
            std::set<std::string> o = in;
            if (const auto *a = dynamic_cast<const AssignS *>(node.stmt))
                if (const auto *t = dynamic_cast<const VarRef *>(a->target.get())) {
                    o.erase(t->name);
                    std::set<std::string> rhs = usesOf(a->value.get());
                    for (const std::string &v : rhs)
                        if (in.count(v)) {
                            o.insert(t->name);  // 污染：右值可能未初始化
                            break;
                        }
                }
            out[p] = o;

            // 状态变化才重算后继（单调保证有界）。
            auto prev = res.outState.find(p);
            if (prev == res.outState.end() || prev->second != o) {
                res.outState[p] = o;
                auto sit = succs.find(p);
                if (sit != succs.end())
                    for (int q : sit->second)
                        if (!inQ.count(q)) {
                            wl.push_back(q);
                            inQ.insert(q);
                        }
            }
        }

        // 不动点之后统一收集警告：语句读取的任何变量 ∈ 流入状态即为
        // "存在一条路径先读后写"。
        for (const auto &[id, node] : fc.nodes) {
            if (!node.stmt) continue;
            std::set<std::string> uses = stmtUses(node.stmt);
            std::set<std::string> bad;
            for (const std::string &v : uses)
                if (res.inState[id].count(v)) bad.insert(v);
            if (bad.empty()) continue;
            std::ostringstream w;
            w << "node " << id << ": " << printStmtLine(*node.stmt)
              << "  possibly uninitialized:";
            for (const std::string &v : bad) w << " " << v;
            res.warnings.push_back(w.str());
        }
    }
    return res;
}

std::string printInit(const Cfg &cfg, const ProgramA & /*program*/,
                      const InitResult &r) {
    std::ostringstream out;
    out << "== possibly-uninitialized (forward, may) ==\n";
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt)
                out << " " << printStmtLine(*node.stmt);
            out << ": in " << joinSet(r.inState.at(id))
                << " out " << joinSet(r.outState.at(id)) << "\n";
        }
    }
    out << "-- warnings --\n";
    if (r.warnings.empty()) {
        out << "  (none)\n";
    } else {
        for (const std::string &w : r.warnings) out << "  " << w << "\n";
    }
    return out.str();
}

}  // namespace tip
