#include "constraints.hpp"

#include <algorithm>
#include <utility>

namespace tip {
namespace {

struct Collector {
    const Bindings *bindings;
    Collected out;
    std::vector<std::string> allFields;

    Tp varOf(const Expr *e) {
        auto it = out.node.find(e);
        if (it != out.node.end()) return it->second;
        Tp t = tvar();
        out.node.emplace(e, t);
        return t;
    }

    void eq(Tp a, Tp b, std::string why) {
        out.cons.push_back(Con{std::move(a), std::move(b), std::move(why)});
    }

    void genExpr(const Expr *e) {
        Tp t = varOf(e);

        if (const auto *x = dynamic_cast<const IntLit *>(e)) {
            (void)x;
            eq(t, tint(), "整数字面量");
            return;
        }
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            eq(t, out.decl.at(bindings->uses.at(x)), "变量使用");
            return;
        }
        if (dynamic_cast<const InputE *>(e)) {
            eq(t, tint(), "input 是整数");
            return;
        }
        if (dynamic_cast<const NullE *>(e))
            // null 的规则在第 27 章总装时补入（与任意 ptr 相容）。
            return;

        if (const auto *x = dynamic_cast<const Binop *>(e)) {
            genExpr(x->l.get());
            genExpr(x->r.get());
            eq(varOf(x->l.get()), tint(), "二元运算左操作数为 int");
            eq(varOf(x->r.get()), tint(), "二元运算右操作数为 int");
            eq(t, tint(),
               x->op == BOp::Gt || x->op == BOp::Eq ? "比较结果为 int(0/1)" : "算术结果为 int");
            return;
        }

        if (const auto *x = dynamic_cast<const CallE *>(e)) {
            // 被调位置可以是任意表达式；参数按序生成。
            genExpr(x->callee.get());
            for (const auto &a : x->args) genExpr(a.get());
            std::vector<Tp> ps;
            for (const auto &a : x->args) ps.push_back(varOf(a.get()));
            Tp ft = std::make_shared<TyFun>(std::move(ps), t);
            eq(varOf(x->callee.get()), ft, "被调表达式须为接受这些实参、返回 τ 的函数");
            return;
        }

        if (const auto *x = dynamic_cast<const AllocE *>(e)) {
            genExpr(x->e.get());
            eq(t, std::make_shared<TyPtr>(varOf(x->e.get())), "alloc E 的类型是 ptr(τ(E))");
            return;
        }
        if (const auto *x = dynamic_cast<const Deref *>(e)) {
            genExpr(x->e.get());
            eq(varOf(x->e.get()), std::make_shared<TyPtr>(t), "对 *E：τ(E)=ptr(τ)");
            return;
        }
        if (const auto *x = dynamic_cast<const AddrOf *>(e)) {
            // &Id：在当前函数作用域（含全局父作用域）里找到该声明。
            const Symbol *s = nullptr;
            for (const auto &scope : bindings->scopes) {
                auto it = scope->table.find(x->name);
                if (it != scope->table.end()) { s = &it->second; break; }
            }
            if (!s) {
                auto it = bindings->global.table.find(x->name);
                if (it != bindings->global.table.end()) s = &it->second;
            }
            eq(t, std::make_shared<TyPtr>(out.decl.at(s)), "&Id 的类型是 ptr(声明类型)");
            return;
        }

        if (const auto *x = dynamic_cast<const RecLit *>(e)) {
            std::vector<std::pair<std::string, Tp>> fs;
            for (const auto &kv : x->fields) {
                genExpr(kv.second.get());
                fs.emplace_back(kv.first, varOf(kv.second.get()));
            }
            eq(t, std::make_shared<TyRec>(std::move(fs)), "记录构造的字段逐个对应");
            return;
        }
        if (const auto *x = dynamic_cast<const FieldA *>(e)) {
            genExpr(x->e.get());
            // spa：记录须含字段 f: τ；其余字段名以新鲜变量占位。
            std::vector<std::pair<std::string, Tp>> fs;
            for (const std::string &name : allFields) {
                if (name == x->field)
                    fs.emplace_back(name, t);
                else
                    fs.emplace_back(name, tvar());
            }
            eq(varOf(x->e.get()), std::make_shared<TyRec>(std::move(fs)),
               "字段访问：记录须含 " + x->field);
            return;
        }
    }

