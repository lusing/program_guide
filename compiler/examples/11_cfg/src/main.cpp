// 第 11 章配套程序：解析 -> AST -> 名字解析 -> 构造控制流图。
// 名字无误时打印每个函数的程序点与边；词法/语法错误退出码 2，语义错误 3。
#include <fstream>
#include <iostream>
#include <memory>
#include <string>
#include <vector>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line, size_t column,
                     const std::string &msg, std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    std::ifstream src(argv[2]);
    if (!src) {
        std::cerr << "cannot open " << argv[2] << '\n';
        return 1;
    }

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
    if (!errors.messages.empty()) {
        for (const std::string &m : errors.messages) std::cout << m << '\n';
        return 2;
    }

    std::unique_ptr<tip::ProgramA> ast = tip::buildAst(tree);
    tip::Bindings bindings = tip::resolveNames(*ast);
    if (!bindings.errors.empty()) {
        for (const tip::Diag &d : bindings.errors) std::cout << d.text << '\n';
        return 3;
    }

    tip::Cfg cfg = tip::buildCfg(*ast);
    std::cout << tip::printCfg(cfg);
    return 0;
}
