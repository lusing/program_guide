// file: src/main.cpp
// 第 27 章驱动：--check FILE
//   TAC → 到达定值（逐块 OUT + ud 链）→ 非常忙（逐块 IN）→
//   复制传播变换 → 代码提升变换 → 每步变换后解释器 outputs 对账。
#include "reach.hpp"
#include "verybusy.hpp"
#include "apps.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"

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

void dumpCode(const std::vector<tip::Quad> &code, const std::string &title) {
    std::cout << "== " << title << " ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';
}

void dumpBlocks(const std::vector<tip::Block> &blocks) {
    std::cout << "== blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << ' ' << s;
        std::cout << '\n';
    }
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    auto ast = parseFile(argv[2]);
    const tip::FunDecl &fn = *ast->funs.front();
    std::vector<tip::Quad> code = tip::tacGen(fn);
    dumpCode(code, "TAC");
    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    dumpBlocks(blocks);

    // ---------- 到达定值 ----------
    tip::ReachInfo ri = tip::reaching(code, blocks);
    std::cout << "== reaching (OUT) ==\n";
    for (size_t b = 0; b < blocks.size(); ++b) {
        std::cout << "  B" << b << ":";
        for (int d : ri.out[b]) std::cout << ' ' << d << ':' << ri.defVar.at(d);
        std::cout << '\n';
    }
    std::cout << "== ud-chains ==\n";
    for (size_t i = 0; i < code.size(); ++i) {
        const tip::Quad &q = code[i];
        bool shown = false;
        for (const std::string *s : {&q.a, &q.b}) {
            if (s->empty() || isdigit((*s)[0])) continue;
            if (q.op == tip::TOp::Goto) continue;
            std::set<int> ch = tip::udChain(ri, blocks, static_cast<int>(i), *s);
            std::cout << "  " << i << ": use " << *s << " <-";
            for (int d : ch) std::cout << ' ' << d;
            std::cout << '\n';
            shown = true;
        }
        (void)shown;
    }

    // ---------- 非常忙 ----------
    tip::VeryBusyInfo vb = tip::veryBusy(code, blocks);
    std::cout << "== very busy (IN) ==\n";
    for (size_t b = 0; b < blocks.size(); ++b) {
        std::cout << "  B" << b << ":";
        for (const auto &e : vb.in[b]) std::cout << " {" << e << "}";
        std::cout << '\n';
    }

    // ---------- 变换与对账 ----------
    std::vector<int> before = tip::tacInterp(code, {}).outputs;

    std::vector<tip::Quad> cp = code;
    tip::CopyPropResult cr = tip::copyProp(cp, ri, blocks);
    dumpCode(cp, "after copy-prop");
    std::cout << "  stats: replaced=" << cr.replaced << " deleted=" << cr.deleted << '\n';
    std::vector<int> afterCp = tip::tacInterp(cp, {}).outputs;

    std::vector<tip::Block> blocks2 = tip::partitionBlocks(cp);
    tip::VeryBusyInfo vb2 = tip::veryBusy(cp, blocks2);
    std::vector<tip::Quad> hs = cp;
    tip::HoistResult hr = tip::hoist(hs, vb2, blocks2);
    dumpCode(hs, "after hoist");
    std::cout << "  stats: hoisted=" << hr.hoisted;
    for (const auto &d : hr.detail) std::cout << " (" << d << ")";
    std::cout << '\n';
    std::vector<int> afterHs = tip::tacInterp(hs, {}).outputs;

    std::cout << "== 对账 ==\n";
    std::cout << "  outputs(before) == outputs(copy-prop): "
              << (before == afterCp ? "yes" : "NO") << '\n';
    std::cout << "  outputs(before) == outputs(hoist): "
              << (before == afterHs ? "yes" : "NO") << '\n';
    return (before == afterCp && before == afterHs) ? 0 : 1;
}
