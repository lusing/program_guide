// file: src/main.cpp
// 第 42 章驱动：--check FILE
//   TAC → 块图 → 后支配树 → CDG → SSA（34 章）→ 拆回 TAC → 解释器三方对账。
#include "cdg.hpp"
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
    std::fprintf(stderr, "[main entered]\n");
    std::cout.setf(std::ios::unitbuf);
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto ast = parseFile(argv[2]);
    std::fprintf(stderr, "[parsed]\n");
    std::vector<tip::Quad> code = tip::tacGen(*ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    size_t n = blocks.size();

    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';
    std::cout << "== blocks ==\n";
    for (size_t b = 0; b < n; ++b) {
        std::cout << "  B" << b << " succs:";
        for (int s : adj[b]) std::cout << ' ' << s;
        std::cout << '\n';
    }

    tip::DomInfo pdom = tip::postDominators(adj);
    std::cout << "== 后支配 ==\n";
    for (size_t b = 0; b < n; ++b) {
        std::cout << "  pdom(B" << b << ") = {";
        bool first = true;
        for (int d : pdom.dom[b]) {
            std::cout << (first ? "" : ",") << d;
            first = false;
        }
        std::cout << "}  ipdom=" << pdom.idom[b] << '\n';
    }

    tip::CdgInfo cdg = tip::controlDependence(adj, pdom);
    std::cout << "== 控制依赖图 ==\n";
    bool any = false;
    for (size_t b = 0; b < n; ++b)
        for (int s : cdg.succs[b]) {
            std::cout << "  B" << s << " 依赖 B" << b << '\n';
            any = true;
        }
    if (!any) std::cout << "  （无——直线程序没有分岔）\n";

    // ---------- SSA 往返 ----------
    bool ok = false;
    tip::SsaProgram ssa = tip::buildSsa(code, blocks, ok);
    std::cout << "== SSA ==\n";
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : ssa.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }
    tip::SsaBackResult back = tip::ssaBack(ssa);
    std::cout << "== SSA 退出 ==\n";
    for (size_t i = 0; i < back.code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(back.code[i]) << '\n';
    std::cout << "  copies = " << back.copies << "  swaps = " << back.swaps << '\n';

    std::cout << "== 对账 ==\n";
    std::vector<int> o1 = tip::tacInterp(code, {5}).outputs;
    std::vector<int> o2 = tip::ssaRun(ssa, {5});
    std::vector<int> o3 = tip::tacInterp(back.code, {5}).outputs;
    std::cout << "  tac   :";
    for (int v : o1) std::cout << ' ' << v;
    std::cout << "\n  ssa   :";
    for (int v : o2) std::cout << ' ' << v;
    std::cout << "\n  back  :";
    for (int v : o3) std::cout << ' ' << v;
    std::cout << "\n  tac==ssa==back: "
              << (o1 == o2 && o2 == o3 ? "yes" : "NO") << '\n';
    return (o1 == o2 && o2 == o3) ? 0 : 1;
}
