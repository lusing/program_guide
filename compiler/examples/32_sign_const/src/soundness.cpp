#include "soundness.hpp"

#include <map>
#include <stdexcept>

namespace tip {
namespace {

struct Machine {
    const ProgramA &program;
    std::vector<int> inputs;
    size_t inputPos = 0;
    ConcreteRun run;

    int readInput() {
        if (inputPos >= inputs.size())
            throw std::runtime_error("inputs exhausted");
        return inputs[inputPos++];
    }

    int eval(const Expr *e, std::map<std::string, int> &env) {
        if (const auto *x = dynamic_cast<const IntLit *>(e)) return x->v;
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            auto it = env.find(x->name);
            if (it == env.end()) throw std::runtime_error("unbound " + x->name);
            return it->second;
        }
        if (dynamic_cast<const InputE *>(e)) return readInput();
        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            const int l = eval(x->l.get(), env);
            const int r = eval(x->r.get(), env);
            switch (x->op) {
                case BOp::Add: return l + r;
                case BOp::Sub: return l - r;
                case BOp::Mul: return l * r;
                case BOp::Div:
                    if (r == 0) throw std::runtime_error("division by zero");
                    return l / r;
                case BOp::Gt: return l > r ? 1 : 0;
                case BOp::Eq: return l == r ? 1 : 0;
            }
        }
        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            const auto *fn = dynamic_cast<const VarRef *>(x->callee.get());
            const FunDecl *decl = nullptr;
            for (const auto &f : program.funs)
                if (f->name == fn->name) decl = f.get();
            std::map<std::string, int> local;
            for (size_t i = 0; i < decl->params.size(); ++i)
                local[decl->params[i]] = eval(x->args[i].get(), env);
            execBody(*decl, local);
            return local["\x01ret"];
        }
        throw std::runtime_error("interpret: unsupported expression");
    }

    void execBody(const FunDecl &f, std::map<std::string, int> &env) {
        const auto *body = dynamic_cast<const BlockS *>(f.body.get());
        for (const auto &s : body->ss) execStmt(s.get(), env);
        if (f.ret) env["\x01ret"] = eval(f.ret->e.get(), env);
    }

    void execStmt(const Stmt *s, std::map<std::string, int> &env) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            const auto *t = dynamic_cast<const VarRef *>(x->target.get());
            env[t->name] = eval(x->value.get(), env);
            return;
        }
        if (const auto *x = dynamic_cast<const OutputS *>(s)) {
            run.values.push_back(eval(x->e.get(), env));
            run.sites.push_back(x);
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            if (eval(x->cond.get(), env) != 0) execStmt(x->then.get(), env);
            else if (x->els) execStmt(x->els.get(), env);
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            while (eval(x->cond.get(), env) != 0) execStmt(x->body.get(), env);
            return;
        }
        if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &y : x->ss) execStmt(y.get(), env);
            return;
        }
        if (dynamic_cast<const ReturnS *>(s))
            return;  // 返回值统一在函数体末尾求值；TIP 的 return 位于函数尾部
        throw std::runtime_error("interpret: unsupported statement");
    }
};

}  // namespace

ConcreteRun interpret(const ProgramA &program, const std::vector<int> &inputs) {
    Machine m{program, inputs, 0, {}};
    const FunDecl *mainFn = nullptr;
    for (const auto &f : program.funs)
        if (f->name == "main") mainFn = f.get();
    std::map<std::string, int> env;  // main 无参：空环境
    m.execBody(*mainFn, env);
    return std::move(m.run);
}

}  // namespace tip
