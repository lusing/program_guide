// 第 12 章配套程序：解析 -> AST -> 名字解析，
// 无诊断时按函数打印每个变量使用点的绑定结果；有诊断时打印诊断并以 3 退出。
#include <fstream>
#include <iostream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line, size_t column,
                     const std::string &msg, std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

namespace {

// 为打印绑定结果再走一遍 AST；使用点的输出顺序由此固定。
struct UsePrinter {
    const tip::Bindings &bindings;
    int counter = 0;

    void line(const tip::VarRef *ref) {
        const tip::Symbol *s = bindings.uses.at(ref);
        std::string kind;
        if (s->kind == tip::Symbol::Fun) kind = "fun";
        else kind = (s->kind == tip::Symbol::Param ? "param" : "local");
        std::cout << "use " << ++counter << ": " << ref->name << " -> " << kind;
        if (s->kind != tip::Symbol::Fun) std::cout << " in " << s->fun->name;
        std::cout << '\n';
    }

    void expr(const tip::Expr *e) {
        if (const auto *x = dynamic_cast<const tip::VarRef *>(e)) return line(x);
        if (const auto *x = dynamic_cast<const tip::Binop *>(e)) {
            expr(x->l.get()); expr(x->r.get()); return;
        }
        if (const auto *x = dynamic_cast<const tip::CallE *>(e)) {
            expr(x->callee.get());
            for (const auto &a : x->args) expr(a.get());
            return;
        }
        if (const auto *x = dynamic_cast<const tip::Deref *>(e)) return expr(x->e.get());
        if (const auto *x = dynamic_cast<const tip::AllocE *>(e)) return expr(x->e.get());
        if (const auto *x = dynamic_cast<const tip::FieldA *>(e)) return expr(x->e.get());
        if (const auto *x = dynamic_cast<const tip::RecLit *>(e)) {
            for (const auto &f : x->fields) expr(f.second.get());
        }
    }
    void stmt(const tip::Stmt *s) {
        if (const auto *x = dynamic_cast<const tip::AssignS *>(s)) {
            expr(x->target.get()); expr(x->value.get()); return;
        }
        if (const auto *x = dynamic_cast<const tip::OutputS *>(s)) return expr(x->e.get());
        if (const auto *x = dynamic_cast<const tip::IfS *>(s)) {
            expr(x->cond.get()); stmt(x->then.get());
            if (x->els) stmt(x->els.get());
            return;
        }
        if (const auto *x = dynamic_cast<const tip::WhileS *>(s)) {
            expr(x->cond.get()); stmt(x->body.get()); return;
        }
        if (const auto *x = dynamic_cast<const tip::BlockS *>(s)) {
            for (const auto &st : x->ss) stmt(st.get());
            return;
        }
        if (const auto *x = dynamic_cast<const tip::ReturnS *>(s)) return expr(x->e.get());
    }
};

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    std::ifstream src(argv[2]);
    if (!src) {
        std::cerr << "cannot open " << argv[2] << '\n';
        return 1;
    }

    antlr4::ANTLRInputStream input(src);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    TIPParser parser(&tokens);

    CollectErrorListener errors;
    lexer.removeErrorListeners();
    parser.removeErrorListeners();
    lexer.addErrorListener(&errors);
    parser.addErrorListener(&errors);

    TIPParser::ProgramContext *tree = parser.program();
    if (!errors.messages.empty()) {
        for (const std::string &m : errors.messages) std::cout << m << '\n';
        return 2;
    }

    std::unique_ptr<tip::ProgramA> ast = tip::buildAst(tree);
    tip::Bindings bindings = tip::resolveNames(*ast);
    if (!bindings.errors.empty()) {
        for (const tip::Diag &d : bindings.errors) std::cout << d.text << '\n';
        return 3;
    }

    UsePrinter printer{bindings};
    for (const auto &f : ast->funs) {
        std::cout << "== " << f->name << " ==\n";
        printer.counter = 0;
        printer.stmt(f->body.get());
        printer.stmt(f->ret.get());
    }
    return 0;
}
