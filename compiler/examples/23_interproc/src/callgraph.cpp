#include "callgraph.hpp"

#include <deque>
#include <functional>
#include <sstream>

#include "pretty.hpp"

namespace tip {
namespace {

// 收集语句中出现的所有调用（callee 限定为具名函数）。
void collectCallsExpr(const Expr *e, std::set<std::string> &out) {
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        collectCallsExpr(x->l.get(), out);
        collectCallsExpr(x->r.get(), out);
    } else if (const auto *x = dynamic_cast<const CallE *>(e)) {
        if (const auto *fn = dynamic_cast<const VarRef *>(x->callee.get()))
            out.insert(fn->name);
        for (const auto &a : x->args) collectCallsExpr(a.get(), out);
    }
}

void collectCallsStmt(const Stmt *s, std::set<std::string> &out) {
    if (const auto *b = dynamic_cast<const BlockS *>(s)) {
        for (const auto &x : b->ss) collectCallsStmt(x.get(), out);
    } else if (const auto *i = dynamic_cast<const IfS *>(s)) {
        collectCallsExpr(i->cond.get(), out);
        collectCallsStmt(i->then.get(), out);
        if (i->els) collectCallsStmt(i->els.get(), out);
    } else if (const auto *w = dynamic_cast<const WhileS *>(s)) {
        collectCallsExpr(w->cond.get(), out);
        collectCallsStmt(w->body.get(), out);
    } else if (const auto *a = dynamic_cast<const AssignS *>(s)) {
        collectCallsExpr(a->value.get(), out);
    } else if (const auto *o = dynamic_cast<const OutputS *>(s)) {
        collectCallsExpr(o->e.get(), out);
    }
}

// 调用图有无环：三色 DFS。
bool hasCycle(const std::string &u,
              const std::map<std::string, std::set<std::string>> &edges,
              std::set<std::string> &visiting, std::set<std::string> &done) {
    visiting.insert(u);
    auto it = edges.find(u);
    if (it != edges.end())
        for (const std::string &v : it->second) {
            if (visiting.count(v)) return true;
            if (!done.count(v) && hasCycle(v, edges, visiting, done)) return true;
        }
    visiting.erase(u);
    done.insert(u);
    return false;
}

// ---- 内联展开求值：直线纯函数在传递函数层展开 ----

// 函数体是否只有赋值语句（直线、无分支/循环/输入/输出）。
// 是则把赋值序列取出供符号执行。
bool straightLineBody(const Stmt *s, std::vector<const AssignS *> &seq) {
    if (const auto *b = dynamic_cast<const BlockS *>(s)) {
        for (const auto &x : b->ss)
            if (!straightLineBody(x.get(), seq)) return false;
        return true;
    }
    if (const auto *a = dynamic_cast<const AssignS *>(s)) {
        if (!dynamic_cast<const VarRef *>(a->target.get())) return false;
        seq.push_back(a);
        return true;
    }
    return false;  // If/While/Output 等一律不内联
}

// 调用感知的扁平常量求值：折叠规则与 evalConstExpr 相同，
// 差别仅在 CallE——直线纯被调函数在此展开，其余保守 ⊤。
Const evalCallExpr(const Expr *e, const ConstEnv &env,
                   const std::map<std::string, const FunDecl *> &funs,
                   int depth) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return cVal(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        auto it = env.find(x->name);
        return it == env.end() ? cBot() : it->second;
    }
    if (dynamic_cast<const InputE *>(e)) return cTop();
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const Const l = evalCallExpr(x->l.get(), env, funs, depth);
        const Const r = evalCallExpr(x->r.get(), env, funs, depth);
        if (l.kind == 0 || r.kind == 0) return cBot();
        if (l.kind == 2 || r.kind == 2) return cTop();
        switch (x->op) {
            case BOp::Add: return cVal(l.v + r.v);
            case BOp::Sub: return cVal(l.v - r.v);
            case BOp::Mul: return cVal(l.v * r.v);
            case BOp::Div:
                if (r.v == 0) return cBot();
                return cVal(l.v / r.v);
            case BOp::Gt: return cVal(l.v > r.v ? 1 : 0);
            case BOp::Eq: return cVal(l.v == r.v ? 1 : 0);
        }
    }
    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        // 深度上限防环外失控（有环时应早被 acyclic 判定拦下）。
        if (depth > 8) return cTop();
        const auto *fn = dynamic_cast<const VarRef *>(x->callee.get());
        if (!fn) return cTop();
        auto fit = funs.find(fn->name);
        if (fit == funs.end()) return cTop();
        const FunDecl *callee = fit->second;

        std::vector<const AssignS *> seq;
        if (!straightLineBody(callee->body.get(), seq)) return cTop();

        // 实参求值后按位置绑给形参；实参不足的形参取 ⊤（保守）。
        ConstEnv local;
        for (size_t i = 0; i < callee->params.size(); ++i)
            local[callee->params[i]] =
                i < x->args.size()
                    ? evalCallExpr(x->args[i].get(), env, funs, depth + 1)
                    : cTop();
        for (const AssignS *a : seq)
            local[dynamic_cast<const VarRef *>(a->target.get())->name] =
                evalCallExpr(a->value.get(), local, funs, depth + 1);
        return evalCallExpr(callee->ret->e.get(), local, funs, depth + 1);
    }
    return cTop();  // 指针/记录：保守
}

}  // namespace

