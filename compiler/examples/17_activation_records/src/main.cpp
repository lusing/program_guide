// file: src/main.cpp
// 第 17 章驱动：--check FILE
//   各函数 TAC → 帧布局 → VM 执行（帧轨迹）→ 哈希版解释器执行 → 对账。
#include "tacgen.hpp"
#include "tacinterp.hpp"
#include "vm.hpp"

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

    std::cout << "== TAC ==\n";
    tip::Vm vm;
    tip::TacInterp interp;
    for (const auto &fn : p.ast->funs) {
        std::vector<tip::Quad> code = tip::tacGen(*fn);
        std::cout << "  fun " << fn->name << ":\n";
        for (size_t i = 0; i < code.size(); ++i)
            std::cout << "    " << i << ": " << tip::show(code[i]) << '\n';
        vm.define(*fn, code);
        interp.define(fn->name, fn->params, code);
    }

    std::cout << "== 帧布局 ==\n";
    for (const auto &fn : p.ast->funs) {
        std::cout << "  " << fn->name << ": [ret | ctrl |";
        for (const auto &v : fn->params) std::cout << ' ' << v;
        for (const auto &v : fn->vars) std::cout << ' ' << v;
        std::cout << " ]  共 "
                  << (fn->params.size() + fn->vars.size()) << " 槽\n";
    }

    std::cout << "== VM 轨迹 ==\n";
    tip::VmRun vr = vm.run({});
    for (const auto &t : vr.trace) std::cout << "  " << t << '\n';
    std::cout << "== outputs (vm) ==\n ";
    for (int v : vr.outputs) std::cout << ' ' << v;
    std::cout << '\n';

    std::cout << "== outputs (interp) ==\n ";
    tip::TacRun tr = interp.run({});
    for (int v : tr.outputs) std::cout << ' ' << v;
    std::cout << " ; steps = " << tr.steps << '\n';

    std::cout << "== 对账 ==\n";
    std::cout << "  vm==interp: " << (vr.outputs == tr.outputs ? "yes" : "NO") << '\n';
    return vr.outputs == tr.outputs ? 0 : 1;
}
