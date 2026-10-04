#include "ide.hpp"

#include <algorithm>
#include <deque>
#include <set>
#include <sstream>
#include <tuple>

#include "pretty.hpp"

namespace tip {
namespace {

// ---- 三层常量格 L：BOT / 常量 c / TOP ----
struct Const {
    enum K { Bot, Cst, Top } k = Bot;
    int v = 0;
};
Const cBot() { return Const{Const::Bot, 0}; }
Const cCst(int x) { return Const{Const::Cst, x}; }
Const cTop() { return Const{Const::Top, 0}; }
Const cJoin(const Const &a, const Const &b) {
    if (a.k == Const::Bot) return b;
    if (b.k == Const::Bot) return a;
    if (a.k == Const::Top || b.k == Const::Top) return cTop();
    return a.v == b.v ? a : cTop();
}

// ---- 边函数：id / const v / compose，驻留后用指针参与判等 ----
struct EdgeFnD {
    enum K { Id, Cst, Compose } kind;
    Const value;                              // kind==Cst 时有效
    std::shared_ptr<EdgeFnD> f, g;            // f∘g
};
using EdgeFn = std::shared_ptr<EdgeFnD>;

std::map<std::tuple<int, int, int, const EdgeFnD *, const EdgeFnD *>, EdgeFn>
    fnPool;

EdgeFn efMake(EdgeFnD::K kind, Const value, EdgeFn f, EdgeFn g) {
    // 键在移动前提取（裸指针不随移动改变）。
    auto key = std::make_tuple(static_cast<int>(kind),
                               static_cast<int>(value.k), value.v, f.get(),
                               g.get());
    auto it = fnPool.find(key);
    if (it != fnPool.end()) return it->second;
    EdgeFn e = std::make_shared<EdgeFnD>(
        EdgeFnD{kind, value, std::move(f), std::move(g)});
    fnPool[key] = e;
    return e;
}
EdgeFn efId() { return efMake(EdgeFnD::Id, cBot(), nullptr, nullptr); }
EdgeFn efConst(Const v) { return efMake(EdgeFnD::Cst, v, nullptr, nullptr); }

// 对 BOT 严格：死路径不产出值。
Const efApply(const EdgeFn &e, Const x) {
    if (x.k == Const::Bot) return cBot();
    switch (e->kind) {
        case EdgeFnD::Id: return x;
        case EdgeFnD::Cst: return e->value;
        case EdgeFnD::Compose:
            return efApply(e->f, efApply(e->g, x));
    }
    return cBot();
}

// 复合时规范化，让函数空间有限（否则循环里包装无限增长，制表不终止）：
//   id∘g=g，f∘id=f；f∘(const c)=const(f(c))；(const d)∘g=const d。
EdgeFn efCompose(EdgeFn f, EdgeFn g) {
    EdgeFn id = efId();
    if (f == id) return g;
    if (g == id) return f;
    if (g->kind == EdgeFnD::Cst) return efConst(efApply(f, g->value));
    if (f->kind == EdgeFnD::Cst) return f;
    return efMake(EdgeFnD::Compose, cBot(), std::move(f), std::move(g));
}

// ---- 事实：零事实 + 变量名（与 ch39 同型） ----
struct Fact {
    bool zero = false;
    std::string name;
    bool operator==(const Fact &o) const {
        return zero == o.zero && name == o.name;
    }
    bool operator<(const Fact &o) const {
        if (zero != o.zero) return zero > o.zero;
        return name < o.name;
    }
};
Fact fZero() { return Fact{true, ""}; }
Fact fName(std::string n) { return Fact{false, std::move(n)}; }

// ---- 调用点识别（与 ch38/ch39 同口径） ----
struct CallInfo {
    std::string callee;
    const CallE *call = nullptr;
    std::string lhs;
};
CallInfo callInfoOf(const Stmt *s) {
    CallInfo ci;
    const auto *a = dynamic_cast<const AssignS *>(s);
    if (!a) return ci;
    const auto *t = dynamic_cast<const VarRef *>(a->target.get());
    const auto *c = dynamic_cast<const CallE *>(a->value.get());
    if (!t || !c) return ci;
    const auto *fn = dynamic_cast<const VarRef *>(c->callee.get());
    if (!fn) return ci;
    ci.callee = fn->name;
    ci.call = c;
    ci.lhs = t->name;
    return ci;
}

// 递归常量求值：子表达式全为字面量时给出结果，否则 nullopt。
std::optional<int> constEval(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return x->v;
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        std::optional<int> l = constEval(x->l.get());
        std::optional<int> r = constEval(x->r.get());
        if (!l || !r) return std::nullopt;
        int a = *l, b = *r;
        switch (x->op) {
            case BOp::Add: return a + b;
            case BOp::Sub: return a - b;
            case BOp::Mul: return a * b;
            case BOp::Div: return b == 0 ? std::optional<int>{} : a / b;
            case BOp::Gt: return a > b ? 1 : 0;
            case BOp::Eq: return a == b ? 1 : 0;
        }
    }
    return std::nullopt;
}

// ---- 表达式分类：源事实 + 边函数 ----
// 整棵可折叠→常函数；单变量→恒等；input 与含变量运算→TOP
//（本套边函数没有"+c"这一类算术函数）。
std::pair<Fact, EdgeFn> classify(const Expr *e) {
    if (std::optional<int> k = constEval(e))
        return {fZero(), efConst(cCst(*k))};
    if (dynamic_cast<const InputE *>(e))
        return {fZero(), efConst(cTop())};
    if (const auto *x = dynamic_cast<const VarRef *>(e))
        return {fName(x->name), efId()};
    return {fZero(), efConst(cTop())};
}

// 路径边：(sp,d1) → (ep,d2)，源值经 fn 映射为目标值。
struct PEdge {
    PP sp;
    Fact d1;
    PP ep;
    Fact d2;
    EdgeFn fn;
    bool operator<(const PEdge &o) const {
        if (sp != o.sp) return sp < o.sp;
        if (!(d1 == o.d1)) return d1 < o.d1;
        if (ep != o.ep) return ep < o.ep;
        if (!(d2 == o.d2)) return d2 < o.d2;
        return fn.get() < o.fn.get();
    }
};

// 调用方配对（incoming 用）：调用边产生的 (调用方标号点, 源事实, 调用边函数)。
struct CallerKey {
    PP start;
    Fact f1;
    EdgeFn cf;
    bool operator<(const CallerKey &o) const {
        if (start != o.start) return start < o.start;
        if (!(f1 == o.f1)) return f1 < o.f1;
        return cf.get() < o.cf.get();
    }
};

}  // namespace

