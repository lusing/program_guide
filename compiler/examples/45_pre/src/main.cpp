// file: src/main.cpp
// 第 45 章驱动：--check FILE
//   TAC → 六方程逐块打印 → latest 摆位报告 → 块内去重变换 → 解释器对账。
#include "pre.hpp"
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

void showS(const tip::FValS &s) {
    std::cout << "{";
    bool first = true;
    for (const auto &x : s) {
        std::cout << (first ? "" : ", ") << x;
        first = false;
    }
    std::cout << "}";
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

    tip::PreInfo p = tip::preAnalyse(code, blocks);
    std::cout << "== 六方程 ==\n";
    for (size_t b = 0; b < blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        std::cout << "    antic.in  "; showS(p.anticIn[b]); std::cout << '\n';
        std::cout << "    avail.in  "; showS(p.availIn[b]); std::cout << '\n';
        std::cout << "    earliest  "; showS(p.earliest[b]); std::cout << '\n';
        std::cout << "    post.out  "; showS(p.postOut[b]); std::cout << '\n';
        std::cout << "    used.in   "; showS(p.usedIn[b]); std::cout << '\n';
        std::cout << "    latest    "; showS(p.latest[b]); std::cout << '\n';
    }

    auto [out, st] = tip::preTransform(code, blocks, p);
    std::cout << "== after PRE（块内去重）==\n";
    for (size_t i = 0; i < out.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(out[i]) << '\n';
    std::cout << "  stats: inserted=" << st.inserted << " replaced=" << st.replaced << '\n';

    std::cout << "== 对账 ==\n";
    tip::TacRun before = tip::tacInterp(code, {5, 3});
    tip::TacRun after = tip::tacInterp(out, {5, 3});
    std::cout << "  steps: " << before.steps << " -> " << after.steps << '\n';
    std::cout << "  outputs:";
    for (int v : before.outputs) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (before.outputs == after.outputs ? "yes" : "NO") << '\n';
    return before.outputs == after.outputs ? 0 : 1;
}
