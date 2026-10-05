// file: src/main.cpp
// 第 40 章驱动：--check FILE
//   块图 → 支配集/支配树 → DFS 边分类 → 自然循环 → 可归约性；
//   末尾内置不可归约小图（TIP 结构化语法造不出它）演示判定失败。
#include "dom.hpp"
#include "dfs.hpp"

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

std::vector<std::vector<int>> adjOf(const std::vector<tip::Block> &blocks) {
    size_t n = blocks.size();
    std::vector<std::vector<int>> adj(n);
    for (size_t b = 0; b < n; ++b)
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) adj[b].push_back(static_cast<int>(k));
    return adj;
}

void runGraph(const std::vector<std::vector<int>> &adj, const std::string &title) {
    std::cout << "== " << title << " ==\n";
    // 简易图打印
    for (size_t b = 0; b < adj.size(); ++b) {
        std::cout << "  B" << b << " ->";
        for (int s : adj[b]) std::cout << ' ' << s;
        std::cout << '\n';
    }
    tip::DomInfo di = tip::dominators(adj);
    std::cout << "== dominators ==\n";
    for (size_t b = 0; b < adj.size(); ++b) {
        std::cout << "  dom(B" << b << ") = {";
        bool first = true;
        for (int d : di.dom[b]) {
            std::cout << (first ? "" : ",") << d;
            first = false;
        }
        std::cout << "}  idom=" << di.idom[b] << '\n';
    }
    std::cout << "== dom tree ==\n";
    for (size_t b = 0; b < adj.size(); ++b)
        if (!di.children[b].empty()) {
            std::cout << "  B" << b << " :";
            for (int c : di.children[b]) std::cout << " B" << c;
            std::cout << '\n';
        }
    std::cout << "  domTreeCheck: " << (tip::domTreeCheck(di) ? "yes" : "NO") << '\n';
    tip::FastDomResult fd = tip::fastDominators(adj);
    bool same = fd.di.dom == di.dom;
    std::cout << "== fast dominators (CHK) ==\n";
    std::cout << "  迭代法扫描 " << di.sweeps << " 轮 vs CHK " << fd.passes
              << " 轮；支配集一致: " << (same ? "yes" : "NO") << '\n';
    tip::DfsInfo df = tip::dfsClassify(adj);
    std::cout << "== DFS ==\n";
    for (size_t b = 0; b < adj.size(); ++b)
        std::cout << "  B" << b << " d=" << df.discover[b] << " f=" << df.finish[b] << '\n';
    for (const auto &[u, v, kind] : df.classified)
        std::cout << "  edge " << u << "->" << v << " : " << kind << '\n';
    auto loops = tip::naturalLoops(adj, df, di);
    std::cout << "== natural loops ==\n";
    if (loops.empty()) std::cout << "  none\n";
    for (const auto &L : loops) {
        std::cout << "  back " << L.from << "->" << L.header << " header=" << L.header
                  << " body={";
        bool first = true;
        for (int m : L.body) {
            std::cout << (first ? "" : ",") << m;
            first = false;
        }
        std::cout << "}\n";
    }
    std::cout << "== reducible ==\n";
    std::cout << "  " << (tip::reducible(adj, df, di) ? "yes" : "no") << '\n';
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
    std::cout << "== TAC blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << ' ' << s;
        std::cout << '\n';
    }
    // ---------- 稀疏集自测（鲸书附录 B.2.3） ----------
    std::cout << "== sparse set ==\n";
    tip::SparseSet ss(1000);
    ss.insert(3);
    ss.insert(500);
    ss.insert(999);
    std::cout << "  插入 {3,500,999} 后 size=" << ss.size()
              << " 含 500: " << (ss.contains(500) ? "yes" : "no")
              << " 含 501: " << (ss.contains(501) ? "yes" : "no") << '\n';
    ss.clear();   // O(1)：游标归零，数组不碰
    std::cout << "  clear 后 size=" << ss.size()
              << " 含 3: " << (ss.contains(3) ? "yes" : "no") << '\n';
    ss.insert(7);
    std::cout << "  复用后遍历:";
    for (int v : ss.items()) std::cout << ' ' << v;
    std::cout << '\n';

    runGraph(adjOf(blocks), "程序块图");

    // 不可归约经典图：两个入口互相跳进对方的“环”。
    // B0→B1, B0→B2, B1→B2, B2→B1（1↔2 的环有两个入口）
    std::cout << "== 不可归约演示 ==\n";
    runGraph({{1, 2}, {2}, {1}}, "内置块图");
    return 0;
}
