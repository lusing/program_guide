// file: src/main.cpp
// 第 14 章驱动：--check FILE
//   TAC → 块 → 贪心跟踪表 → 线性化（消跳/翻转/补跳计数）→
//   跳转数前后对比 → 解释器 outputs 对账。
#include "trace.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"
#include "tacgen.hpp"
#include "tacblocks.hpp"

#include <fstream>
#include <iostream>
#include <vector>

namespace {

struct CollectErrorListener : antlr4::BaseErrorListener {
    std::vector<std::string> messages;
    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

std::unique_ptr<tip::ProgramA> parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) throw std::runtime_error("打不开 " + path);
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
    if (!errors.messages.empty())
        throw std::runtime_error("词法/语法错误: " + errors.messages.front());
    auto ast = tip::buildAst(tree);
    auto binds = tip::resolveNames(*ast);
    if (!binds.errors.empty())
        throw std::runtime_error("名字解析错误: " + binds.errors.front().text);
    return ast;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto ast = parseFile(argv[2]);
    std::vector<tip::Quad> code = tip::tacGen(*ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';
    std::cout << "== blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << ' ' << s;
        std::cout << '\n';
    }

    tip::TracePlan plan = tip::buildTraces(blocks);
    std::cout << "== traces ==\n";
    for (size_t k = 0; k < plan.traces.size(); ++k) {
        std::cout << "  T" << k << ":";
        for (int b : plan.traces[k]) std::cout << ' ' << b;
        std::cout << '\n';
    }

    tip::LinearResult lin = tip::linearize(code, blocks, plan);
    std::cout << "== after traces ==\n";
    for (size_t i = 0; i < lin.code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(lin.code[i]) << '\n';

    int jumpsBefore = 0, jumpsAfter = 0;
    for (const auto &q : code)
        if (q.op == tip::TOp::Goto) ++jumpsBefore;
    for (const auto &q : lin.code)
        if (q.op == tip::TOp::Goto) ++jumpsAfter;
    std::cout << "== stats ==\n";
    std::cout << "  gotosDeleted = " << lin.gotosDeleted
              << "  flips = " << lin.flips
              << "  fixups = " << lin.fixups << '\n';
    std::cout << "  instructions: " << code.size() << " -> " << lin.code.size() << '\n';
    std::cout << "  gotos: " << jumpsBefore << " -> " << jumpsAfter << '\n';

    std::cout << "== 对账 ==\n";
    std::vector<int> before = tip::tacInterp(code, {3, 1}).outputs;   // a=3, b=1
    std::vector<int> after = tip::tacInterp(lin.code, {3, 1}).outputs;
    std::cout << "  outputs:";
    for (int v : before) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (before == after ? "yes" : "NO") << '\n';
    return (before == after && jumpsAfter <= jumpsBefore) ? 0 : 1;
}
