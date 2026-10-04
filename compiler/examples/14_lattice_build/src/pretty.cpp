#include "pretty.hpp"

#include <string>

namespace tip {

namespace {

// 表达式打印为前缀式：运算符与符号的对照表。
std::string exprText(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e)) return std::to_string(x->v);
    if (const auto *x = dynamic_cast<const VarRef *>(e)) return x->name;
    if (dynamic_cast<const InputE *>(e)) return "input";
    if (dynamic_cast<const NullE *>(e)) return "null";

    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        const char *sym = "+";
        switch (x->op) {
            case BOp::Add: sym = "+"; break;
            case BOp::Sub: sym = "-"; break;
            case BOp::Mul: sym = "*"; break;
            case BOp::Div: sym = "/"; break;
            case BOp::Gt: sym = ">"; break;
            case BOp::Eq: sym = "=="; break;
        }
        return "(" + std::string(sym) + " " + exprText(x->l.get()) + " " +
               exprText(x->r.get()) + ")";
    }
    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        std::string s = "(call " + exprText(x->callee.get());
        for (const auto &a : x->args) s += " " + exprText(a.get());
        return s + ")";
    }
    if (const auto *x = dynamic_cast<const Deref *>(e))
        return "(* " + exprText(x->e.get()) + ")";
    if (const auto *x = dynamic_cast<const AddrOf *>(e)) return "(& " + x->name + ")";
    if (const auto *x = dynamic_cast<const AllocE *>(e))
        return "(alloc " + exprText(x->e.get()) + ")";
    if (const auto *x = dynamic_cast<const FieldA *>(e))
        return "(. " + exprText(x->e.get()) + " " + x->field + ")";
    if (const auto *x = dynamic_cast<const RecLit *>(e)) {
        std::string s = "{";
        for (size_t i = 0; i < x->fields.size(); ++i) {
            if (i) s += ", ";
            s += x->fields[i].first + ": " + exprText(x->fields[i].second.get());
        }
        return s + "}";
    }
    return "<unknown expr>";
}

std::string indent(int level) { return std::string(static_cast<size_t>(level) * 2, ' '); }

// 语句打印带缩进，一条语句一行（块内多行）。
void stmtText(const Stmt *s, int level, std::string &out) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        out += indent(level) + exprText(x->target.get()) + " = " +
               exprText(x->value.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const OutputS *>(s)) {
        out += indent(level) + "output " + exprText(x->e.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const ReturnS *>(s)) {
        out += indent(level) + "return " + exprText(x->e.get()) + " ;\n";
        return;
    }
    if (const auto *x = dynamic_cast<const IfS *>(s)) {
        out += indent(level) + "if (" + exprText(x->cond.get()) + ")\n";
        stmtText(x->then.get(), level + 1, out);
        if (x->els) {
            out += indent(level) + "else\n";
            stmtText(x->els.get(), level + 1, out);
        }
        return;
    }
    if (const auto *x = dynamic_cast<const WhileS *>(s)) {
        out += indent(level) + "while (" + exprText(x->cond.get()) + ")\n";
        stmtText(x->body.get(), level + 1, out);
        return;
    }
    if (const auto *x = dynamic_cast<const BlockS *>(s)) {
        out += indent(level) + "{\n";
        for (const auto &st : x->ss) stmtText(st.get(), level + 1, out);
        out += indent(level) + "}\n";
        return;
    }
    out += indent(level) + "<unknown stmt>\n";
}

}  // namespace

std::string printExpr(const Expr *e) { return exprText(e); }

std::string printProgram(const ProgramA &program) {
    std::string out;
    for (const auto &f : program.funs) {
        std::string paramList;
        for (size_t i = 0; i < f->params.size(); ++i) {
            if (i) paramList += ",";
            paramList += f->params[i];
        }
        out += f->name + "(" + paramList + ") {\n";
        if (!f->vars.empty()) {
            out += indent(1) + "var ";
            for (size_t i = 0; i < f->vars.size(); ++i) {
                if (i) out += ",";
                out += f->vars[i];
            }
            out += " ;\n";
        }
        // 函数体是 BlockS；打印其内部语句而不是再嵌一层花括号。
        const auto *body = dynamic_cast<const BlockS *>(f->body.get());
        for (const auto &st : body->ss) stmtText(st.get(), 1, out);
        stmtText(f->ret.get(), 1, out);
        out += "}\n";
    }
    return out;
}

// 单行形式：CFG 节点标签等"节点旁边写一句话"的场合使用。
std::string printStmtLine(const Stmt &stmt) {
    std::string out;
    stmtText(&stmt, 0, out);
    if (!out.empty() && out.back() == '\n') out.pop_back();
    return out;
}

}  // namespace tip