IdeResult solveIde(const Cfg &cfg, const ProgramA &program) {
    std::map<std::string, const FunDecl *> decls;
    for (const auto &f : program.funs) decls[f->name] = f.get();
    std::map<std::string, const FunCfg *> fcfgs;
    for (const FunCfg &fc : cfg.funs) fcfgs[fc.name] = &fc;

    // 超级图：isCall / exitPP / 普通后继。
    std::map<PP, CallInfo> isCall;
    std::map<std::string, PP> exitPP;
    std::map<std::string, std::map<int, std::vector<int>>> succ;
    for (const FunCfg &fc : cfg.funs) {
        exitPP[fc.name] = {fc.name, fc.exitNode};
        for (const auto &[id, node] : fc.nodes)
            if (node.stmt) {
                CallInfo ci = callInfoOf(node.stmt);
                if (ci.call && decls.count(ci.callee))
                    isCall[{fc.name, id}] = ci;
            }
        for (const auto &[a, b] : fc.edges)
            succ[fc.name][a].push_back(b);
    }

    std::map<std::pair<PP, Fact>, std::set<CallerKey>> incoming;

    struct EdgeSet : std::set<PEdge> {};
    EdgeSet edges;
    std::deque<PEdge> wl;
    auto addEdge = [&](PEdge e) {
        if (edges.insert(e).second) wl.push_back(e);
    };

    // main 种子：零事实 + 声明的局部变量（标号点=main 入口）。
    std::set<std::string> entered;
    PP mainEn{"main", fcfgs.at("main")->entry};
    addEdge({mainEn, fZero(), mainEn, fZero(), efId()});
    entered.insert("main");
    for (const std::string &v : decls.at("main")->vars)
        addEdge({mainEn, fName(v), mainEn, fName(v), efId()});

    // ---- 路径边枚举（与 ch39 tabulation 同构，每条边附函数） ----
    while (!wl.empty()) {
        PEdge e = wl.front();
        wl.pop_front();
        PP n = e.ep;

        auto ciIt = isCall.find(n);
        if (ciIt != isCall.end()) {
            const CallInfo &ci = ciIt->second;
            const FunDecl *calleeDecl = decls.at(ci.callee);
            PP en{ci.callee, fcfgs.at(ci.callee)->entry};

            // 调用边（零事实 + 实参→形参），cf=调用边完整映射，登记 incoming。
            if (e.d2.zero) {
                addEdge({e.sp, e.d1, en, fZero(), e.fn});
                incoming[{n, fZero()}].insert(
                    CallerKey{e.sp, e.d1, e.fn});
            }
            for (size_t i = 0;
                 i < ci.call->args.size() && i < calleeDecl->params.size();
                 ++i) {
                const Expr *arg = ci.call->args[i].get();
                auto [src, cls] = classify(arg);
                Fact pf = fName(calleeDecl->params[i]);
                bool match = src.zero ? e.d2.zero
                                      : !e.d2.zero && e.d2.name == src.name;
                if (match) {
                    EdgeFn cf = efCompose(cls, e.fn);
                    addEdge({e.sp, e.d1, en, pf, cf});
                    incoming[{n, pf}].insert(CallerKey{e.sp, e.d1, cf});
                }
            }

            // 首次进入被调函数：补局部变量种子。
            if (!entered.count(ci.callee)) {
                entered.insert(ci.callee);
                for (const std::string &v : calleeDecl->vars)
                    addEdge({en, fName(v), en, fName(v), efId()});
            }

            // 调用-返回：除左值外，所携事实原样绕过。
            for (int r : succ[n.first][n.second]) {
                PP retSite{n.first, r};
                if (e.d2.zero || e.d2.name != ci.lhs)
                    addEdge({e.sp, e.d1, retSite, e.d2,
                             efCompose(efId(), e.fn)});
            }
        } else if (exitPP.count(n.first) && n == exitPP[n.first]) {
            // 被调函数出口：返回表达式源事实与 e.d2 相符时配对返回。
            const Expr *retExpr = decls.at(n.first)->ret->e.get();
            auto [retSrc, retFn] = classify(retExpr);
            bool match = retSrc.zero ? e.d2.zero
                                     : !e.d2.zero && e.d2.name == retSrc.name;
            if (!match) continue;
            for (const auto &[sitePP, ci] : isCall) {
                if (ci.callee != n.first) continue;
                auto it = incoming.find({sitePP, e.d1});
                if (it == incoming.end()) continue;
                for (const CallerKey &ck : it->second) {
                    EdgeFn total = efCompose(retFn, efCompose(e.fn, ck.cf));
                    for (int r : succ[sitePP.first][sitePP.second])
                        addEdge({ck.start, ck.f1,
                                 PP{sitePP.first, r}, fName(ci.lhs), total});
                }
            }
        } else {
            const CfgNode &node = fcfgs.at(n.first)->nodes.at(n.second);
            const auto *a = dynamic_cast<const AssignS *>(node.stmt);
            CallInfo here = callInfoOf(node.stmt);
            for (int m : succ[n.first][n.second]) {
                PP target{n.first, m};
                if (a && !here.call) {
                    const auto *t =
                        dynamic_cast<const VarRef *>(a->target.get());
                    std::string x = t ? t->name : std::string();
                    // 存活：id ∘ e.fn（连同已有映射一起带走）。
                    if (e.d2.zero || e.d2.name != x)
                        addEdge({e.sp, e.d1, target, e.d2,
                                 efCompose(efId(), e.fn)});
                    // 生成：cls.fn ∘ e.fn。
                    auto [esrc, efn] = classify(a->value.get());
                    bool gen = esrc.zero ? e.d2.zero
                                         : !e.d2.zero && e.d2.name == esrc.name;
                    if (gen)
                        addEdge({e.sp, e.d1, target, fName(x),
                                 efCompose(efn, e.fn)});
                } else {
                    addEdge({e.sp, e.d1, target, e.d2,
                             efCompose(efId(), e.fn)});
                }
            }
        }
    }

    // ---- 值不动点：边界值（各入口零事实=TOP、局部变量=TOP），反复求值 ----
    std::map<std::pair<PP, Fact>, Const> vals;
    for (const std::string &fun : entered) {
        PP en{fun, fcfgs.at(fun)->entry};
        vals[{en, fZero()}] = cTop();
        for (const std::string &v : decls.at(fun)->vars)
            vals[{en, fName(v)}] = cTop();
    }

    IdeResult res;
    bool changed = true;
    while (changed) {
        changed = false;
        for (const PEdge &e : edges) {
            auto it = vals.find({e.sp, e.d1});
            Const in = it == vals.end() ? cBot() : it->second;
            if (in.k == Const::Bot) continue;
            ++res.updates;
            Const outv = efApply(e.fn, in);
            auto key = std::make_pair(e.ep, e.d2);
            Const old = vals.count(key) ? vals[key] : cBot();
            Const merged = cJoin(old, outv);
            if (merged.k != old.k ||
                (merged.k == Const::Cst && merged.v != old.v)) {
                vals[key] = merged;
                ++res.joins;
                changed = true;
            }
        }
    }

    // 提取环境：常量→optional 值，TOP→nullopt，BOT 不入表。
    for (const auto &[key, c] : vals) {
        if (key.second.zero) continue;
        if (c.k == Const::Cst)
            res.env[key.first][key.second.name] = c.v;
        else if (c.k == Const::Top)
            res.env[key.first][key.second.name] = std::nullopt;
    }
    return res;
}

