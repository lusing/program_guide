// file: src/main.cpp
// 第 46 章驱动：
//   --check FILE：TIP → TAC → SSA → OSR（SCC 找归纳变量 → 削减 → LFTR → DCE）→
//   前后程序对照 + 循环乘法账 + SSA 解释器对账。
#include "osr.hpp"

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
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    Parsed p = parseFile(argv[2]);
    std::vector<tip::Quad> code = tip::tacGen(*p.ast->funs.front());
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    size_t n = blocks.size();
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    auto preds = tip::predsOf(adj);

    bool ok = false;
    tip::SsaProgram ssa = tip::buildSsa(code, blocks, ok);
    std::cout << "== SSA（削减前）==\n";
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : ssa.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }

    tip::OsrResult r = tip::runOSR(ssa, adj, preds);
    std::cout << "== 归纳变量（SSA 图 SCC）==\n";
    for (const auto &iv : r.rep.ivs) std::cout << "  链头 φ: " << iv << "\n";
    std::cout << "== 削减 ==\n";
    for (const auto &s : r.rep.reduced) std::cout << "  " << s << "\n";
    std::cout << "== LFTR ==\n";
    for (const auto &s : r.rep.lftr) std::cout << "  " << s << "\n";
    std::cout << "== DCE ==\n  清走死指令 " << r.rep.deadRemoved << " 条\n";

    std::cout << "== SSA（削减后）==\n";
    for (size_t b = 0; b < r.prog.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : r.prog.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }

    std::cout << "== 乘法账 ==\n";
    std::cout << "  循环一乘法：削减前 " << r.rep.mulLoopBefore
              << " → 削减后 " << r.rep.mulLoopAfter << "\n";
    std::cout << "  循环二乘法（k×j，j 非字面量）：保持 " << r.rep.mulUntouched << "\n";

    std::cout << "== 对账 ==\n";
    std::vector<int> before = tip::ssaRun(ssa);
    std::vector<int> after = tip::ssaRun(r.prog);
    std::cout << "  削减前 outputs:";
    for (int v : before) std::cout << ' ' << v;
    std::cout << "\n  削减后 outputs:";
    for (int v : after) std::cout << ' ' << v;
    std::cout << "\n  前后一致: " << (before == after ? "yes" : "NO") << "\n";

    bool ok1 = r.rep.mulLoopBefore >= 1 && r.rep.mulLoopAfter == 0;
    bool ok2 = before == after;
    bool ok3 = r.rep.mulUntouched >= 1;
    bool ok4 = !r.rep.reduced.empty() && !r.rep.lftr.empty();
    std::cout << "  循环一乘法 1→0: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  outputs 相等: " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  非候选（j 非字面量）原样保留: " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  削减与 LFTR 都发生: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok && ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
