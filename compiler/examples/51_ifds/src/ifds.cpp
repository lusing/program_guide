#include "ifds.hpp"

#include <deque>
#include <sstream>

#include "pretty.hpp"

namespace tip {
namespace {

// ---- 表达式/语句读取的变量（与 ch35 init.cpp 同型，自带一份保持自包含） ----
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
    return r;
}

std::set<std::string> stmtUses(const Stmt *s) {
    if (const auto *a = dynamic_cast<const AssignS *>(s))
        return usesOf(a->value.get());
    if (const auto *o = dynamic_cast<const OutputS *>(s)) return usesOf(o->e.get());
    if (const auto *r = dynamic_cast<const ReturnS *>(s)) return usesOf(r->e.get());
    if (const auto *w = dynamic_cast<const WhileS *>(s)) return usesOf(w->cond.get());
    if (const auto *i = dynamic_cast<const IfS *>(s)) return usesOf(i->cond.get());
    return {};
}

// ---- 调用点识别：赋值右端是单个具名函数调用（与 ch50 同口径） ----
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

// ---- 四类可分配流函数：单点事实输入 → 事实集合 ----

// 普通过程内边（语句 s 之后）：
//   赋值 x=e（非调用）：d≠x 时 d 存活；d 被 e 读取时生成 x；
//   其余语句：恒等。零事实恒等通过。
std::set<Fact> normalFlow(const Stmt *s, Fact d) {
    std::set<Fact> out;
    if (d.zero) {
        out.insert(fZero());
        return out;
    }
    if (const auto *a = dynamic_cast<const AssignS *>(s)) {
        if (!callInfoOf(s).call) {
            const auto *t =
                dynamic_cast<const VarRef *>(a->target.get());
            if (t) {
                if (d.name != t->name) out.insert(d);
                std::set<std::string> rhs = usesOf(a->value.get());
                if (rhs.count(d.name)) out.insert(fName(t->name));
                return out;
            }
        }
    }
    out.insert(d);
    return out;
}

// 调用边（调用点 → 被调函数入口）：
//   d 出现在第 i 个实参里 → 形参 i；零事实→零事实。
std::set<Fact> callFlow(const CallInfo &ci,
                        const std::vector<std::string> &params, Fact d) {
    std::set<Fact> out;
    if (d.zero) {
        out.insert(fZero());
        return out;
    }
    for (size_t i = 0; i < ci.call->args.size() && i < params.size(); ++i) {
        std::set<std::string> argVars = usesOf(ci.call->args[i].get());
        if (argVars.count(d.name)) out.insert(fName(params[i]));
    }
    return out;
}

// 返回边（被调函数出口 → 返回点）：
//   d 被返回表达式读取 → 调用赋值的左值；零事实→零事实。
std::set<Fact> returnFlow(const CallInfo &ci, const Expr *retExpr, Fact d) {
    std::set<Fact> out;
    if (d.zero) {
        out.insert(fZero());
        return out;
    }
    std::set<std::string> retVars = usesOf(retExpr);
    if (retVars.count(d.name)) out.insert(fName(ci.lhs));
    return out;
}

// 调用-返回边（调用点 → 返回点，过程内"绕过"）：
//   局部事实存活，但左值被杀（左值的新值由被调函数摘要给出）；
//   零事实→零事实。
std::set<Fact> callToReturnFlow(const CallInfo &ci, Fact d) {
    std::set<Fact> out;
    if (d.zero) {
        out.insert(fZero());
        return out;
    }
    if (d.name != ci.lhs) out.insert(d);
    return out;
}

std::string showFactSet(const std::set<Fact> &fs) {
    std::set<std::string> names;
    for (const Fact &f : fs)
        if (!f.zero) names.insert(f.name);
    if (names.empty()) return "{}";
    std::ostringstream out;
    out << "{";
    bool first = true;
    for (const std::string &v : names) {
        if (!first) out << ",";
        out << v;
        first = false;
    }
    out << "}";
    return out.str();
}

}  // namespace

Fact fZero() { return Fact{true, ""}; }
Fact fName(std::string n) { return Fact{false, std::move(n)}; }

std::string factShow(const Fact &f) { return f.zero ? "0" : f.name; }

