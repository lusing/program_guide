// file: src/main.cpp
// 第 37 章驱动：--check FILE
//   TAC → 自然循环 → LICM（外提计数 + 前后 TAC + steps/outputs 对账）
//   → 归纳变量识别（报告 i = i + c）。
#include "licm.hpp"
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

    tip::LoopInfo li = tip::loopsOf(code, blocks);
    std::cout << "== loops ==\n";
    for (const auto &L : li.loops) {
        std::cout << "  back " << L.from << "->" << L.header << " body={";
        bool first = true;
        for (int b : L.body) {
            std::cout << (first ? "" : ",") << b;
            first = false;
        }
        std::cout << "}\n";
    }

    // 两轮外提：第一轮提出 t5=2 后，t6=c*t5 的操作数即全部循环外（迭代的直观演示）
    auto [h1, n1] = tip::licm(code, blocks, li);
    std::vector<tip::Quad> hoistedCode = h1;
    int nHoist = n1;
    {
        std::vector<tip::Block> b2 = tip::partitionBlocks(hoistedCode);
        tip::LoopInfo li2 = tip::loopsOf(hoistedCode, b2);
        auto [h2, n2] = tip::licm(hoistedCode, b2, li2);
        hoistedCode = h2;
        nHoist += n2;
    }
    std::cout << "== after LICM (两轮) ==\n";
    for (size_t i = 0; i < hoistedCode.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(hoistedCode[i]) << '\n';
    std::cout << "  hoisted = " << nHoist << '\n';

    std::cout << "== induction variables ==\n";
    for (const auto &L : li.loops) {
        auto ivs = tip::indVars(code, blocks, L);
        for (const auto &iv : ivs)
            std::cout << "  " << iv.var << " : line " << iv.incrLine
                      << " (" << iv.var << " = " << iv.var << " + " << iv.incr << ")\n";
    }

    std::cout << "== 对账 ==\n";
    tip::TacRun before = tip::tacInterp(code, {3});
    tip::TacRun after = tip::tacInterp(hoistedCode, {3});
    std::cout << "  steps: " << before.steps << " -> " << after.steps << '\n';
    std::cout << "  outputs:";
    for (int v : before.outputs) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (before.outputs == after.outputs ? "yes" : "NO") << '\n';
    return (before.outputs == after.outputs && after.steps <= before.steps) ? 0 : 1;
}
