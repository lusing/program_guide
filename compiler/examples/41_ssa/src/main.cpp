// file: src/main.cpp
// 第 41 章驱动：
//   --check FILE：TAC → 块图 → 支配边界 → SSA（φ 插入 + 改名）→
//                 SSA 打印 → 单定值自检 → SSA 解释 vs TAC 解释对账；
//   --emit-ir FILE：吐 LLVM IR（opt mem2reg 对账的取材口）。
#include "ssa.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"
#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "irgen.hpp"

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

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
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
    Parsed p;
    p.ast = tip::buildAst(tree);
    p.bindings = tip::resolveNames(*p.ast);
    if (!p.bindings.errors.empty())
        throw std::runtime_error("名字解析错误: " + p.bindings.errors.front().text);
    return p;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc == 3 && std::string(argv[1]) == "--emit-ir") {
        Parsed p = parseFile(argv[2]);
        tip::IRGen gen;
        gen.gen(*p.ast, p.bindings);
        if (!gen.verify()) {
            std::cerr << "generated module failed verification\n";
            return 1;
        }
        std::cout << gen.dump();
        return 0;
    }
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE | tipa --emit-ir FILE\n";
        return 2;
    }
    Parsed p = parseFile(argv[2]);
    std::vector<tip::Quad> code = tip::tacGen(*p.ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    size_t n = blocks.size();

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';

    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    tip::DomInfo di = tip::dominators(adj);
    auto preds = tip::predsOf(adj);
    auto df = tip::dominanceFrontiers(adj, di, preds);
    std::cout << "== dominance frontiers ==\n";
    for (size_t b = 0; b < n; ++b) {
        std::cout << "  DF(B" << b << ") = {";
        bool first = true;
        for (int d : df[b]) {
            std::cout << (first ? "" : ",") << d;
            first = false;
        }
        std::cout << "}\n";
    }

    bool ok = false;
    tip::SsaProgram ssa = tip::buildSsa(code, blocks, ok);
    std::cout << "== SSA ==\n";
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : ssa.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }
    std::cout << "== 单定值自检 ==\n";
    std::cout << "  single-def: " << (ok ? "yes" : "NO") << '\n';

    std::cout << "== 对账 ==\n";
    std::vector<int> tac = tip::tacInterp(code, {}).outputs;
    std::vector<int> ss = tip::ssaRun(ssa);
    std::cout << "  tac outputs:";
    for (int v : tac) std::cout << ' ' << v;
    std::cout << "\n  ssa outputs:";
    for (int v : ss) std::cout << ' ' << v;
    std::cout << "\n  tac==ssa: " << (tac == ss ? "yes" : "NO") << '\n';
    return (ok && tac == ss) ? 0 : 1;
}
