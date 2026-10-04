#include "coll.hpp"

#include <algorithm>
#include <deque>
#include <functional>
#include <map>
#include <set>
#include <sstream>
#include <utility>

#include "pretty.hpp"
#include "sign.hpp"

namespace tip {
namespace {

// ---------------- 具体表达式求值 ----------------
struct ConcEval {
    TraceEnv &env;
    std::deque<int> inputs;

    ConcEval(TraceEnv &e, std::vector<int> in) : env(e) {
        for (int v : in) inputs.push_back(v);
    }

    int value(const Expr *e) {
        if (const auto *x = dynamic_cast<const IntLit *>(e)) return x->v;
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            auto it = env.find(x->name);
            return it == env.end() ? 0 : it->second;
        }
        if (dynamic_cast<const InputE *>(e)) {
            int v = inputs.front();
            inputs.pop_front();
            return v;
        }
        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            int a = value(x->l.get());
            int b = value(x->r.get());
            switch (x->op) {
                case BOp::Add: return a + b;
                case BOp::Sub: return a - b;
                case BOp::Mul: return a * b;
                case BOp::Div: return a / b;
                case BOp::Gt: return a > b ? 1 : 0;
                case BOp::Eq: return a == b ? 1 : 0;
            }
        }
        return 0;
    }
};

int signOfConcrete(int v) {
    if (v < 0) return SMINUS;
    if (v == 0) return SZERO;
    return SPLUS;
}

// ---------------- 路径展开 ----------------
void runOneTrace(const Cfg &cfg, const ProgramA &program,
                 const std::vector<int> &inputStream, CollState &out) {
    std::map<std::string, const FunDecl *> decls;
    for (const auto &f : program.funs) decls[f->name] = f.get();

    for (const FunCfg &fc : cfg.funs) {
        const FunDecl *fd = decls.at(fc.name);
        std::map<int, std::vector<int>> succ;
        for (const auto &[a, b] : fc.edges) succ[a].push_back(b);
        for (auto &[a, bs] : succ) std::sort(bs.begin(), bs.end());

        TraceEnv env;
        for (const std::string &p : fd->params) env[p] = 0;
        for (const std::string &v : fd->vars) env[v] = 0;

        ConcEval ev(env, inputStream);
        PP cur{fc.name, fc.entry};
        int steps = 0;
        while (steps++ < 10000) {
            out[cur].insert(ev.env);
            const CfgNode &node = fc.nodes.at(cur.second);

            if (node.kind == CfgNode::Kind::Exit) break;

            if (node.kind == CfgNode::Kind::Assign) {
                const auto *a =
                    dynamic_cast<const AssignS *>(node.stmt);
                if (const auto *t =
                        dynamic_cast<const VarRef *>(a->target.get()))
                    ev.env[t->name] = ev.value(a->value.get());
            } else if (node.kind == CfgNode::Kind::Branch) {
                const auto *s = dynamic_cast<const IfS *>(node.stmt);
                const Expr *cond = nullptr;
                bool isWhile = false;
                if (s) {
                    cond = s->cond.get();
                } else {
                    const auto *w =
                        dynamic_cast<const WhileS *>(node.stmt);
                    cond = w->cond.get();
                    isWhile = true;
                }
                bool taken = ev.value(cond) != 0;
                const std::vector<int> &bs = succ[cur.second];
                int nextId = taken ? bs.front() : bs.back();
                (void)isWhile;
                cur = {fc.name, nextId};
                continue;
            }

            auto it = succ.find(cur.second);
            if (it == succ.end() || it->second.empty()) break;
            cur = {fc.name, it->second.front()};
        }
    }
}

