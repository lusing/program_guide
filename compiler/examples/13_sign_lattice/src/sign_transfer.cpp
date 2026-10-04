#include "sign_transfer.hpp"

#include <map>
#include <set>
#include <sstream>
#include <vector>

#include "pretty.hpp"
#include "sign.hpp"

namespace tip {

int signOfLiteral(int v) {
    if (v < 0) return SMINUS;
    if (v == 0) return SZERO;
    return SPLUS;
}

int evalExprSign(const Expr *e, const SignEnv &env) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return signOfLiteral(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        auto it = env.find(x->name);
        return it == env.end() ? SBOT : it->second;
    }
    if (dynamic_cast<const InputE *>(e)) return STOP;  // 输入流的下一个整数符号未知
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const int l = evalExprSign(x->l.get(), env);
        const int r = evalExprSign(x->r.get(), env);
        switch (x->op) {
            case BOp::Add: return sAdd(l, r);
            case BOp::Sub: return sSub(l, r);
            case BOp::Mul: return sMul(l, r);
            case BOp::Div: return sDiv(l, r);
            case BOp::Gt:
            case BOp::Eq: return sCompare(l, r);
        }
    }
    // 函数调用的返回值、指针/记录相关表达式：本章按"任意整数"保守处理，
    // 精确分析在过程间（第 23 章起）与指针篇（第 28 章）给出。
    (void)e;
    return STOP;
}

SignEnv entryEnv(const FunDecl &f) {
    SignEnv env;
    for (const std::string &p : f.params) env[p] = STOP;  // 调用方实参符号未知
    return env;
}

SignEnv joinEnv(const SignEnv &a, const SignEnv &b) {
    SignEnv r = a;
    SignLattice lat;
    for (const auto &[k, v] : b) {
        auto it = r.find(k);
        r[k] = it == r.end() ? v : lat.join(it->second, v);
    }
    return r;
}

SignEnv transferNode(const CfgNode &node, const SignEnv &in) {
    if (node.kind != CfgNode::Kind::Assign || !node.stmt) return in;
    const auto *a = dynamic_cast<const AssignS *>(node.stmt);
    const auto *target = dynamic_cast<const VarRef *>(a->target.get());
    if (!target) return in;  // *p / r.f 目标：第 28 章指针分析之前保持环境不变
    SignEnv out = in;
    out[target->name] = evalExprSign(a->value.get(), in);
    return out;
}

namespace {

std::map<int, std::vector<int>> predecessorMap(const FunCfg &f) {
    std::map<int, std::vector<int>> preds;
    for (const auto &[from, to] : f.edges) preds[to].push_back(from);
    return preds;
}

const char *nodeLabel(CfgNode::Kind kind) {
    switch (kind) {
        case CfgNode::Kind::Entry: return "entry";
        case CfgNode::Kind::Exit: return "exit";
        case CfgNode::Kind::Assign: return "assign";
        case CfgNode::Kind::Output: return "output";
        case CfgNode::Kind::Branch: return "branch";
        case CfgNode::Kind::Return: return "return";
    }
    return "?";
}

}  // namespace

PointEnv singlePass(const Cfg &cfg, const ProgramA &program) {
    PointEnv states;
    for (const FunCfg &fc : cfg.funs) {
        const FunDecl *decl = nullptr;
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();

        const auto preds = predecessorMap(fc);
        for (const auto &[id, node] : fc.nodes) {
            if (node.kind == CfgNode::Kind::Entry) {
                states[id] = entryEnv(*decl);  // 边界条件：参数 ⊤
                continue;
            }
            // 前驱尚未计算（典型是循环回边）时其状态按全 ⊥（空环境）处理。
            SignEnv in;
            auto pit = preds.find(id);
            if (pit != preds.end()) {
                for (int q : pit->second) {
                    auto qit = states.find(q);
                    if (qit != states.end()) in = joinEnv(in, qit->second);
                }
            }
            states[id] = transferNode(node, in);
        }
    }
    return states;
}

std::string printPointEnv(const Cfg &cfg, const ProgramA &program,
                          const PointEnv &states) {
    std::ostringstream out;
    for (const FunCfg &fc : cfg.funs) {
        out << "-- " << fc.name << " --\n";

        const FunDecl *decl = nullptr;  // 变量打印顺序：参数在前，局部变量在后
        for (const auto &f : program.funs)
            if (f->name == fc.name) decl = f.get();
        std::vector<std::string> names = decl->params;
        for (const std::string &v : decl->vars) names.push_back(v);

        for (const auto &[id, node] : fc.nodes) {
            out << "  " << id << ' ' << nodeLabel(node.kind);
            if (node.kind == CfgNode::Kind::Branch && node.stmt) {
                // 分支点只标注条件，避免把整个 if/while 体压成一行又折行。
                if (const auto *w = dynamic_cast<const WhileS *>(node.stmt))
                    out << "  while " << printExpr(w->cond.get());
                else if (const auto *i = dynamic_cast<const IfS *>(node.stmt))
                    out << "  if " << printExpr(i->cond.get());
            } else if (node.stmt) {
                out << "  " << printStmtLine(*node.stmt);
            }
            out << ':';

            const SignEnv &env = states.at(id);
            for (const std::string &k : names) {
                auto it = env.find(k);
                out << ' ' << k << '='
                    << signShow(it == env.end() ? SBOT : it->second);
            }
            out << '\n';
        }
    }
    return out.str();
}

}  // namespace tip
