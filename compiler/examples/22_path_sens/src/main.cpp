// 第 22 章配套程序：路径精炼 vs 流不敏感基线的对照。
//   --check FILE : 对同一程序跑两档区间分析（关/开条件精炼），
//                  打印 output 点预测与除零告警的对比
#include <fstream>
#include <iostream>
#include <memory>
#include <string>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "path.hpp"
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

void reportMode(const char *name, const tip::Cfg &cfg,
                const tip::PathResult &r) {
    std::cout << name << "\n";
    for (const std::string &l : tip::outputPredictions(cfg, r.out))
        std::cout << "  " << l << "\n";
    std::vector<std::string> warns = tip::divZeroWarnings(cfg, r.out);
    if (warns.empty()) {
        std::cout << "  div-zero: (none)\n";
    } else {
        for (const std::string &w : warns) std::cout << "  div-zero: " << w << "\n";
    }
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
    tip::PathResult base = solveInterval(cfg, *p.ast, maxRounds, false);
    tip::PathResult refined = solveInterval(cfg, *p.ast, maxRounds, true);

    std::cout << "== interval analysis: flow-insensitive vs path-refined ==\n";
    reportMode("FLOW-INSENSITIVE (no edge refinement):", cfg, base);
    reportMode("PATH-REFINED (condition refinement on branch edges):", cfg,
               refined);
    return 0;
}
