#include "path.hpp"

#include <algorithm>
#include <set>
#include <sstream>

#include "pretty.hpp"
#include "widen.hpp"

namespace tip {
namespace {

// 分支节点携带的 cond 表达式（与第 31 章 widen.cpp 同一份局部重建）。
const Expr *condOf(const Stmt *s) {
    if (const auto *w = dynamic_cast<const WhileS *>(s)) return w->cond.get();
    if (const auto *i = dynamic_cast<const IfS *>(s)) return i->cond.get();
    return nullptr;
}

// CFG 构造器编号/连线规则的局部重建：拿到每个分支真/假边目标。
struct BranchEdges {
    std::map<int, int> trueOf, falseOf;
};

class LocalWiring {
public:
    BranchEdges run(const ProgramA &program) {
        for (const auto &fun : program.funs) {
            next_ = 2;
            id_.clear();
            number(fun->body.get());
            const int retId = next_++;
            (void)retId;
            wire(fun->body.get(), {retId});
        }
        return edges_;
    }

private:
    BranchEdges edges_;
    int next_ = 2;
    std::map<const Stmt *, int> id_;

    void number(const Stmt *s) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            for (const auto &x : b->ss) number(x.get());
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            id_[x] = next_++;
            number(x->then.get());
            if (x->els) number(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            id_[x] = next_++;
            number(x->body.get());
            return;
        }
        if (dynamic_cast<const AssignS *>(s) || dynamic_cast<const OutputS *>(s))
            id_[s] = next_++;
    }

    std::vector<int> wire(const Stmt *s, std::vector<int> succ) {
        if (const auto *b = dynamic_cast<const BlockS *>(s)) {
            std::vector<int> cur = succ;
            for (auto it = b->ss.rbegin(); it != b->ss.rend(); ++it)
                cur = wire(it->get(), cur);
            return cur;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            const int n = id_.at(x);
            std::vector<int> targets = wireOrSelf(x->then.get(), succ);
            edges_.trueOf[n] = targets[0];
            std::vector<int> rest;
            if (x->els)
                rest = wireOrSelf(x->els.get(), succ);
            else
                rest = succ;
            edges_.falseOf[n] = rest[0];
            return {n};
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            const int n = id_.at(x);
            std::vector<int> bodyEntries = wireOrSelf(x->body.get(), {n});
            edges_.trueOf[n] = bodyEntries[0];
            edges_.falseOf[n] = succ[0];
            return {n};
        }
        return {id_.at(s)};
    }
    std::vector<int> wireOrSelf(const Stmt *s, std::vector<int> succ) {
        std::vector<int> r = wire(s, succ);
        if (r.empty()) r = succ;
        return r;
    }
};

// 收集表达式中的全部除法子式（含嵌套）。
void collectDivs(const Expr *e, std::vector<const Binop *> &out) {
    if (const auto *b = dynamic_cast<const Binop *>(e)) {
        collectDivs(b->l.get(), out);
        collectDivs(b->r.get(), out);
        if (b->op == BOp::Div) out.push_back(b);
    }
}

void collectDivsStmt(const Stmt *s, std::vector<const Binop *> &out) {
    if (const auto *a = dynamic_cast<const AssignS *>(s)) {
        collectDivs(a->value.get(), out);
    } else if (const auto *o = dynamic_cast<const OutputS *>(s)) {
        collectDivs(o->e.get(), out);
    } else if (const auto *r = dynamic_cast<const ReturnS *>(s)) {
        collectDivs(r->e.get(), out);
    } else if (const auto *w = dynamic_cast<const WhileS *>(s)) {
        collectDivs(w->cond.get(), out);
    } else if (const auto *i = dynamic_cast<const IfS *>(s)) {
        collectDivs(i->cond.get(), out);
    }
}

}  // namespace