    void genStmt(const Stmt *s) {
        if (const auto *x = dynamic_cast<const AssignS *>(s)) {
            genExpr(x->value.get());
            genExpr(x->target.get());
            eq(varOf(x->target.get()), varOf(x->value.get()), "赋值左右类型相同");
            return;
        }
        if (const auto *x = dynamic_cast<const OutputS *>(s)) {
            genExpr(x->e.get());
            eq(varOf(x->e.get()), tint(), "output 的值是 int");
            return;
        }
        if (const auto *x = dynamic_cast<const IfS *>(s)) {
            genExpr(x->cond.get());
            eq(varOf(x->cond.get()), tint(), "if 条件是 int");
            genStmt(x->then.get());
            if (x->els) genStmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const WhileS *>(s)) {
            genExpr(x->cond.get());
            eq(varOf(x->cond.get()), tint(), "while 条件是 int");
            genStmt(x->body.get());
            return;
        }
        if (const auto *x = dynamic_cast<const BlockS *>(s)) {
            for (const auto &st : x->ss) genStmt(st.get());
            return;
        }
        if (const auto *x = dynamic_cast<const ReturnS *>(s)) {
            genExpr(x->e.get());  // return 表达式在函数级约束中连接
        }
    }
};

void gatherFields(const Expr *e, std::vector<std::string> &names) {
    if (const auto *x = dynamic_cast<const RecLit *>(e))
        for (const auto &kv : x->fields) {
            if (std::find(names.begin(), names.end(), kv.first) == names.end())
                names.push_back(kv.first);
            gatherFields(kv.second.get(), names);
        }
    if (const auto *x = dynamic_cast<const FieldA *>(e)) {
        if (std::find(names.begin(), names.end(), x->field) == names.end())
            names.push_back(x->field);
        gatherFields(x->e.get(), names);
    }
    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        gatherFields(x->l.get(), names);
        gatherFields(x->r.get(), names);
    }
    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        gatherFields(x->callee.get(), names);
        for (const auto &a : x->args) gatherFields(a.get(), names);
    }
    if (const auto *x = dynamic_cast<const AllocE *>(e)) gatherFields(x->e.get(), names);
    if (const auto *x = dynamic_cast<const Deref *>(e)) gatherFields(x->e.get(), names);
}

}  // namespace

Collected collect(const ProgramA &program, const Bindings &bindings) {
    Collector c;
    c.bindings = &bindings;

    // 第一遍：收集程序中出现过的全部字段名（字段访问的记录形状需要）。
    for (const auto &f : program.funs) {
        gatherFields(f->ret->e.get(), c.allFields);
        for (const auto &st : dynamic_cast<const BlockS *>(f->body.get())->ss) {
            // 语句内的字段收集
            const Stmt *s = st.get();
            if (const auto *a = dynamic_cast<const AssignS *>(s)) {
                gatherFields(a->target.get(), c.allFields);
                gatherFields(a->value.get(), c.allFields);
            } else if (const auto *a = dynamic_cast<const OutputS *>(s)) {
                gatherFields(a->e.get(), c.allFields);
            } else if (const auto *a = dynamic_cast<const IfS *>(s)) {
                gatherFields(a->cond.get(), c.allFields);
            } else if (const auto *a = dynamic_cast<const WhileS *>(s)) {
                gatherFields(a->cond.get(), c.allFields);
            }
        }
    }

    // 第二遍 A：为全部函数建类型（形参/var 新鲜变量）并登记函数名，
    // 这样函数体互相前向调用时被调函数的类型已在 decl 中。
    std::vector<Tp> funTypes;
    for (size_t i = 0; i < program.funs.size(); ++i) {
        const FunDecl *f = program.funs[i].get();
        std::vector<Tp> ps;
        for (size_t j = 0; j < f->params.size(); ++j) ps.push_back(tvar());
        Tp retVar = tvar();
        Tp ft = std::make_shared<TyFun>(ps, retVar);

        for (size_t j = 0; j < f->params.size(); ++j) {
            const Symbol *s = &bindings.scopes[i]->table.at(f->params[j]);
            c.out.decl[s] = ps[j];
        }
        for (const std::string &v : f->vars) {
            const Symbol *s = &bindings.scopes[i]->table.at(v);
            c.out.decl[s] = tvar();
        }
        for (const auto &kv : bindings.global.table)
            if (kv.second.kind == Symbol::Fun && kv.second.name == f->name)
                c.out.decl[&kv.second] = ft;
        funTypes.push_back(ft);
    }

    // 第二遍 B：按函数顺序走函数体与 return。
    for (size_t i = 0; i < program.funs.size(); ++i) {
        const FunDecl *f = program.funs[i].get();
        for (const auto &st : dynamic_cast<const BlockS *>(f->body.get())->ss)
            c.genStmt(st.get());

        c.genExpr(f->ret->e.get());
        const auto *ft = dynamic_cast<const TyFun *>(funTypes[i].get());
        c.eq(ft->ret, c.varOf(f->ret->e.get()), "return 表达式确定返回类型");
    }
    return c.out;
}

}  // namespace tip
