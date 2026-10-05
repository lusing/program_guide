// 第 30 章配套程序：区间格 + 朴素迭代的不终止演示。
//   --check FILE : 打印每轮朴素迭代在循环头的区间环境，封顶 50 轮；
//                  未收敛时打印 DID NOT CONVERGE（这正是第 31 章 widening 的动机）
#include <fstream>
#include <iostream>
#include <memory>
#include <string>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "interval.hpp"
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

    const int maxRounds = 50;
    tip::NaiveResult r = tip::runNaiveInterval(cfg, *p.ast, maxRounds);

    std::cout << "== interval lattice, naive iteration (cap " << maxRounds
              << " rounds) ==\n";
    std::cout << "loop head: node " << r.headNode << "\n";
    for (const std::string &line : r.trace) std::cout << line << "\n";
    if (r.converged)
        std::cout << "CONVERGED after " << r.rounds << " rounds\n";
    else
        std::cout << "DID NOT CONVERGE after " << r.rounds
                  << " rounds: chain [1,1] <= [1,2] <= [1,3] <= ... has no end\n";
    return 0;
}