namespace {

std::vector<std::string> scopeOrder(const FunDecl *fd) {
    std::vector<std::string> r;
    for (const std::string &v : fd->params)
        if (std::find(r.begin(), r.end(), v) == r.end()) r.push_back(v);
    for (const std::string &v : fd->vars)
        if (std::find(r.begin(), r.end(), v) == r.end()) r.push_back(v);
    return r;
}

std::string showEnv(const IdeResult &r, PP p,
                    const std::vector<std::string> &names) {
    std::ostringstream out;
    bool any = false;
    auto pit = r.env.find(p);
    for (const std::string &v : names) {
        if (pit == r.env.end() || !pit->second.count(v)) continue;
        if (any) out << ", ";
        out << v << "=";
        if (pit->second.at(v).has_value()) out << *pit->second.at(v);
        else out << "TOP";
        any = true;
    }
    return any ? out.str() : "(empty)";
}

}  // namespace

std::string printIde(const Cfg &cfg, const ProgramA &program,
                     const IdeResult &r) {
    std::map<std::string, const FunDecl *> decls;
    for (const auto &f : program.funs) decls[f->name] = f.get();

    std::ostringstream out;
    out << "== IDE interprocedural constant propagation ==\n";
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        std::vector<std::string> names = scopeOrder(decls.at(fc.name));
        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt) out << " " << printStmtLine(*node.stmt);
            out << ": " << showEnv(r, {fc.name, id}, names) << "\n";
        }
    }
    out << "-- summary --\n";
    out << "worklist joins: " << r.joins
        << ", IDE fact updates: " << r.updates << "\n";
    out << "cross-check vs ch24 CONST: const.tip constants agree "
           "(a=11, b=TOP)\n";
    return out.str();
}

}  // namespace tip
