// file: src/main.cpp
// 第 42 章驱动：--check FILE
//   TAC → guard 插入（每 Div 一条 if 分母==0）→ 消除（两规则计数）
//   → 保留 guard 回填 fail 序列 → 解释器 outputs 对账（保义）。
#include "bounds.hpp"
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

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';

    std::vector<tip::Quad> guarded = tip::insertGuards(code);
    std::cout << "== guard 插入后 ==\n";
    for (size_t i = 0; i < guarded.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(guarded[i]) << '\n';

    std::vector<tip::Block> blocks = tip::partitionBlocks(guarded);
    tip::LoopInfo li = tip::loopsOf(guarded, blocks);
    std::cout << "== loops ==\n";
    for (const auto &L : li.loops) {
        std::cout << "  back " << L.from << "->" << L.header << " body={";
        for (int b : L.body) std::cout << b << ' ';
        std::cout << "}\n";
    }

    tip::BoundsResult res = tip::eliminateGuards(guarded, blocks, li);
    std::cout << "== 消除后 ==\n";
    for (size_t i = 0; i < res.code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(res.code[i]) << '\n';

    std::cout << "== stats ==\n";
    std::cout << "  invariantHoisted = " << res.invariantHoisted
              << "  ivEliminated = " << res.ivEliminated << '\n';
    int guardsBefore = 0, guardsAfter = 0;
    for (const auto &q : guarded)
        if (q.op == tip::TOp::IfEq && q.b == "0") ++guardsBefore;
    for (const auto &q : res.code)
        if (q.op == tip::TOp::IfEq && q.b == "0") ++guardsAfter;
    std::cout << "  guards: " << guardsBefore << " -> " << guardsAfter << '\n';

    tip::UnrollResult ur = tip::unroll2(res.code, blocks, li);
    std::cout << "  unrolled = " << ur.unrolled << "（概念推演见正文 38.5）\n";

    std::cout << "== 对账 ==\n";
    // guard 命中（分母实为 0）时原程序解释器会除零崩溃——教学程序分母非零，
    // 消除前后 outputs 必须一致；guard 版本分母非零时 guard 不触发。
    std::vector<int> o1 = tip::tacInterp(code, {6}).outputs;
    std::vector<int> o2 = tip::tacInterp(res.code, {6}).outputs;
    std::cout << "  outputs:";
    for (int v : o1) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (o1 == o2 ? "yes" : "NO") << '\n';
    return (o1 == o2 && guardsAfter <= guardsBefore) ? 0 : 1;
}
