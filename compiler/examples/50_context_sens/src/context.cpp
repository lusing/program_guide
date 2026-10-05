#include "context.hpp"

#include <deque>
#include <set>
#include <tuple>

namespace tip {
namespace {

std::map<std::string, const FunDecl *> funTable(const ProgramA &program) {
    std::map<std::string, const FunDecl *> funs;
    for (const auto &f : program.funs) funs[f->name] = f.get();
    return funs;
}

// 调用点信息：Assign 语句的右端恰好是一个"具名函数调用"才算。
// 嵌在更大表达式里的调用保守按 ⊤ 处理（教学实现简化，正文说明）。
struct CallSite {
    std::string callee;
    const CallE *call = nullptr;
};

CallSite asCallSite(const Stmt *s) {
    CallSite cs;
    const auto *a = dynamic_cast<const AssignS *>(s);
    if (!a || !dynamic_cast<const VarRef *>(a->target.get())) return cs;
    const auto *c = dynamic_cast<const CallE *>(a->value.get());
    if (!c) return cs;
    const auto *fn = dynamic_cast<const VarRef *>(c->callee.get());
    if (!fn) return cs;
    cs.callee = fn->name;
    cs.call = c;
    return cs;
}

// push 后截断：调用串只保留最近 k 个调用点（k<0 = 不截断）。
Ctx pushTrunc(const Ctx &ctx, const Site &s, int k) {
    Ctx next = ctx;
    next.push_back(s);
    if (k >= 0 && static_cast<int>(next.size()) > k)
        next.erase(next.begin(), next.begin() + (next.size() - k));
    return next;
}

}  // namespace

ContextResult solveContext(const Cfg &cfg, const ProgramA &program, int k) {
    std::map<std::string, const FunDecl *> funs = funTable(program);
    std::map<std::string, const FunCfg *> fcfgs;
    for (const FunCfg &fc : cfg.funs) fcfgs[fc.name] = &fc;

    // 每个函数的 CFG 前驱/后继表。
    std::map<std::string, std::map<int, std::vector<int>>> preds, succs;
    for (const FunCfg &fc : cfg.funs)
        for (const auto &[a, b] : fc.edges) {
            preds[fc.name][b].push_back(a);
            succs[fc.name][a].push_back(b);
        }

    // 返回值累积：(调用方上下文, 调用点) → 已见返回值的 join。
    std::map<std::pair<Ctx, Site>, Const> retValues;
    // 形参绑定累积：(入口上下文, 被调函数) → 形参 → 实参 join。
    std::map<CtxFun, ConstEnv> entryArgs;
    // 反向表：(被调函数, 入口上下文) → 产生它的 (调用方上下文, 站点)。
    // 返回时按这张表扇形回送——教科书 call-string 的返回匹配：
    // 所有"从 δ 经过站点 s 进入、入口上下文恰为 γ"的调用方都接收返回值。
    std::map<CtxFun, std::vector<std::pair<Ctx, Site>>> retCandidates;
    // 每个函数出现过哪些上下文（仅用于正文打印分箱数）。
    std::map<std::string, std::set<Ctx>> seenCtx;
    seenCtx["main"].insert(Ctx{});

    ContextResult res;
    auto &states = res.out;

    struct Item {
        Ctx ctx;
        std::string fun;
        int node;
    };
    std::deque<Item> wl;
    std::set<std::tuple<Ctx, std::string, int>> queued;

    const int maxDepth = 8;  // k<0（无限 k）时的递归保险丝

    auto enqueue = [&](const Ctx &ctx, const std::string &fun, int node) {
        if (static_cast<int>(ctx.size()) > maxDepth) return;
        if (queued.insert({ctx, fun, node}).second)
            wl.push_back({ctx, fun, node});
    };

    // main 入口起步；其余函数只经调用进入。
    enqueue({}, "main", fcfgs.at("main")->entry);

    while (!wl.empty()) {
        Item it = wl.front();
        wl.pop_front();
        queued.erase({it.ctx, it.fun, it.node});

        const FunCfg &fc = *fcfgs.at(it.fun);
        const CfgNode &node = fc.nodes.at(it.node);
        CtxFun key{it.ctx, it.fun};

        // ---- 入口环境：调用方累积的形参绑定（main：空） ----
        ConstEnv in;
        if (node.kind == CfgNode::Kind::Entry) {
            auto ea = entryArgs.find(key);
            if (ea != entryArgs.end()) in = ea->second;
        } else {
            // ---- 普通 CFG 前驱出口的 join（同一上下文内） ----
            auto pp = preds[it.fun].find(it.node);
            if (pp != preds[it.fun].end()) {
                auto st = states.find(key);
                if (st != states.end())
                    for (int q : pp->second) {
                        auto qs = st->second.find(q);
                        if (qs != st->second.end())
                            in = constJoinEnv(in, qs->second);
                    }
            }
        }

        ConstEnv out = in;
        if (node.kind == CfgNode::Kind::Assign && node.stmt) {
            const auto *a = dynamic_cast<const AssignS *>(node.stmt);
            const auto *target =
                dynamic_cast<const VarRef *>(a->target.get());
            CallSite cs = asCallSite(node.stmt);
            if (target && !cs.callee.empty() && funs.count(cs.callee)) {
                // ---- 调用点：推进调用串、登记反向表、绑形参 ----
                Site site{it.fun, it.node};
                Ctx calleeCtx = pushTrunc(it.ctx, site, k);
                bool fresh = seenCtx[cs.callee].insert(calleeCtx).second;
                retCandidates[{calleeCtx, cs.callee}]
                    .push_back({it.ctx, site});

                // 实参在调用方环境求值后 join 进被调方形参绑定。
                ConstEnv &bind = entryArgs[{calleeCtx, cs.callee}];
                const std::vector<std::string> &params =
                    funs.at(cs.callee)->params;
                bool changedArgs = false;
                for (size_t i = 0; i < cs.call->args.size(); ++i) {
                    if (i >= params.size()) break;
                    Const v = evalConstExpr(cs.call->args[i].get(), in);
                    Const merged = cJoin(
                        bind.count(params[i]) ? bind[params[i]] : cBot(), v);
                    if (!(bind.count(params[i]) && bind[params[i]] == merged)) {
                        bind[params[i]] = merged;
                        changedArgs = true;
                    }
                }
                // 新上下文，或形参有了更"宽"的值：被调方入口重算。
                if (fresh || changedArgs)
                    enqueue(calleeCtx, cs.callee,
                            fcfgs.at(cs.callee)->entry);

                // 出口环境的目标变量 = 该(上下文, 站点)已累积的返回值；
                // 还没有则 ⊥：被调函数尚未返回，先按不可达传播，到达后重算。
                auto rv = retValues.find({it.ctx, site});
                out[target->name] = rv == retValues.end() ? cBot() : rv->second;
            } else if (target) {
                out[target->name] = evalConstExpr(a->value.get(), in);
            }
        } else if (node.kind == CfgNode::Kind::Return && node.stmt) {
            // ---- 返回边：查反向表，向所有匹配的调用方扇形回送 ----
            // k=0 时所有调用点的入口上下文都是 []，反向表里同一函数的
            // 多个 (δ, 站点) 全部命中——不同实参的返回值在各自站点被
            // join，这就是上下文不敏感分析必然 ⊤ 的原因，而且是显式可见的。
            const auto *r = dynamic_cast<const ReturnS *>(node.stmt);
            Const v = evalConstExpr(r->e.get(), in);
            auto rc = retCandidates.find(key);
            if (rc != retCandidates.end())
                for (const auto &[callerCtx, callerSite] : rc->second) {
                    auto rk = std::make_pair(callerCtx, callerSite);
                    Const merged = cJoin(
                        retValues.count(rk) ? retValues[rk] : cBot(), v);
                    if (!(retValues.count(rk) && retValues[rk] == merged)) {
                        retValues[rk] = merged;
                        enqueue(callerCtx, callerSite.first, callerSite.second);
                        for (int s : succs[callerSite.first][callerSite.second])
                            enqueue(callerCtx, callerSite.first, s);
                    }
                }
        }

        // ---- 与旧状态比较，变了才往后传 ----
        ConstPointEnv &st = states[key];
        auto old = st.find(it.node);
        if (old == st.end() || !(old->second == out)) {
            st[it.node] = out;
            for (int s : succs[it.fun][it.node]) enqueue(it.ctx, it.fun, s);
        }
    }

    for (const auto &[f, cs] : seenCtx)
        res.ctxCount[f] = static_cast<int>(cs.size());
    return res;
}

std::vector<std::pair<const OutputS *, Const>> outputPredictionsCtx(
    const Cfg &cfg, const ContextResult &r) {
    std::vector<std::pair<const OutputS *, Const>> preds;
    auto st = r.out.find({{}, "main"});
    if (st == r.out.end()) return preds;
    const FunCfg *mainCfg = nullptr;
    for (const FunCfg &fc : cfg.funs)
        if (fc.name == "main") mainCfg = &fc;
    if (!mainCfg) return preds;
    for (const auto &[id, node] : mainCfg->nodes) {
        const auto *o = dynamic_cast<const OutputS *>(node.stmt);
        if (!o) continue;
        auto env = st->second.find(id);
        if (env == st->second.end()) continue;
        preds.emplace_back(o, evalConstExpr(o->e.get(), env->second));
    }
    return preds;
}

}  // namespace tip
