// 第 40 章配套程序：调用图 + 两档过程间常量传播对比。
//   --check FILE : 打印调用图，然后分别以"调用点 = ⊤"（上下文不敏感基线）
//                  与"直线纯函数内联展开"两档跑常量传播并打印逐点状态
#include <fstream>
#include <iostream>
#include <memory>
#include <string>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "callgraph.hpp"
#include "cfg.hpp"
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

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    Parsed p = parseFile(argv[2]);
    tip::Cfg cfg = tip::buildCfg(*p.ast);

    tip::CallGraph cg = tip::buildCallGraph(*p.ast);
    std::cout << "== call graph ==\n" << tip::printCallGraph(cg);
    std::cout << "acyclic: " << (cg.acyclic ? "yes" : "no") << "\n";

    std::map<std::string, tip::ConstPointEnv> merged =
        tip::solveConstInterproc(cfg, *p.ast, false);
    std::cout
        << "== constants, context-insensitive (every call = TOP) ==\n"
        << tip::printInterproc(cfg, *p.ast, merged);

    std::map<std::string, tip::ConstPointEnv> inlined =
        tip::solveConstInterproc(cfg, *p.ast, true);
    std::cout << "== constants, inline expansion (straight-line pure callees) ==\n"
              << tip::printInterproc(cfg, *p.ast, inlined);
    return 0;
}
