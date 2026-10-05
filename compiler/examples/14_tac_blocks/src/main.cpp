// file: src/main.cpp
// 第 14 章驱动：--check FILE
//   TAC 全文 → 基本块划分 → 每块 next-use 表 →
//   TAC 解释器执行 → LLVM JIT 执行 → interp==jit 对账。
#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "memmodel.hpp"
#include "tacinterp.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"
#include "TIPParser.h"

#include "ast.hpp"
#include "ast_build.hpp"
#include "symtab.hpp"
#include "irgen.hpp"
#include "jitrun.hpp"

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

    Parsed result;
    result.ast = tip::buildAst(tree);
    result.bindings = tip::resolveNames(*result.ast);
    if (!result.bindings.errors.empty())
        throw std::runtime_error("名字解析错误: " + result.bindings.errors.front().text);
    return result;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    Parsed p = parseFile(argv[2]);
    const tip::FunDecl &fn = *p.ast->funs.front();
    if (p.ast->funs.size() > 1 || fn.name != "main") {
        std::cerr << "本章示例只处理单 main 函数\n";
        return 2;
    }

    std::vector<tip::Quad> code = tip::tacGen(fn);

    std::cout << "== TAC ==\n";
    for (size_t i = 0; i < code.size(); ++i)
        std::cout << "  " << i << ": " << tip::show(code[i]) << '\n';

    std::vector<tip::Block> blocks = tip::partitionBlocks(code);
    std::cout << "== blocks ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << " [" << b.begin << "," << b.end << ") succs:";
        for (int s : b.succs) std::cout << " " << s;
        std::cout << '\n';
    }

    std::cout << "== next-use ==\n";
    for (const auto &b : blocks) {
        std::cout << "  B" << b.id << ":\n";
        auto nu = tip::nextUse(code, b);
        for (int i = b.begin; i < b.end; ++i) {
            std::cout << "    " << i << ": " << tip::show(code[i]);
            bool any = false;
            for (const auto &kv : nu) {
                if (kv.first.first != i) continue;
                std::cout << "  | " << kv.first.second
                          << " next@" << (kv.second < 0 ? std::string("-") : std::to_string(kv.second));
                any = true;
            }
            if (!any) std::cout << "  | -";
            std::cout << '\n';
        }
    }

    // ---------- 解释器 vs JIT ----------
    std::cout << "== interp ==\n";
    tip::TacRun run = tip::tacInterp(code, {});
    std::cout << "  outputs:";
    for (int v : run.outputs) std::cout << ' ' << v;
    std::cout << " ; steps = " << run.steps << '\n';

    std::cout << "== jit ==\n";
    tip::IRGen gen;
    gen.gen(*p.ast, p.bindings);
    if (!gen.verify()) {
        std::cerr << "generated module failed verification\n";
        return 1;
    }
    std::vector<int> jout = tip::runJit(std::move(gen), {});
    std::cout << "  outputs:";
    for (int v : jout) std::cout << ' ' << v;
    std::cout << '\n';

    std::cout << "== 对账 ==\n";
    std::cout << "  interp==jit: " << (run.outputs == jout ? "yes" : "NO") << '\n';

    // ---------- 内存模型：值的二分法（鲸书 §5.4.3）----------
    std::cout << "== 内存模型（可寄存器判定）==\n";
    std::vector<std::string> names = {"a", "b", "c", "s"};
    // 粗别名信息：p 与 q 的去向（第 49 章的指针分析负责提供成色）
    std::map<std::string, std::set<std::string>> coarse = {{"p", {"a", "b"}}};
    std::map<std::string, std::set<std::string>> fine = {{"p", {"a"}}};
    tip::MemModelReport m1 = tip::memoryModel(names, coarse, {"p"});
    tip::MemModelReport m2 = tip::memoryModel(names, fine, {"p"});
    for (const auto &s : m1.notes) std::cout << "  粗: " << s << "\n";
    std::cout << "  粗: ambiguous={";
    bool first = true;
    for (const auto &v : m1.ambiguous) { std::cout << (first ? "" : ",") << v; first = false; }
    std::cout << "} unambiguous={";
    first = true;
    for (const auto &v : m1.unambiguous) { std::cout << (first ? "" : ",") << v; first = false; }
    std::cout << "}\n";
    std::cout << "  精(pointees={a}): ambiguous={";
    first = true;
    for (const auto &v : m2.ambiguous) { std::cout << (first ? "" : ",") << v; first = false; }
    std::cout << "} ← b 复归可寄存器（别名分析的精度直接换寄存器）\n";
    bool mmOk = m1.ambiguous.count("a") && m1.ambiguous.count("b")
                && m2.ambiguous.count("a") && m2.unambiguous.count("b");
    std::cout << "  粗杀 a+b、精只杀 a: " << (mmOk ? "yes" : "NO") << "\n";
    return (run.outputs == jout && mmOk) ? 0 : 1;
}
