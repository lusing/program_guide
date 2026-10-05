#include "widen.hpp"

#include <algorithm>
#include <set>
#include <sstream>

namespace tip {
namespace {

// ---- 条件识别：把 (x > k)/(k > x)/(x == k) 归一成 {变量, 界, 比较种类} ----
enum CondKind { Cgt, Clt, Ceq };
struct CondFact {
    std::string var;
    int k = 0;
    CondKind kind = Cgt;
    bool ok = false;
};

CondFact parseCond(const Expr *cond) {
    CondFact f;
    const auto *b = dynamic_cast<const Binop *>(cond);
    if (!b) return f;
    const auto *x = dynamic_cast<const VarRef *>(b->l.get());
    const auto *c = dynamic_cast<const IntLit *>(b->r.get());
    if (!x || !c) {
        x = dynamic_cast<const VarRef *>(b->r.get());
        c = dynamic_cast<const IntLit *>(b->l.get());
    }
    if (!x || !c) return f;
    f.var = x->name;
    f.k = c->v;
    switch (b->op) {
        case BOp::Gt:
            // 原式 (x > k) 或 (k > x)：后者按 (x < k) 归一。
            f.kind = (b->l.get() == x) ? Cgt : Clt;
            f.ok = true;
            break;
        case BOp::Eq:
            f.kind = Ceq;
            f.ok = true;
            break;
        default:
            break;
    }
    return f;
}

// ---- CFG 构造器编号/连线规则的局部重建：拿到每个分支真/假边的目标 ----
// cfg.cpp 用"先序编号 + 语句透传"构造图且边不带标签；本章不动共享的
// cfg.hpp（前几章文档已按字节嵌入它），按同一规则重推一份。
struct BranchEdges {
    std::map<int, int> trueOf, falseOf;  // 分支节点号 → 真/假边目标
};

class LocalWiring {
public:
    BranchEdges run(const ProgramA &program) {
        for (const auto &fun : program.funs) {
            next_ = 2;  // entry 固定为 1
            id_.clear();
            number(fun->body.get());
            const int retId = next_++;  // 与 cfg.cpp 相同：return、exit 收尾
            (void)next_;
            wire(fun->body.get(), {retId});
        }
        return edges_;
    }

private:
    BranchEdges edges_;
    int next_ = 2;
    std::map<const Stmt *, int> id_;

    // 第一遍：先序编号（与 cfg.cpp 的 numberStmt 逐条对应）。
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

    // 第二遍：连边（与 cfg.cpp 的 wireStmt 逐条对应；入口点恒为单点）。
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

// 分支节点携带的 cond 表达式（非分支语句返回空）。
const Expr *condOf(const Stmt *s) {
    if (const auto *w = dynamic_cast<const WhileS *>(s)) return w->cond.get();
    if (const auto *i = dynamic_cast<const IfS *>(s)) return i->cond.get();
    return nullptr;
}

}  // namespace

Iv widen(const Iv &a, const Iv &b) {
    if (a.lo > a.hi) return b;  // 旧值为 ⊥：直接采用新值，不跳阈值
    if (b.lo > b.hi) return a;
    Iv r = a;
    if (b.lo < a.lo) {
        // 下界阈值表 {-inf, 0, 1}：取不超过新下界的最大阈值。
        if (b.lo >= 1)
            r.lo = 1;
        else if (b.lo >= 0)
            r.lo = 0;
        else
            r.lo = INT_MIN;
    }
    if (b.hi > a.hi) {
        // 上界阈值表 {1, 0, +inf}：取不低于新上界的最小阈值。
        if (b.hi <= 0)
            r.hi = 0;
        else if (b.hi <= 1)
            r.hi = 1;
        else
            r.hi = INT_MAX;
    }
    return r;
}

Iv narrow(const Iv &a, const Iv &b) {
    if (a.lo > a.hi || b.lo > b.hi) return b;  // ⊥ 不收
    Iv r = a;
    if (a.lo == INT_MIN && b.lo > a.lo) r.lo = b.lo;
    if (a.hi == INT_MAX && b.hi < a.hi) r.hi = b.hi;
    return r;
}

IvEnv refineOnBranch(const Expr *cond, const IvEnv &env, bool taken) {
    CondFact f = parseCond(cond);
    if (!f.ok) return env;
    IvEnv out = env;
    auto it = out.find(f.var);
    if (it == out.end()) return out;  // ⊥ 变量无可精炼
    Iv v = it->second;
    if (v.lo > v.hi) return out;
    switch (f.kind) {
        case Cgt:  // x > k
            if (taken)
                v.lo = std::max(v.lo, f.k == INT_MAX ? INT_MAX : f.k + 1);
            else
                v.hi = std::min(v.hi, f.k);
            break;
        case Clt:  // x < k
            if (taken)
                v.hi = std::min(v.hi, f.k == INT_MIN ? INT_MIN : f.k - 1);
            else
                v.lo = std::max(v.lo, f.k);
            break;
        case Ceq:  // x == k：真边钉成 [k,k]；假边保守不动
            if (taken) {
                if (f.k < v.lo || f.k > v.hi)
                    v = Iv{1, 0};  // 与区间矛盾 → 该边不可达
                else
                    v = Iv{f.k, f.k};
            }
            break;
    }
    it->second = v;
    return out;
}

WidenedResult solveWidenedInterval(const Cfg &cfg, const ProgramA &program,
                                   int maxRounds) {
    Lattice<Iv> lat = ivLattice();
    WidenedResult res;

    // 加宽点：所有 while 条件节点。
    std::set<int> widenPoints;
    for (const FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes)
            if (dynamic_cast<const WhileS *>(node.stmt)) {
                widenPoints.insert(id);
                if (res.headNode < 0) res.headNode = id;
            }

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
        if (be.trueOf.count(a) && be.trueOf[a] == b) pe = PredEdge{a, true, true};
        if (be.falseOf.count(a) && be.falseOf[a] == b)
            pe = PredEdge{a, true, false};
        preds[b].push_back(pe);
    }

