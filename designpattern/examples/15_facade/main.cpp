// 15 外观。
#include <cassert>
#include <print>

#include "facade.hpp"

int main() {
    using namespace dp;

    // ---- 零件可独立用（外观不封死子系统） ----
    Lexer lex;
    auto toks = lex.tokenize("int x = 1 ;");
    assert(toks.size() == 5);                    // int/x/=/1/;
    std::println("零件: Lexer 独立产出 {} 个词", toks.size());

    Parser par;
    assert(par.parse(toks) == 1);
    std::println("零件: Parser 独立解析出 {} 个节点", par.parse(toks));

    CodeGen gen;
    std::println("零件: CodeGen 独立产出 \"{}\"", gen.emit(1));

    // ---- Facade 串联三步 ----
    Compiler compiler;
    auto result = compiler.compile("int x = 1 ;");
    assert(result.find("tokens:5") != std::string::npos);
    assert(result.find("nodes:1") != std::string::npos);
    std::println("门面: compile -> {}", result);

    // 同一门面，不同输入：调用方零知识切换
    auto r2 = compiler.compile("int y = 2 ; int z = 3 ;");
    std::println("门面: compile -> {}", r2);
    assert(r2.find("tokens:10") != std::string::npos);

    std::println("自检通过");
}
