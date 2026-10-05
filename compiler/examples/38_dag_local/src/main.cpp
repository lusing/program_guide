// file: src/main.cpp
// 第 38 章驱动：--check FILE
//   TAC → 逐块 DAG（结点/标签/命中统计）→ 重发射 → 指令数对账 → 解释器 outputs 对账。
#include "dag.hpp"
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

    // 逐块建 DAG、重发射，拼回新程序
    std::vector<tip::Quad> rebuilt;
    int algebra = 0, cse = 0;
    for (const auto &b : blocks) {
        tip::DagResult d = tip::dagBuild(code, b);
        algebra += d.algebraHits;
        cse += d.cseHits;
        std::cout << "== DAG B" << b.id << " ==\n";
        std::cout << "  nodes=" << d.nodes.size() << " labels=" << d.labelOf.size()
                  << " algebraHits=" << d.algebraHits << " cseHits=" << d.cseHits << '\n';
        for (size_t k = 0; k < d.nodes.size(); ++k) {
            const auto &n = d.nodes[k];
            if (n.isLeaf) continue;
            std::cout << "    n" << k << " = " << tip::show(tip::Quad{n.op, "", "", "", -1})
                      << " kids(" << n.kid0 << "," << n.kid1 << ") labels:";
            for (const auto &l : n.labels) std::cout << ' ' << l;
            std::cout << '\n';
        }
        std::vector<tip::Quad> part = tip::dagEmit(d, code, b);
        rebuilt.insert(rebuilt.end(), part.begin(), part.end());
    }

    std::cout << "== after DAG ==\n";
    for (size_t i = 0; i < rebuilt.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(rebuilt[i]) << '\n';

    std::cout << "== stats ==\n";
    std::cout << "  instructions: " << code.size() << " -> " << rebuilt.size() << '\n';
    std::cout << "  algebraHits = " << algebra << "  cseHits = " << cse << '\n';

    std::cout << "== 对账 ==\n";
    std::vector<int> before = tip::tacInterp(code, {3}).outputs;   // input 喂 3
    std::vector<int> after = tip::tacInterp(rebuilt, {3}).outputs;
    std::cout << "  outputs:";
    for (int v : before) std::cout << ' ' << v;
    std::cout << "\n  outputs preserved: " << (before == after ? "yes" : "NO") << '\n';
    return (before == after && rebuilt.size() <= code.size()) ? 0 : 1;
}