    std::set<std::string> vars(program.funs[0]->vars.begin(),
                               program.funs[0]->vars.end());

    // 流入 = 各前驱流出（沿边精炼后）之并；无前驱点取空（参数在下方补全区间）。
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
            // entry 边界：参数视为全区间。
            for (const std::string &p : program.funs[0]->params)
                in[p] = Iv{INT_MIN, INT_MAX};

            if (widenPoints.count(id)) {
                // 加宽点：与上一轮状态逐变量做 ∇。
                auto prev = out.find(id);
                if (prev != out.end())
                    for (auto &[k, v] : in) {
                        Iv pv = prev->second.count(k) ? prev->second.at(k)
                                                      : lat.bot();
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
        if (res.headNode >= 0) {
            IvEnv head = out.count(res.headNode) ? out[res.headNode] : IvEnv{};
            res.trace.push_back("iter " + std::to_string(round) + ": " +
                                printIvEnv(head, vars));
        }
        if (!changed) {
            res.converged = true;
            break;
        }
    }
    res.out = out;
    return res;
}

std::map<int, IvEnv> narrowPass(const Cfg &cfg, const ProgramA &program,
                                const std::map<int, IvEnv> &widened) {
    Lattice<Iv> lat = ivLattice();
    const FunCfg &fc = cfg.funs[0];

    BranchEdges be = LocalWiring().run(program);
    struct PredEdge {
        int node;
        bool refine;
        bool taken;
    };
    std::map<int, std::vector<PredEdge>> preds;
    for (const auto &[a, b] : fc.edges) {
        PredEdge pe{a, false, true};
        if (be.trueOf.count(a) && be.trueOf[a] == b) pe = PredEdge{a, true, true};
        if (be.falseOf.count(a) && be.falseOf[a] == b)
            pe = PredEdge{a, true, false};
        preds[b].push_back(pe);
    }

    std::map<int, IvEnv> out = widened;
    for (const auto &[id, node] : fc.nodes) {
        IvEnv in;
        auto pit = preds.find(id);
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
        // Δ 规则：与加宽解逐变量收窄，只把 ±∞ 处的界收回有限值。
        for (auto &[k, v] : in) {
            Iv pv = widened.count(id) && widened.at(id).count(k)
                        ? widened.at(id).at(k)
                        : lat.bot();
            v = narrow(pv, v);
        }

        IvEnv o = in;
        if (const auto *a = dynamic_cast<const AssignS *>(node.stmt))
            if (const auto *t = dynamic_cast<const VarRef *>(a->target.get()))
                o[t->name] = evalIv(a->value.get(), in);
        out[id] = o;
    }
    return out;
}

std::string printIvEnv(const IvEnv &env, const std::set<std::string> &keys) {
    std::ostringstream out;
    bool first = true;
    for (const std::string &k : keys) {
        if (!first) out << " ";
        out << k << "="
            << (env.count(k) ? ivText(env.at(k)) : std::string("bottom"));
        first = false;
    }
    return out.str();
}

}  // namespace tip