PathResult solveInterval(const Cfg &cfg, const ProgramA &program,
                         int maxRounds, bool refineOnEdges) {
    Lattice<Iv> lat = ivLattice();
    PathResult res;

    std::set<int> widenPoints;
    for (const FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes)
            if (dynamic_cast<const WhileS *>(node.stmt))
                widenPoints.insert(id);

    BranchEdges be = LocalWiring().run(program);
    const FunCfg &fc = cfg.funs[0];

    struct PredEdge {
        int node;
        bool refine;
        bool taken;
    };
    std::map<int, std::vector<PredEdge>> preds;
    for (const auto &[a, b] : fc.edges) {
        PredEdge pe{a, false, true};
        if (refineOnEdges) {
            if (be.trueOf.count(a) && be.trueOf[a] == b)
                pe = PredEdge{a, true, true};
            if (be.falseOf.count(a) && be.falseOf[a] == b)
                pe = PredEdge{a, true, false};
        }
        preds[b].push_back(pe);
    }

    auto computeIn = [&](int p, const std::map<int, IvEnv> &out) {
        IvEnv in;
        auto pit = preds.find(p);
        if (pit != preds.end()) {
            for (const PredEdge &pe : pit->second) {
                IvEnv piece;
                auto it = out.find(pe.node);
                if (it != out.end()) piece = it->second;
                if (pe.refine)
                    piece = refineOnBranch(condOf(fc.nodes.at(pe.node).stmt),
                                           piece, pe.taken);
                for (const auto &[k, v] : piece)
                    in[k] = lat.join(in.count(k) ? in[k] : lat.bot(), v);
            }
        }
        return in;
    };

    std::map<int, IvEnv> out;
    for (int round = 0; round < maxRounds; ++round) {
        bool changed = false;
        for (const auto &[id, node] : fc.nodes) {
            IvEnv in = computeIn(id, out);
            for (const std::string &p : program.funs[0]->params)
                in[p] = Iv{INT_MIN, INT_MAX};

            if (widenPoints.count(id)) {
                auto prev = out.find(id);
                if (prev != out.end())
                    for (auto &[k, v] : in) {
                        Iv pv =
                            prev->second.count(k) ? prev->second.at(k) : lat.bot();
                        v = widen(pv, v);
                    }
            }

            IvEnv o = in;
            if (const auto *a = dynamic_cast<const AssignS *>(node.stmt))
                if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
                    o[t->name] = evalIv(a->value.get(), in);

            if (out.count(id) == 0 || !(out[id] == o)) {
                out[id] = o;
                changed = true;
            }
        }
        res.rounds = round + 1;
        if (!changed) {
            res.converged = true;
            break;
        }
    }
    res.out = out;
    return res;
}

std::vector<std::string> divZeroWarnings(const Cfg &cfg,
                                         const std::map<int, IvEnv> &out) {
    std::vector<std::string> warnings;
    for (const FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes) {
            if (!node.stmt) continue;
            std::vector<const Binop *> divs;
            collectDivsStmt(node.stmt, divs);
            const IvEnv &env = out.at(id);
            for (const Binop *d : divs) {
                Iv den = evalIv(d->r.get(), env);
                bool containsZero = !(den.lo > den.hi) && den.lo <= 0 &&
                                    den.hi >= 0;
                if (containsZero) {
                    std::ostringstream line;
                    line << "node " << id << ": divisor "
                         << printExpr(d->r.get()) << " in " << ivText(den)
                         << " contains 0 — possible division by zero";
                    warnings.push_back(line.str());
                }
            }
        }
    return warnings;
}

std::vector<std::string> outputPredictions(const Cfg &cfg,
                                           const std::map<int, IvEnv> &out) {
    std::vector<std::string> lines;
    for (const FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes) {
            const auto *o = dynamic_cast<const OutputS *>(node.stmt);
            if (!o) continue;
            Iv pred = evalIv(o->e.get(), out.at(id));
            std::ostringstream line;
            line << "output node " << id << ": " << printExpr(o->e.get())
                 << " in " << ivText(pred);
            lines.push_back(line.str());
        }
    return lines;
}

}  // namespace tip
