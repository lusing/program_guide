// file: src/interp.cpp
#include "interp.hpp"

#include <algorithm>
#include <iterator>

namespace tip {

// ---------- 环境链 ----------
Value *Environment::find(const std::string &name) {
    for (Environment *e = this; e; e = e->enclosing.get()) {
        auto it = e->values.find(name);
        if (it != e->values.end()) return &it->second;
    }
    return nullptr;
}

// ---------- 静态检查 ----------
std::vector<Diag> SemCheck::run(ProgramA &prog) {
    scopes_.assign(1, {});  // 第 0 层 = 全局函数表
    for (const auto &f : prog.funs) {
        if (funs_.count(f->name)) diags_.push_back({"全局函数重名：" + f->name, 0});
        funs_[f->name] = f.get();
        scopes_[0].insert(f->name);
    }
    for (const auto &f : prog.funs) {
        captured_.clear();  // 捕获豁免按顶层函数积累（嵌套字面量的捕获都算它的）
        checkFunBody(f->params, f->vars, *f->body, *f->ret->e, f->line);
    }
    return std::move(diags_);
}

void SemCheck::declare(const std::string &name, int line) {
    if (scopes_.back().count(name)) {
        diags_.push_back({"同层重复声明：" + name, line});
        return;  // 先声明者保留（与第 12 章口径一致）
    }
    scopes_.back().insert(name);
}

int SemCheck::resolve(const std::string &name) {
    for (int d = int(scopes_.size()) - 1; d >= 0; --d)
        if (scopes_[size_t(d)].count(name)) return d;
    return -1;
}

// 一个函数（顶层或字面量）体的完整检查：作用域栈压一层，确定赋值从
// "形参全部已赋值"起算，var 声明的变量从空起算。
void SemCheck::checkFunBody(const std::vector<std::string> &params,
                            const std::vector<std::string> &vars, const Stmt &body,
                            const Expr &ret, int line) {
    scopes_.push_back({});
    for (const auto &p : params) declare(p, line);  // 形参即"已赋值的局部"
    for (const auto &v : vars) declare(v, line);

    std::set<std::string> assigned(params.begin(), params.end());
    checkStmt(body, assigned);
    checkExpr(ret, assigned);
    scopes_.pop_back();
    // 捕获豁免的方向说明（正文 §13.5 详述）：captured_ 里的名字读值发生在
    // 未来某次闭包调用，检查的保守方向是"不误报"——豁免它们，宁漏报。
}

void SemCheck::checkStmt(const Stmt &s, std::set<std::string> &assigned) {
    if (const auto *x = dynamic_cast<const AssignS *>(&s)) {
        checkExpr(*x->value, assigned);
        if (auto *t = dynamic_cast<const VarRef *>(x->target.get())) {
            if (resolve(t->name) < 0) diags_.push_back({"未声明：" + t->name, t->line});
            assigned.insert(t->name);  // 直写变量：从此确定已赋值
        } else {
            checkExpr(*x->target, assigned);  // FieldA/Deref 目标：先查内部使用
        }
    } else if (const auto *x = dynamic_cast<const OutputS *>(&s)) {
        checkExpr(*x->e, assigned);
    } else if (const auto *x = dynamic_cast<const IfS *>(&s)) {
        checkExpr(*x->cond, assigned);
        std::set<std::string> a1 = assigned, a2 = assigned;
        checkStmt(*x->then, a1);
        if (x->els) checkStmt(*x->els, a2);
        // 汇合 = 交集：两支都赋了值，汇合点才确定已赋值
        std::set<std::string> join;
        std::set_intersection(a1.begin(), a1.end(), a2.begin(), a2.end(),
                              std::inserter(join, join.begin()));
        assigned = std::move(join);
    } else if (const auto *x = dynamic_cast<const WhileS *>(&s)) {
        checkExpr(*x->cond, assigned);
        std::set<std::string> body = assigned;
        checkStmt(*x->body, body);
        // 循环可能零次：汇合 = 进循环前 ∩ 循环后
        std::set<std::string> join;
        std::set_intersection(assigned.begin(), assigned.end(), body.begin(), body.end(),
                              std::inserter(join, join.begin()));
        assigned = std::move(join);
    } else if (const auto *x = dynamic_cast<const BlockS *>(&s)) {
        // 块不声明变量（TIP 声明只在函数头），语句顺序传播
        for (const auto &st : x->ss) checkStmt(*st, assigned);
    }
}

void SemCheck::checkExpr(const Expr &e, std::set<std::string> &assigned) {
    if (const auto *x = dynamic_cast<const VarRef *>(&e)) {
        int d = resolve(x->name);
        if (d < 0) {
            diags_.push_back({"未声明：" + x->name, x->line});
        } else if (d > 0) {  // 局部（含参数）才受确定赋值约束；全局函数恒有值
            if (!assigned.count(x->name) && !captured_.count(x->name))
                diags_.push_back({"使用前未赋值：" + x->name, x->line});
        }
    } else if (const auto *x = dynamic_cast<const Binop *>(&e)) {
        checkExpr(*x->l, assigned);
        checkExpr(*x->r, assigned);
    } else if (const auto *x = dynamic_cast<const CallE *>(&e)) {
        checkExpr(*x->callee, assigned);
        for (const auto &a : x->args) checkExpr(*a, assigned);
        // 直接调用全局函数：元数静态可查（闭包调用留运行时兜底）
        if (auto *fn = dynamic_cast<const VarRef *>(x->callee.get())) {
            auto it = funs_.find(fn->name);
            if (it != funs_.end() && it->second->params.size() != x->args.size())
                diags_.push_back({"元数不符：" + fn->name + " 期望 " +
                                      std::to_string(it->second->params.size()) + " 实得 " +
                                      std::to_string(x->args.size()),
                                  x->line});
        }
    } else if (const auto *x = dynamic_cast<const Deref *>(&e)) {
        checkExpr(*x->e, assigned);
    } else if (const auto *x = dynamic_cast<const AllocE *>(&e)) {
        checkExpr(*x->e, assigned);
    } else if (const auto *x = dynamic_cast<const RecLit *>(&e)) {
        for (const auto &f : x->fields) checkExpr(*f.second, assigned);
    } else if (const auto *x = dynamic_cast<const FieldA *>(&e)) {
        checkExpr(*x->e, assigned);
    } else if (const auto *x = dynamic_cast<const FunLit *>(&e)) {
        // 次序关键：先收集捕获（体内引用的外层局部名 → 豁免外层确定赋值），
        // 再进字面量自己的作用域做诊断——否则对合法捕获会误报"未赋值"。
        scopes_.push_back({});
        for (const auto &p : x->params) scopes_.back().insert(p);
        for (const auto &v : x->vars) scopes_.back().insert(v);
        int myDepth = int(scopes_.size()) - 1;
        collectCapturedStmt(*x->body, myDepth);
        collectCapturedExpr(*x->ret, myDepth);
        scopes_.pop_back();

        checkFunBody(x->params, x->vars, *x->body, *x->ret, x->line);
    }
    // IntLit/InputE/NullE/AddrOf：无局部使用（AddrOf 的名字是全局函数引用）
}

// 捕获收集：在字面量作用域（已压栈）视角下，凡是解析到更外层"局部"
// （层数 1..myDepth-1）的名字都是捕获——字面量创建时不读值，读值发生在
// 未来调用，因此外层的确定赋值对它们放行。
void SemCheck::collectCapturedExpr(const Expr &e, int myDepth) {
    if (const auto *x = dynamic_cast<const VarRef *>(&e)) {
        int d = resolve(x->name);
        if (d >= 1 && d < myDepth) captured_.insert(x->name);
    } else if (const auto *x = dynamic_cast<const Binop *>(&e)) {
        collectCapturedExpr(*x->l, myDepth);
        collectCapturedExpr(*x->r, myDepth);
    } else if (const auto *x = dynamic_cast<const CallE *>(&e)) {
        collectCapturedExpr(*x->callee, myDepth);
        for (const auto &a : x->args) collectCapturedExpr(*a, myDepth);
    } else if (const auto *x = dynamic_cast<const Deref *>(&e)) {
        collectCapturedExpr(*x->e, myDepth);
    } else if (const auto *x = dynamic_cast<const AllocE *>(&e)) {
        collectCapturedExpr(*x->e, myDepth);
    } else if (const auto *x = dynamic_cast<const RecLit *>(&e)) {
        for (const auto &f : x->fields) collectCapturedExpr(*f.second, myDepth);
    } else if (const auto *x = dynamic_cast<const FieldA *>(&e)) {
        collectCapturedExpr(*x->e, myDepth);
    } else if (const auto *x = dynamic_cast<const FunLit *>(&e)) {
        scopes_.push_back({});
        for (const auto &p : x->params) scopes_.back().insert(p);
        for (const auto &v : x->vars) scopes_.back().insert(v);
        collectCapturedStmt(*x->body, int(scopes_.size()) - 1);
        collectCapturedExpr(*x->ret, int(scopes_.size()) - 1);
        scopes_.pop_back();
    }
}

void SemCheck::collectCapturedStmt(const Stmt &s, int myDepth) {
    if (const auto *x = dynamic_cast<const AssignS *>(&s)) {
        collectCapturedExpr(*x->value, myDepth);
        if (auto *t = dynamic_cast<const VarRef *>(x->target.get())) {
            int d = resolve(t->name);  // 写捕获同样算捕获（计数器靠它）
            if (d >= 1 && d < myDepth) captured_.insert(t->name);
        } else {
            collectCapturedExpr(*x->target, myDepth);
        }
    } else if (const auto *x = dynamic_cast<const OutputS *>(&s)) {
        collectCapturedExpr(*x->e, myDepth);
    } else if (const auto *x = dynamic_cast<const IfS *>(&s)) {
        collectCapturedExpr(*x->cond, myDepth);
        collectCapturedStmt(*x->then, myDepth);
        if (x->els) collectCapturedStmt(*x->els, myDepth);
    } else if (const auto *x = dynamic_cast<const WhileS *>(&s)) {
        collectCapturedExpr(*x->cond, myDepth);
        collectCapturedStmt(*x->body, myDepth);
    } else if (const auto *x = dynamic_cast<const BlockS *>(&s)) {
        for (const auto &st : x->ss) collectCapturedStmt(*st, myDepth);
    }
}

// ---------- 解释器 ----------
Interpreter::Interpreter(ProgramA &prog) : prog_(prog) {
    globals_ = newEnv(nullptr);
    for (const auto &f : prog_.funs) {
        auto clo = std::make_shared<Closure>();
        clo->decl = f.get();
        clo->env = globals_;
        globals_->define(f->name, Value::fun(std::move(clo)));
    }
}

std::shared_ptr<Environment> Interpreter::newEnv(std::shared_ptr<Environment> parent) {
    ++envCreated_;
    return std::make_shared<Environment>(std::move(parent));
}

Value Interpreter::run(const std::string &entry, std::vector<Value> args, std::ostream &out) {
    out_ = &out;
    Value *v = globals_->find(entry);
    if (!v || v->tag != Value::Tag::Closure)
        throw InterpError{"入口函数不存在：" + entry, 0};
    return callClosure(*v->clo, std::move(args), 0);
}

Value Interpreter::callClosure(const Closure &c, std::vector<Value> args, int line) {
    if (int(args.size()) != c.paramCount())
        throw InterpError{"元数不符（运行时）：期望 " + std::to_string(c.paramCount()) +
                              " 实得 " + std::to_string(args.size()),
                          line};
    auto env = newEnv(c.env);  // 新帧：父链指向"定义时环境"，不是调用者！
    const auto &params = c.decl ? c.decl->params : c.lit->params;
    const auto &vars = c.decl ? c.decl->vars : c.lit->vars;
    for (size_t k = 0; k < params.size(); ++k) env->define(params[k], args[k]);
    for (const auto &v : vars) env->define(v, Value::num(0));  // 声明即占位（0）
    const Stmt &body = c.decl ? *c.decl->body : *c.lit->body;
    const Expr &ret = c.decl ? *c.decl->ret->e : *c.lit->ret;
    // 函数体本身就是 BlockS（构建器保证）——它就是本次调用的作用域环境，
    // 语句直接在 env 里执行，不再为体包一层块环境（否则每次调用双重建链）。
    auto *bb = dynamic_cast<const BlockS *>(&body);
    if (bb) {
        for (const auto &st : bb->ss) exec(*st, *env);
    } else {
        exec(body, *env);
    }
    return eval(ret, *env);
}

void Interpreter::exec(const Stmt &s, Environment &env) {
    if (const auto *x = dynamic_cast<const AssignS *>(&s)) {
        Value v = eval(*x->value, env);
        if (auto *t = dynamic_cast<const VarRef *>(x->target.get())) {
            Value *slot = env.find(t->name);  // 赋值沿链写回：找定义处
            if (!slot) throw InterpError{"未定义变量：" + t->name, t->line};
            *slot = v;  // 就地写——闭包共享由此而来
        } else {
            throw InterpError{"字段/指针赋值本章不支持（语料口径）", x->line};
        }
    } else if (const auto *x = dynamic_cast<const OutputS *>(&s)) {
        Value v = eval(*x->e, env);
        *out_ << v.i << "\n";
    } else if (const auto *x = dynamic_cast<const IfS *>(&s)) {
        if (eval(*x->cond, env).i != 0) exec(*x->then, env);
        else if (x->els) exec(*x->els, env);
    } else if (const auto *x = dynamic_cast<const WhileS *>(&s)) {
        while (eval(*x->cond, env).i != 0) exec(*x->body, env);
    } else if (const auto *x = dynamic_cast<const BlockS *>(&s)) {
        auto block = newEnv(env.shared_from_this());  // 块即子环境：进建退弃
        // 块内没有声明（TIP 声明在函数头）；块环境的意义见正文 §13.2
        for (const auto &st : x->ss) exec(*st, *block);
    }
}

Value Interpreter::eval(const Expr &e, Environment &env) {
    if (const auto *x = dynamic_cast<const IntLit *>(&e)) return Value::num(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(&e)) {
        Value *v = env.find(x->name);  // 取值沿链：从当前层向定义处爬
        if (!v) throw InterpError{"未定义变量：" + x->name, x->line};
        return *v;
    }
    if (dynamic_cast<const InputE *>(&e)) return Value::num(0);  // 确定性桩
    if (const auto *x = dynamic_cast<const Binop *>(&e)) {
        long long l = eval(*x->l, env).i, r = eval(*x->r, env).i;
        switch (x->op) {
            case BOp::Add: return Value::num(l + r);
            case BOp::Sub: return Value::num(l - r);
            case BOp::Mul: return Value::num(l * r);
            case BOp::Div:
                if (r == 0) throw InterpError{"除零", 0};
                return Value::num(l / r);
            case BOp::Gt: return Value::num(l > r ? 1 : 0);
            case BOp::Eq: return Value::num(l == r ? 1 : 0);
        }
    }
    if (const auto *x = dynamic_cast<const CallE *>(&e)) {
        Value callee = eval(*x->callee, env);
        std::vector<Value> args;
        for (const auto &a : x->args) args.push_back(eval(*a, env));
        if (callee.tag != Value::Tag::Closure)
            throw InterpError{"被调者不是函数", x->line};
        return callClosure(*callee.clo, std::move(args), x->line);
    }
    if (const auto *x = dynamic_cast<const FunLit *>(&e)) {
        auto clo = std::make_shared<Closure>();
        clo->lit = x;
        clo->env = env.shared_from_this();  // 定义时环境——闭包的全部秘密在此一行
        return Value::fun(std::move(clo));
    }
    throw InterpError{"本章不求值该表达式种类", 0};
}

}  // namespace tip
