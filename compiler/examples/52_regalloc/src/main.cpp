// file: src/main.cpp
// 第 52 章驱动：--check FILE
//   TAC → 块级活跃 → 干涉图 → k=3 图着色 →
//   合法性断言（相邻异色）+ 寄存器映射表 + outputs 对账（TAC 未改，解释器走原程序）。
#include "ra.hpp"
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

    tip::LiveInfo lv = tip::liveness(code, blocks);
    std::cout << "== liveness ==\n";
    for (size_t b = 0; b < blocks.size(); ++b) {
        std::cout << "  B" << b << " in={";
        bool first = true;
        for (const auto &v : lv.in[b]) {
            std::cout << (first ? "" : ",") << v;
            first = false;
        }
        std::cout << "} out={";
        first = true;
        for (const auto &v : lv.out[b]) {
            std::cout << (first ? "" : ",") << v;
            first = false;
        }
        std::cout << "}\n";
    }

    tip::InterfGraph g = tip::buildInterf(code, blocks, lv);
    std::cout << "== interference ==\n";
    for (const auto &e : g.edges) std::cout << "  " << e.first << " -- " << e.second << '\n';
    std::cout << "  moves:";
    for (const auto &m : g.moveEdges) std::cout << ' ' << m.first << "<->" << m.second;
    std::cout << '\n';

    const int K = 3;
    tip::ColorResult cr = tip::colorGraph(g, K);
    std::cout << "== coloring (k=" << K << ") ==\n";
    for (const auto &v : cr.stackOrder) (void)v;
    for (const auto &kv : cr.color)
        std::cout << "  " << kv.first << " -> r" << kv.second << '\n';
    if (!cr.spilled.empty()) {
        std::cout << "  spilled:";
        for (const auto &s : cr.spilled) std::cout << ' ' << s;
        std::cout << "（溢出改写留作练习；本表未含溢出者）\n";
    }
    std::cout << "  spill-free: " << (cr.ok ? "yes" : "no") << '\n';
    std::cout << "  coalesced = " << cr.coalesced << '\n';

    std::cout << "== 校验 ==\n";
    // 两种正确结局：无溢出且合法着色；或有溢出（如实报告、改写留作练习）。
    bool valid = tip::colorValid(g, cr.color, K) && (cr.ok || !cr.spilled.empty());
    std::cout << "  已着色子图相邻异色且色域<=k: " << (tip::colorValid(g, cr.color, K) ? "yes" : "NO") << '\n';

    std::cout << "== 对账 ==\n";
    tip::TacRun run = tip::tacInterp(code, {4, 7, 5, 2});
    std::cout << "  outputs:";
    for (int v : run.outputs) std::cout << ' ' << v;
    std::cout << "\n  (着色是分配方案，不改程序；解释器照常执行原 TAC)\n";
    return valid ? 0 : 1;
}
