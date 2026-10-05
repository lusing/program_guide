#include "dfa.hpp"

#include <deque>
#include <sstream>

#include "pretty.hpp"

namespace tip {
namespace {

std::set<std::string> collectVars(const Expr *e) {
    std::set<std::string> r;
    if (const auto *x = dynamic_cast<const IntLit *>(e)) {
        (void)x;
    } else if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        r.insert(x->name);
    } else if (dynamic_cast<const InputE *>(e)) {
        r.insert("input");
    } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
        std::set<std::string> l = collectVars(x->l.get());
        r.insert(l.begin(), l.end());
        std::set<std::string> rr = collectVars(x->r.get());
        r.insert(rr.begin(), rr.end());
    } else if (const auto *x = dynamic_cast<const CallE *>(e)) {
        for (const auto &a : x->args) {
            std::set<std::string> s = collectVars(a.get());
            r.insert(s.begin(), s.end());
        }
    }
    return r;
}

// 子式文本（供可用/非常忙的"因子"）：把 (a+b)*c 记成 ((a+b)*c) 的名字。
std::string termText(const Expr *e) {
    std::string out;
    if (const auto *x = dynamic_cast<const IntLit *>(e)) {
        out = std::to_string(x->v);
    } else if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        out = x->name;
    } else if (dynamic_cast<const InputE *>(e)) {
        out = "input";
    } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
        static const char *op[] = {"+", "-", "*", "/", ">", "=="};
        out = "(" + termText(x->l.get()) + op[static_cast<int>(x->op)] +
              termText(x->r.get()) + ")";
    }
    return out;
}

std::set<std::string> collectTerms(const Expr *e) {
    std::set<std::string> r;
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        std::set<std::string> l = collectTerms(x->l.get());
        r.insert(l.begin(), l.end());
        std::set<std::string> rr = collectTerms(x->r.get());
        r.insert(rr.begin(), rr.end());
        r.insert(termText(e));
    }
    return r;
}

}  // namespace

std::set<std::string> exprVars(const Expr *e) { return collectVars(e); }
std::string assignTargetName(const Stmt *s) {
    if (const auto *a = dynamic_cast<const AssignS *>(s))
        if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
            return t->name;
    return "";
}
std::set<std::string> exprSubTerms(const Expr *e) { return collectTerms(e); }
const Expr *stmtExpr(const Stmt *s) {
    if (const auto *a = dynamic_cast<const AssignS *>(s)) return a->value.get();
    if (const auto *o = dynamic_cast<const OutputS *>(s)) return o->e.get();
    if (const auto *r = dynamic_cast<const ReturnS *>(s)) return r->e.get();
    if (const auto *w = dynamic_cast<const WhileS *>(s)) return w->cond.get();
    if (const auto *i = dynamic_cast<const IfS *>(s)) return i->cond.get();
    return nullptr;
}

std::map<int, FactSet> runDfa(const Cfg &cfg, const DfaSpec &spec) {
    std::map<int, FactSet> cur;  // 每点"流出"状态（沿信息流方向施加 gen/kill 后）

    for (const FunCfg &fc : cfg.funs) {
        // 邻接表按分析方向取：flow[p]=信息流方向上为 p 供状态的前驱点，
        // flowSucc[p]=状态变化时需要重算的后继点。
        std::map<int, std::vector<int>> flow, flowSucc;
        for (const auto &[a, b] : fc.edges) {
            if (spec.forward) {
                flow[b].push_back(a);
                flowSucc[a].push_back(b);
            } else {
                flow[a].push_back(b);
                flowSucc[b].push_back(a);
            }
        }

        // 边界点：前向=entry，逆向=exit。
        const int boundary = spec.forward ? fc.entry : fc.exitNode;

        // must 分析的非边界点初始为全集；全集无法枚举时取"本函数全部
        // 语句 gen 因子之并"作为可表示的全集（有限因子假设）。
        FactSet universe;
        if (!spec.may)
            for (const auto &[id, node] : fc.nodes)
                if (node.stmt) {
                    std::set<std::string> g = spec.gen(node.stmt);
                    universe.insert(g.begin(), g.end());
                }

        // 初始化：may 从空集出发；must 的非边界点从全集出发、边界为空。
        // 全部点先入队一遍，保证初值无一被跳过。
        std::deque<int> wl;
        std::set<int> inQ;
        for (const auto &[id, node] : fc.nodes) {
            FactSet init;
            if (!spec.may && id != boundary) init = universe;
            cur[id] = init;
            wl.push_back(id);
            inQ.insert(id);
        }

        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            inQ.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            // 合并信息流前驱的流出状态（may=并，must=交；无前驱时取幺元）。
            FactSet merged;
            bool first = true;
            auto fit = flow.find(p);
            if (fit != flow.end()) {
                for (int q : fit->second) {
                    const FactSet &qs = cur[q];
                    if (first) {
                        merged = qs;
                        first = false;
                    } else if (spec.may) {
                        merged.insert(qs.begin(), qs.end());
                    } else {
                        FactSet inter;
                        for (const std::string &f : qs)
                            if (merged.count(f)) inter.insert(f);
                        merged = inter;
                    }
                }
            }

            // 施加本点 gen/kill：may=先 kill 后 gen（并）；must=保留 ∖kill 再补 gen。
            FactSet out = merged;
            if (node.stmt) {
                FactSet g = spec.gen(node.stmt);
                FactSet k = spec.kill(node.stmt);
                if (spec.may) {
                    for (const std::string &f : k) out.erase(f);
                    for (const std::string &f : g) out.insert(f);
                } else {
                    FactSet keep;
                    for (const std::string &f : out)
                        if (!k.count(f)) keep.insert(f);
                    keep.insert(g.begin(), g.end());
                    out = std::move(keep);
                }
            }

            // 只有变化才重算信息流后继（单调框架保证有界）。
            if (out != cur[p]) {
                cur[p] = out;
                auto sit = flowSucc.find(p);
                if (sit != flowSucc.end())
                    for (int s : sit->second)
                        if (!inQ.count(s)) {
                            wl.push_back(s);
                            inQ.insert(s);
                        }
            }
        }
    }
    return cur;
}

std::string printDfa(const Cfg &cfg, const std::map<int, FactSet> &result,
                     const DfaSpec &spec) {
    std::ostringstream out;
    out << "== " << spec.name << " ==\n";
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt) {
                if (const auto *w = dynamic_cast<const WhileS *>(node.stmt))
                    out << " branch  while " << printExpr(w->cond.get());
                else if (const auto *i = dynamic_cast<const IfS *>(node.stmt))
                    out << " branch  if " << printExpr(i->cond.get());
                else
                    out << " " << printStmtLine(*node.stmt);
            }
            out << ':';
            const FactSet &fs = result.at(id);
            if (fs.empty()) {
                out << " {}\n";
                continue;
            }
            out << " {";
            bool first = true;
            for (const std::string &f : fs) {
                if (!first) out << ",";
                out << f;
                first = false;
            }
            out << "}\n";
        }
    }
    return out.str();
}

}  // namespace tip