CallGraph buildCallGraph(const ProgramA &program) {
    CallGraph cg;
    for (const auto &f : program.funs) {
        std::set<std::string> callees;
        collectCallsStmt(f->body.get(), callees);
        for (const std::string &c : callees) cg.edges[f->name].insert(c);
    }
    std::set<std::string> visiting, done;
    cg.acyclic = true;
    for (const auto &[f, _] : cg.edges)
        if (!done.count(f) && hasCycle(f, cg.edges, visiting, done)) {
            cg.acyclic = false;
            break;
        }
    return cg;
}

std::string printCallGraph(const CallGraph &cg) {
    std::ostringstream out;
    for (const auto &[f, cs] : cg.edges) {
        out << f << " ->";
        if (cs.empty()) out << " (none)";
        for (const std::string &c : cs) out << " " << c;
        out << "\n";
    }
    return out.str();
}

std::map<std::string, ConstPointEnv> solveConstInterproc(
    const Cfg &cfg, const ProgramA &program, bool inlineExpand) {
    std::map<std::string, const FunDecl *> funs;
    for (const auto &f : program.funs) funs[f->name] = f.get();

    std::map<std::string, ConstPointEnv> cur;
    for (const FunCfg &fc : cfg.funs) {
        const FunDecl *decl = funs.at(fc.name);

        std::map<int, std::vector<int>> preds, succs;
        for (const auto &[from, to] : fc.edges) {
            succs[from].push_back(to);
            preds[to].push_back(from);
        }

        ConstPointEnv &state = cur[fc.name];
        std::deque<int> wl{fc.entry};
        std::set<int> in{fc.entry};
        while (!wl.empty()) {
            int p = wl.front();
            wl.pop_front();
            in.erase(p);
            const CfgNode &node = fc.nodes.at(p);

            ConstEnv nv;
            if (node.kind == CfgNode::Kind::Entry) {
                nv = constEntryEnv(*decl);
            } else {
                ConstEnv before;
                auto pit = preds.find(p);
                if (pit != preds.end())
                    for (int q : pit->second)
                        if (auto it = state.find(q); it != state.end())
                            before = constJoinEnv(before, it->second);
                // 传递：赋值目标为标量时按调用感知求值；其余原样传递。
                nv = before;
                if (node.kind == CfgNode::Kind::Assign && node.stmt) {
                    const auto *a =
                        dynamic_cast<const AssignS *>(node.stmt);
                    const auto *target =
                        dynamic_cast<const VarRef *>(a->target.get());
                    if (target)
                        nv[target->name] =
                            inlineExpand
                                ? evalCallExpr(a->value.get(), before, funs, 0)
                                : evalConstExpr(a->value.get(), before);
                }
            }

            auto old = state.find(p);
            if (old == state.end() || !(old->second == nv)) {
                state[p] = nv;
                auto sit = succs.find(p);
                if (sit != succs.end())
                    for (int s : sit->second)
                        if (!in.count(s)) {
                            wl.push_back(s);
                            in.insert(s);
                        }
            }
        }
    }
    return cur;
}

std::string printInterproc(const Cfg &cfg, const ProgramA &program,
                           const std::map<std::string, ConstPointEnv> &states) {
    (void)program;
    std::ostringstream out;
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        const ConstPointEnv &state = states.at(fc.name);
        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id;
            if (node.stmt) out << " " << printStmtLine(*node.stmt);
            out << ":";
            const ConstEnv &env = state.at(id);
            if (env.empty()) {
                out << "\n";
                continue;
            }
            for (const auto &[k, v] : env) out << " " << k << "=" << constShow(v);
            out << "\n";
        }
    }
    return out.str();
}

}  // namespace tip
