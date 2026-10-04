#include "constant.hpp"

#include <deque>
#include <map>
#include <set>
#include <sstream>
#include <vector>

#include "pretty.hpp"

namespace tip {

std::string constShow(const Const &c) {
    if (c.kind == 0) return "BOT";
    if (c.kind == 2) return "TOP";
    return std::to_string(c.v);
}

Const cBot() { return Const{0, 0}; }
Const cTop() { return Const{2, 0}; }
Const cVal(int v) { return Const{1, v}; }

Const cJoin(const Const &a, const Const &b) {
    if (a.kind == 0) return b;
    if (b.kind == 0) return a;
    if (a == b) return a;
    return cTop();  // 两个不同常量：只能共同承诺"是某个整数"
}

ConstEnv constEntryEnv(const FunDecl &f) {
    ConstEnv env;
    for (const std::string &p : f.params) env[p] = cTop();
    return env;
}

ConstEnv constJoinEnv(const ConstEnv &a, const ConstEnv &b) {
    ConstEnv r = a;
    for (const auto &[k, v] : b) {
        auto it = r.find(k);
        r[k] = it == r.end() ? v : cJoin(it->second, v);
    }
    return r;
}

Const evalConstExpr(const Expr *e, const ConstEnv &env) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return cVal(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        auto it = env.find(x->name);
        return it == env.end() ? cBot() : it->second;
    }
    if (dynamic_cast<const InputE *>(e)) return cTop();  // 输入未知 → 非"确定常量"
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const Const l = evalConstExpr(x->l.get(), env);
        const Const r = evalConstExpr(x->r.get(), env);
        // 任一操作数 ⊥：此路径不可达，结果 ⊥（⊥ 吸收一切）。
        if (l.kind == 0 || r.kind == 0) return cBot();
        // 任一操作数 ⊤：即使另一个是常量，结果也随输入变化（除零在
        // 抽象层面无法排除，保守取 ⊤；具体除零属动态错误）。
        if (l.kind == 2 || r.kind == 2) return cTop();
        switch (x->op) {  // 两侧都是常量：具体折叠
            case BOp::Add: return cVal(l.v + r.v);
            case BOp::Sub: return cVal(l.v - r.v);
            case BOp::Mul: return cVal(l.v * r.v);
            case BOp::Div:
                if (r.v == 0) return cBot();  // 常量除零：该路径具体会抛错
                return cVal(l.v / r.v);
            case BOp::Gt: return cVal(l.v > r.v ? 1 : 0);
            case BOp::Eq: return cVal(l.v == r.v ? 1 : 0);
        }
    }
    return cTop();  // 调用/指针/记录：保守视为非常量
}

ConstEnv constTransferNode(const CfgNode &node, const ConstEnv &in) {
    if (node.kind != CfgNode::Kind::Assign || !node.stmt) return in;
    const auto *a = dynamic_cast<const AssignS *>(node.stmt);
    const auto *target = dynamic_cast<const VarRef *>(a->target.get());
    if (!target) return in;  // *p / r.f 目标：指针分析之前不处理
    ConstEnv out = in;
    out[target->name] = evalConstExpr(a->value.get(), in);
    return out;
}

ConstPointEnv solveConstFixpoint(const Cfg &cfg, const ProgramA &program) {
    ConstPointEnv cur;
    for (const FunCfg &fc : cfg.funs) {
        const FunDecl *decl = nullptr;
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();

        std::map<int, std::vector<int>> preds, succs;
        for (const auto &[from, to] : fc.edges) {
            succs[from].push_back(to);
            preds[to].push_back(from);
        }

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
                        if (auto it = cur.find(q); it != cur.end())
                            before = constJoinEnv(before, it->second);
                nv = constTransferNode(node, before);
            }

            auto old = cur.find(p);
            if (old == cur.end() || !(old->second == nv)) {
                cur[p] = nv;
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

std::string printConstEnv(const Cfg &cfg, const ProgramA &program,
                          const ConstPointEnv &states) {
    std::ostringstream out;
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";
        const FunDecl *decl = nullptr;
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();
        std::vector<std::string> names = decl->params;
        for (const std::string &v : decl->vars) names.push_back(v);

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
            const ConstEnv &env = states.at(id);
            for (const std::string &k : names)
                out << ' ' << k << '=' << constShow(env.count(k) ? env.at(k) : cBot());
            out << '\n';
        }
    }
    return out.str();
}

}  // namespace tip