// ---------------- 抽象：表达式的符号求值 ----------------
int abstractValue(const Expr *e,
                  const std::map<std::string, int> &signEnv) {
    if (const auto *x = dynamic_cast<const IntLit *>(e))
        return signOfConcrete(x->v);
    if (dynamic_cast<const InputE *>(e)) return STOP;
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        auto it = signEnv.find(x->name);
        return it == signEnv.end() ? SBOT : it->second;
    }
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        int a = abstractValue(x->l.get(), signEnv);
        int b = abstractValue(x->r.get(), signEnv);
        switch (x->op) {
            case BOp::Add: return sAdd(a, b);
            case BOp::Sub: return sSub(a, b);
            case BOp::Mul: return sMul(a, b);
            case BOp::Div: return sDiv(a, b);
            case BOp::Gt:
            case BOp::Eq: return sCompare(a, b);
        }
    }
    return SBOT;
}

}  // namespace

CollectResult collect(const Cfg &cfg, const ProgramA &program,
                      const std::vector<std::vector<int>> &inputStreams) {
    CollectResult r;
    for (const auto &stream : inputStreams) {
        runOneTrace(cfg, program, stream, r.state);
        ++r.runs;
    }
    return r;
}

GaloisResult runGalois(const Cfg &cfg, const ProgramA &program,
                       const CollectResult &collected,
                       const std::vector<int> &representatives) {
    GaloisResult g;
    SignLattice sl;

    std::set<std::string> allVars;
    std::map<std::string, const FunDecl *> decls;
    for (const auto &f : program.funs) {
        decls[f->name] = f.get();
        for (const std::string &v : f->vars) allVars.insert(v);
        for (const std::string &p : f->params) allVars.insert(p);
    }

    // α(C[[p]])：逐点对环境集合抽象。
    for (const auto &[pp, envs] : collected.state) {
        std::map<std::string, int> s;
        for (const std::string &v : allVars) s[v] = SBOT;
        for (const TraceEnv &e : envs)
            for (const auto &[name, val] : e)
                s[name] = sl.join(s[name], signOfConcrete(val));
        g.alphaCollection[pp] = std::move(s);
    }

    // A：CFG 上的单调符号分析。入口取 α(初始具体状态)：解释器（和 IR 生成
    // 器）都把每个变量初始化为 0，α 之后是全 0——这正是第 23 章方程组
    // "初值取具体初态的抽象"一行的实例。其余点从 ⊥ 升起。
    std::map<PP, std::map<std::string, int>> states;
    std::map<PP, std::vector<PP>> succ;
    for (const FunCfg &fc : cfg.funs) {
        for (const auto &[a, b] : fc.edges)
            succ[{fc.name, a}].push_back({fc.name, b});
        for (const auto &[id, node] : fc.nodes) {
            PP p{fc.name, id};
            std::map<std::string, int> e;
            for (const std::string &v : allVars)
                e[v] = id == fc.entry ? SZERO : SBOT;
            states[p] = std::move(e);
        }
    }

    std::deque<PP> wl;
    for (const auto &[p, e] : states) wl.push_back(p);
    while (!wl.empty()) {
        PP p = wl.front();
        wl.pop_front();
        const std::string &fun = p.first;
        const FunCfg *fc = nullptr;
        for (const FunCfg &x : cfg.funs)
            if (x.name == fun) fc = &x;
        const CfgNode &node = fc->nodes.at(p.second);

        std::map<std::string, int> after = states[p];
        if (node.kind == CfgNode::Kind::Assign) {
            const auto *a =
                dynamic_cast<const AssignS *>(node.stmt);
            if (const auto *t =
                    dynamic_cast<const VarRef *>(a->target.get())) {
                // 右端必须在赋值前的状态上求值：
                // i = i + 1 的右端 i 指的是赋值前的 i（先 kill 再求值会把
                // 自引用读成 ⊥，循环里 i 就永远不动了）。
                after[t->name] =
                    abstractValue(a->value.get(), states[p]);
            }
        }

        auto it = succ.find(p);
        if (it == succ.end()) continue;
        for (const PP &q : it->second) {
            bool changed = false;
            for (const std::string &v : allVars) {
                int old = states[q][v];
                int joined = sl.join(old, after[v]);
                if (!sl.eq(old, joined)) {
                    states[q][v] = joined;
                    changed = true;
                }
            }
            if (changed) wl.push_back(q);
        }
    }
    g.analysis = std::move(states);

    // 定理：α(C[[p]]) ⊑ A 逐点逐变量。
    g.theoremHolds = true;
    for (const auto &[pp, signs] : g.alphaCollection) {
        ++g.pointsCompared;
        for (const auto &[v, s] : signs) {
            int a = g.analysis.at(pp).at(v);
            if (!sl.leq(s, a)) g.theoremHolds = false;
        }
    }

    // 往返检验：收集到的每个环境都属于 γ(α(S))（用代表域枚举）。
    // γ 只在当前函数自己的变量上枚举：环境不含其他函数的变量。
    for (const auto &[pp, envs] : collected.state) {
        const std::map<std::string, int> &signs = g.alphaCollection.at(pp);
        const FunDecl *fd = decls.at(pp.first);
        std::vector<std::string> names;
        for (const std::string &v : fd->vars) names.push_back(v);
        for (const std::string &v : fd->params) names.push_back(v);

        std::set<TraceEnv> gamma;
        std::vector<std::pair<std::string, int>> chosen;
        std::function<void(size_t)> enumerate = [&](size_t i) {
            if (i == names.size()) {
                TraceEnv e;
                for (const auto &[name, val] : chosen) e[name] = val;
                gamma.insert(std::move(e));
                return;
            }
            int wanted = signs.at(names[i]);
            for (int r : representatives) {
                int rs = signOfConcrete(r);
                if (sl.leq(rs, wanted)) {
                    chosen.emplace_back(names[i], r);
                    enumerate(i + 1);
                    chosen.pop_back();
                }
            }
        };
        enumerate(0);

        for (const TraceEnv &e : envs) {
            ++g.envsTotal;
            if (gamma.count(e)) ++g.envsRoundtrip;
        }
    }
    return g;
}

