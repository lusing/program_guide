// file: src/main.cpp
// 第 60 章驱动：--check FILE
//   TAC → 表达式树（Ershov 标号）→ maximal munch 选指令（瓦片命中报告）
//   → 窥孔清扫（模式命中计数）→ 指令数对账 → RISC 解释器 outputs 对账。
#include "isel.hpp"
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

void dumpTree(const tip::TreeNode &n, int depth) {
    for (int i = 0; i < depth; ++i) std::cout << "    ";
    if (n.kind == 'c') std::cout << "const " << n.value;
    else if (n.kind == 'v') std::cout << "var " << n.name;
    else {
        const char *op = n.op == tip::TOp::Add ? "+"
                       : n.op == tip::TOp::Sub ? "-"
                       : n.op == tip::TOp::Mul ? "*"
                       : n.op == tip::TOp::Div ? "/"
                       : n.op == tip::TOp::Gt ? ">" : "==";
        std::cout << "op " << op;
    }
    std::cout << "  [E" << n.ershov << "]\n";
    if (n.l) dumpTree(*n.l, depth + 1);
    if (n.r) dumpTree(*n.r, depth + 1);
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

    std::cout << "== 表达式树（含 Ershov 标号）==\n";
    std::vector<tip::Risc> sel;
    std::vector<std::string> notes;
    for (const auto &b : blocks) {
        std::vector<tip::Tree> trees = tip::fuseTrees(code, b);
        for (auto &t : trees) {
            std::cout << "  " << t.dst << " =\n";
            tip::ershov(t.root);
            dumpTree(t.root, 1);
            std::vector<tip::Risc> part = tip::munchTree(t.root, notes);
            // 先发射计算，再把树结果 mov 到目的名字
            sel.insert(sel.end(), part.begin(), part.end());
            sel.push_back({"mov", t.dst, t.root.result, -1});
        }
        // 控制流/IO 原样降一条
        for (int i = b.begin; i < b.end; ++i) {
            if (code[i].op == tip::TOp::Output) sel.push_back({"output", code[i].a, "", -1});
            else if (code[i].op == tip::TOp::Input) sel.push_back({"loadi", code[i].dst, "0", -1}),
                notes.push_back("input 按 0 装载（示例不读输入）");
        }
    }

    std::cout << "== 指令选择（maximal munch）==\n";
    for (const auto &r : sel) std::cout << tip::showRisc(r) << '\n';
    for (const auto &n : notes) std::cout << "  (" << n << ")\n";

    auto [clean, hits] = tip::peephole(sel);
    std::cout << "== 窥孔清扫后 ==\n";
    for (const auto &r : clean) std::cout << tip::showRisc(r) << '\n';

    std::cout << "== stats ==\n";
    std::cout << "  instructions: " << sel.size() << " -> " << clean.size() << '\n';
    for (const auto &kv : hits)
        std::cout << "  pattern " << kv.first << " x" << kv.second << '\n';

    std::cout << "== 对账 ==\n";
    tip::TacRun run = tip::tacInterp(code, {});
    std::vector<int> rout = tip::riscRun(clean);
    std::cout << "  tac outputs:";
    for (int v : run.outputs) std::cout << ' ' << v;
    std::cout << "\n  risc outputs:";
    for (int v : rout) std::cout << ' ' << v;
    std::cout << "\n  tac==risc: " << (run.outputs == rout ? "yes" : "NO") << '\n';
    return (run.outputs == rout && clean.size() <= sel.size()) ? 0 : 1;
}
