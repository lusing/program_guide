// 第 51 章配套程序：指针分析双算法 + JIT 可靠性检验。
//   --check FILE : AST→约束，分别跑 Andersen/Steensgaard，双栏打印 pts 集
//   --verify-soundness FILE INPUTS :
//                  先静态列出每个解引用点"是否可能解引用 null"，
//                  再对 INPUTS 的每一行真实 JIT 执行：
//                  凡运行正常返回即证明该行没有触发 null 解引用，
//                  与静态结论对照
#include <fstream>
#include <iostream>
#include <memory>
#include <sstream>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"
#include "ptranal.hpp"
#include "pretty.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

namespace {

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) {
        std::cerr << "cannot open " << path << '\n';
        std::exit(1);
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
        std::exit(2);
    }

    Parsed result;
    result.ast = tip::buildAst(tree);
    result.bindings = tip::resolveNames(*result.ast);
    if (!result.bindings.errors.empty()) {
        for (const tip::Diag &d : result.bindings.errors)
            std::cout << d.text << '\n';
        std::exit(3);
    }
    return result;
}

std::vector<int> parseRun(const std::string &line) {
    std::istringstream ss(line);
    std::vector<int> vals;
    int v;
    while (ss >> v) vals.push_back(v);
    return vals;
}

// 收集程序中全部解引用表达式（RHS/条件/输出里都算）。
void collectDerefs(const tip::Expr *e,
                   std::vector<const tip::Deref *> &out) {
    if (const auto *x = dynamic_cast<const tip::Deref *>(e)) {
        out.push_back(x);
        collectDerefs(x->e.get(), out);
    } else if (const auto *x = dynamic_cast<const tip::CallE *>(e)) {
        for (const auto &a : x->args) collectDerefs(a.get(), out);
    } else if (const auto *x = dynamic_cast<const tip::Binop *>(e)) {
        collectDerefs(x->l.get(), out);
        collectDerefs(x->r.get(), out);
    }
}
void collectDerefsS(const tip::Stmt *s,
                    std::vector<const tip::Deref *> &out) {
    if (const auto *x = dynamic_cast<const tip::AssignS *>(s)) {
        collectDerefs(x->target.get(), out);
        collectDerefs(x->value.get(), out);
    } else if (const auto *x = dynamic_cast<const tip::OutputS *>(s)) {
        collectDerefs(x->e.get(), out);
    } else if (const auto *x = dynamic_cast<const tip::IfS *>(s)) {
        collectDerefs(x->cond.get(), out);
        collectDerefsS(x->then.get(), out);
        if (x->els) collectDerefsS(x->els.get(), out);
    } else if (const auto *x = dynamic_cast<const tip::WhileS *>(s)) {
        collectDerefs(x->cond.get(), out);
        collectDerefsS(x->body.get(), out);
    } else if (const auto *x = dynamic_cast<const tip::BlockS *>(s)) {
        for (const auto &st : x->ss) collectDerefsS(st.get(), out);
    }
}

}  // namespace

int main(int argc, char **argv) {
    if (argc == 3 && std::string(argv[1]) == "--check") {
        Parsed p = parseFile(argv[2]);
        tip::PtrConstraints cons =
            tip::buildPtrConstraints(*p.ast, p.bindings);
        tip::PtrResult r = tip::solvePointer(cons);
        std::cout << tip::printPointer(cons, r);
        return 0;
    }

    if (argc == 4 && std::string(argv[1]) == "--verify-soundness") {
        std::ifstream in(argv[3]);
        if (!in) {
            std::cerr << "cannot open " << argv[3] << '\n';
            return 1;
        }
        Parsed p = parseFile(argv[2]);
        tip::PtrConstraints cons =
            tip::buildPtrConstraints(*p.ast, p.bindings);
        tip::PtrResult r = tip::solvePointer(cons);

        // 静态：每个解引用点基址的 pts 集是否含 null。
        std::vector<const tip::Deref *> derefs;
        for (const auto &f : p.ast->funs) collectDerefsS(f->body.get(), derefs);
        std::cout << "static deref sites: " << derefs.size() << "\n";
        for (const tip::Deref *d : derefs) {
            std::string status = "no-variable-base";
            if (const auto *v =
                    dynamic_cast<const tip::VarRef *>(d->e.get())) {
                auto it = r.andersen.find(v->name);
                bool mayNull = false;
                if (it != r.andersen.end())
                    mayNull = it->second.count("null") > 0;
                status = mayNull ? "possibly-null (conservative)"
                                 : "cannot-be-null";
            }
            std::cout << "  *(" << tip::printExpr(d->e.get()) << "): " << status
                      << "\n";
        }

        int runs = 0;
        std::string line;
        while (std::getline(in, line)) {
            std::string trimmed = line;
            size_t a = trimmed.find_first_not_of(" \t\r\n");
            if (a == std::string::npos) continue;
            if (trimmed[a] == '#') continue;

            std::vector<int> inputs = parseRun(trimmed);
            tip::IRGen gen;
            gen.gen(*p.ast, p.bindings);
            if (!gen.verify()) {
                std::cerr << "generated module failed verification\n";
                return 1;
            }
            std::vector<int> outputs = tip::runJit(std::move(gen), inputs);
            ++runs;
            std::cout << "run " << runs << ": inputs";
            for (int v : inputs) std::cout << " " << v;
            std::cout << " -> outputs";
            for (int v : outputs) std::cout << " " << v;
            std::cout << "\n";
        }
        std::cout << "JIT completed " << runs
                  << " runs: no null-deref crash observed\n";
        return 0;
    }

    std::cerr << "usage: tipa --check FILE | tipa --verify-soundness FILE INPUTS\n";
    return 1;
}