IfdsResult solveIfds(const Cfg &cfg, const ProgramA &program) {
    // 函数表与 FunCfg 表。
    std::map<std::string, const FunDecl *> decls;
    for (const auto &f : program.funs) decls[f->name] = f.get();
    std::map<std::string, const FunCfg *> fcfgs;
    for (const FunCfg &fc : cfg.funs) fcfgs[fc.name] = &fc;

    // 超级图：普通边集合（调用点的 CFG 出边另算 call-to-return）。
    // isCall[PP] → 调用信息；exitPP[fun]。
    std::map<PP, CallInfo> isCall;
    std::map<std::string, PP> exitPP;
    std::map<std::string, std::map<int, std::vector<int>>> normalSucc;
    for (const FunCfg &fc : cfg.funs) {
        exitPP[fc.name] = {fc.name, fc.exitNode};
        for (const auto &[id, node] : fc.nodes)
            if (node.stmt) {
                CallInfo ci = callInfoOf(node.stmt);
                if (ci.call && decls.count(ci.callee))
                    isCall[{fc.name, id}] = ci;
            }
        for (const auto &[a, b] : fc.edges)
            normalSucc[fc.name][a].push_back(b);
    }

    // incoming：调用点 PP × 被调入口事实 → 调用方 (start 标号, 站点事实)
    // 列表。被调函数出口路径边按此配对回送给调用方。
    struct CallerKey {
        PP start;
        Fact f1;
        bool operator<(const CallerKey &o) const {
            if (start != o.start) return start < o.start;
            return f1 < o.f1;
        }
    };
    std::map<std::pair<PP, Fact>, std::set<CallerKey>> incoming;

    IfdsResult res;
    std::deque<PathEdge> wl;
    auto addEdge = [&](const PathEdge &e) {
        if (res.pathEdges.insert(e).second) wl.push_back(e);
    };

    // 每个函数入口的种子事实：声明的局部变量（参数到达时已初始化）。
    auto seedsOf = [&](const std::string &fun) {
        std::set<Fact> seeds;
        const FunDecl *fd = decls.at(fun);
        for (const std::string &v : fd->vars) seeds.insert(fName(v));
        return seeds;
    };

    // main 起步：零事实路径边 + 种子；标记 main 已进入。
    std::set<std::string> entered;
    PP mainEntry{"main", fcfgs.at("main")->entry};
    addEdge({mainEntry, fZero(), mainEntry, fZero()});
    entered.insert("main");
    for (const Fact &s : seedsOf("main"))
        addEdge({mainEntry, s, mainEntry, s});

    while (!wl.empty()) {
        PathEdge e = wl.front();
        wl.pop_front();
        PP n = e.end;

        auto ciIt = isCall.find(n);
        if (ciIt != isCall.end()) {
            // ---- 调用点 ----
            const CallInfo &ci = ciIt->second;
            const FunCfg &calleeCfg = *fcfgs.at(ci.callee);
            PP calleeEntry{ci.callee, calleeCfg.entry};

            // 调用边：把入口事实送进被调函数，并登记 incoming 配对。
            for (const Fact &d3 : callFlow(ci, decls.at(ci.callee)->params, e.f2)) {
                incoming[{n, d3}].insert(CallerKey{e.start, e.f1});
                addEdge({calleeEntry, d3, calleeEntry, d3});
                // 首次进入被调函数：补它自己的种子路径边。
                if (!entered.count(ci.callee)) {
                    entered.insert(ci.callee);
                    for (const Fact &s : seedsOf(ci.callee))
                        addEdge({calleeEntry, s, calleeEntry, s});
                }
            }

            // 调用-返回边：局部事实绕过调用直接到返回点。
            for (int r : normalSucc[n.first][n.second]) {
                PP retSite{n.first, r};
                for (const Fact &d3 : callToReturnFlow(ci, e.f2))
                    addEdge({e.start, e.f1, retSite, d3});
            }
        } else if (exitPP.count(n.first) && n == exitPP[n.first]) {
            // ---- 被调函数出口：配对所有以此函数为被调方的调用点 ----
            for (const auto &[sitePP, ci] : isCall) {
                if (ci.callee != n.first) continue;
                const Expr *retExpr = decls.at(n.first)->ret->e.get();
                auto inIt = incoming.find({sitePP, e.f1});
                if (inIt == incoming.end()) continue;
                for (const CallerKey &ck : inIt->second) {
                    for (int r : normalSucc[sitePP.first][sitePP.second]) {
                        PP retSite{sitePP.first, r};
                        for (const Fact &d3 : returnFlow(ci, retExpr, e.f2))
                            addEdge({ck.start, ck.f1, retSite, d3});
                    }
                }
            }
        } else {
            // ---- 普通过程内边 ----
            const CfgNode &node = fcfgs.at(n.first)->nodes.at(n.second);
            for (int m : normalSucc[n.first][n.second]) {
                PP target{n.first, m};
                for (const Fact &d3 : normalFlow(node.stmt, e.f2))
                    addEdge({e.start, e.f1, target, d3});
            }
        }
    }

    // 提取每个点到达事实；警告：语句读取的变量 ∈ 到达事实。
    for (const PathEdge &e : res.pathEdges) res.reach[e.end].insert(e.f2);
    for (const FunCfg &fc : cfg.funs) {
        for (const auto &[id, node] : fc.nodes) {
            if (!node.stmt) continue;
            std::set<std::string> bad;
            auto rf = res.reach.find({fc.name, id});
            if (rf != res.reach.end()) {
                std::set<std::string> uses = stmtUses(node.stmt);
                for (const std::string &v : uses) {
                    Fact f = fName(v);
                    if (rf->second.count(f)) bad.insert(v);
                }
            }
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

std::string printIfds(const Cfg &cfg, const IfdsResult &r) {
    std::ostringstream out;
    out << "== IFDS path-edge tabulation, possibly-uninitialized ==\n";
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt) out << " " << printStmtLine(*node.stmt);
            out << ": " << showFactSet(r.reach.count({fc.name, id})
                                            ? r.reach.at({fc.name, id})
                                            : std::set<Fact>{});
            if (node.stmt && callInfoOf(node.stmt).call) out << " (call site)";
            out << "\n";
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
