// 第 32 章配套程序：可能未初始化分析 + 单调框架五元组/分类总表输出。
//   --check FILE : 打印各程序点可能未初始化集合、use-before-init 警告，
//                  以及本分析在 MonotoneFramework 五元组下的形式化描述
#include <fstream>
#include <iostream>
#include <memory>
#include <string>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "init.hpp"
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

// 第 28–32 章所有分析按五元组（格、方向、边界、初值、传递函数族）归位。
// 一张总表看懂"同一个 worklist 引擎为什么能跑出七种分析"。
void printFrameworkTable() {
    std::cout <<
        "== monotone framework classification (chapters 16-19) ==\n"
        "analysis         direction merge boundary            transfer\n"
        "sign lattice     forward   join  entry: params=TOP   abstract arith tables\n"
        "constant (flat)  forward   join  entry: params=TOP   constant folding\n"
        "live variables   backward  union exit: {}            gen/kill\n"
        "reaching defs    forward   union entry: {}           gen/kill\n"
        "available exprs  forward   inter entry: {}           gen/kill\n"
        "very busy exprs  backward  inter exit: {}            gen/kill\n"
        "possibly-uninit  forward   union entry: decls\\params state-dependent\n";
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    Parsed p = parseFile(argv[2]);
    tip::Cfg cfg = tip::buildCfg(*p.ast);

    tip::InitResult r = tip::runInitAnalysis(cfg, *p.ast);
    std::cout << tip::printInit(cfg, *p.ast, r);

    std::cout <<
        "-- monotone framework (five-tuple), possibly-uninitialized --\n"
        "  lattice  : powerset of program variables, order = subset,\n"
        "             join = union, bottom = {}\n"
        "  direction: forward\n"
        "  boundary : entry(f) = declared vars \\ params (params arrive initialized)\n"
        "  init     : every other point starts at bottom {}\n"
        "  transfer : x = e  ->  (S \\ {x}) plus {x} if e reads a variable in S\n"
        "             others ->  S\n"
        "  theorem  : all transfer functions are monotone, so the worklist least\n"
        "             fixpoint approximates merge-over-paths; every reported\n"
        "             use-before-init occurs on at least one real execution path.\n";

    printFrameworkTable();
    return 0;
}