namespace {

std::string showEnv(const TraceEnv &e) {
    std::ostringstream out;
    out << "{";
    bool first = true;
    for (const auto &[name, val] : e) {
        if (!first) out << ", ";
        out << name << "=" << val;
        first = false;
    }
    out << "}";
    return out.str();
}

}  // namespace

std::string printCollect(const Cfg &cfg, const ProgramA &program,
                         const CollectResult &r) {
    (void)program;
    std::ostringstream out;
    out << "== collecting semantics: environments per program point ==\n";
    out << "concrete input streams expanded: " << r.runs << "\n";
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        for (const auto &[id, node] : fc.nodes) {
            PP p{fc.name, id};
            out << "  " << id;
            if (node.stmt) out << " " << printStmtLine(*node.stmt);
            auto it = r.state.find(p);
            int n = it == r.state.end() ? 0 : static_cast<int>(it->second.size());
            out << ": " << n << " environment" << (n == 1 ? "" : "s") << "\n";
            if (it != r.state.end())
                for (const TraceEnv &e : it->second)
                    out << "      " << showEnv(e) << "\n";
        }
    }
    return out.str();
}

std::string printGalois(const GaloisResult &g) {
    std::ostringstream out;
    out << "== abstraction alpha of the collected states ==\n";
    for (const auto &[pp, signs] : g.alphaCollection) {
        out << "  " << pp.first << ":" << pp.second;
        for (const auto &[v, s] : signs)
            out << " " << v << "=" << signShow(s);
        out << "\n";
    }

    out << "== monotone sign analysis A (entry = alpha of initial state) ==\n";
    for (const auto &[pp, signs] : g.analysis) {
        out << "  " << pp.first << ":" << pp.second;
        for (const auto &[v, s] : signs)
            out << " " << v << "=" << signShow(s);
        out << "\n";
    }

    out << "== soundness theorem: alpha(C[[p]]) is below A ==\n";
    out << "  " << g.pointsCompared << " points compared; theorem "
        << (g.theoremHolds ? "HOLDS" : "FAILS") << "\n";

    out << "== Galois roundtrip: S is contained in gamma(alpha(S)) ==\n";
    out << "  " << g.envsRoundtrip << "/" << g.envsTotal
        << " collected environments reproduced on the representative domain\n";
    return out.str();
}

}  // namespace tip
