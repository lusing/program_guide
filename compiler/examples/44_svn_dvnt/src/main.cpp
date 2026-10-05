// file: src/main.cpp
// 第 44 章驱动：
//   --check FILE：TIP → TAC → 块图 → SSA → 三档值编号（LVN/SVN/DVNT）→
//   各档成绩单与流水 → DVNT 优化后程序 → SSA 解释器前后对账。
#include "svn.hpp"

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
    tip::DomInfo di = tip::dominators(adj);
    auto preds = tip::predsOf(adj);

    bool ok = false;
    tip::SsaProgram ssa = tip::buildSsa(code, blocks, ok);
    std::cout << "== SSA（输入）==\n";
    for (size_t b = 0; b < ssa.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : ssa.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }

    // ---------- 三档值编号 ----------
    tip::VnResult lvn = tip::runLVN(ssa, adj, preds);
    tip::VnResult svn = tip::runSVN(ssa, adj, preds);
    tip::VnResult dvnt = tip::runDVNT(ssa, adj, preds, di);
    std::cout << "== 三档成绩 ==\n";
    std::cout << "  LVN（块内）  : 消除 " << lvn.rep.redundant << " 条冗余\n";
    std::cout << "  SVN（EBB）   : 消除 " << svn.rep.redundant << " 条冗余\n";
    std::cout << "  DVNT（支配树）: 消除 " << dvnt.rep.redundant << " 条冗余 + "
              << dvnt.rep.phiDeleted << " 个无义/重复 φ（" << dvnt.rep.sweeps << " 轮扫描）\n";
    std::cout << "== DVNT 流水 ==\n";
    for (const auto &s : dvnt.rep.notes) std::cout << "  " << s << "\n";

    std::cout << "== DVNT 优化后 ==\n";
    for (size_t b = 0; b < dvnt.prog.blocks.size(); ++b) {
        std::cout << "  B" << b << ":\n";
        for (const auto &inst : dvnt.prog.blocks[b].body)
            std::cout << "    " << tip::show(inst) << '\n';
    }

    // ---------- 解释器对账 ----------
    std::cout << "== 对账 ==\n";
    std::vector<int> before = tip::ssaRun(ssa);
    std::vector<int> after = tip::ssaRun(dvnt.prog);
    std::cout << "  原始 outputs:";
    for (int v : before) std::cout << ' ' << v;
    std::cout << "\n  优化 outputs:";
    for (int v : after) std::cout << ' ' << v;
    std::cout << "\n  前后一致: " << (before == after ? "yes" : "NO") << "\n";

    bool ok1 = lvn.rep.redundant >= 1 && svn.rep.redundant > lvn.rep.redundant;
    bool ok2 = dvnt.rep.redundant + dvnt.rep.phiDeleted > svn.rep.redundant;
    bool ok3 = before == after;
    bool ok4 = dvnt.rep.phiDeleted >= 1 && dvnt.rep.sweeps >= 2;
    std::cout << "  SVN 比 LVN 多抓跨块冗余: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  DVNT 比 SVN 多抓连接块与 φ: " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  优化前后 outputs 相等: " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  无义 φ 被删（≥2 轮扫描）: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok && ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
