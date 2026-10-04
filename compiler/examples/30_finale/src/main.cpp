// 第 30 章配套程序：收官总装。
//   --check [FILE] : 打印全教程分析的 Galois 视角总表（固定文本）；
//                    给 FILE 时顺带确认该程序能通过前端（解析+名字解析+CFG）
//   --emit-ir FILE : 打印未优化 LLVM 模块——供 opt 中端流水线实验取材
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
#include "irgen.hpp"
#include "survey.hpp"
#include "symtab.hpp"

class CollectErrorListener : public antlr4::BaseErrorListener {
public:
    std::vector<std::string> messages;

    void syntaxError(antlr4::Recognizer *, antlr4::Token *, size_t line,
                     size_t column, const std::string &msg,
                     std::exception_ptr) override {
        messages.push_back("syntax error line " + std::to_string(line) + ":" +
                           std::to_string(column) + " " + msg);
    }
};

namespace {

struct Parsed {
    std::unique_ptr<tip::ProgramA> ast;
    tip::Bindings bindings;
};

Parsed parseFile(const std::string &path) {
    std::ifstream src(path);
    if (!src) {
        std::cerr << "cannot open " << path << '\n';
        std::exit(1);
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
        std::exit(2);
    }

    Parsed result;
    result.ast = tip::buildAst(tree);
    result.bindings = tip::resolveNames(*result.ast);
    if (!result.bindings.errors.empty()) {
        for (const tip::Diag &d : result.bindings.errors)
            std::cout << d.text << '\n';
        std::exit(3);
    }
    return result;
}

}  // namespace

int main(int argc, char **argv) {
    if (argc >= 2 && std::string(argv[1]) == "--check") {
        if (argc >= 3) {
            // 收官章不引入新分析：只确认样例程序过前端、CFG 可建，
            // 然后输出总表。前端可用性本身就是 30 章成果的一部分。
            Parsed p = parseFile(argv[2]);
            tip::Cfg cfg = tip::buildCfg(*p.ast);
            std::cout << "frontend OK: " << cfg.funs.size()
                      << " function(s) built into CFG\n";
        }
        std::cout << tip::printSurvey();
        return 0;
    }

    if (argc >= 3 && std::string(argv[1]) == "--emit-ir") {
        Parsed p = parseFile(argv[2]);
        tip::IRGen gen;
        gen.gen(*p.ast, p.bindings);
        if (!gen.verify()) {
            std::cerr << "generated module failed verification\n";
            return 1;
        }
        std::cout << gen.dump();
        return 0;
    }

    std::cerr << "usage: tipa --check [FILE] | tipa --emit-ir FILE\n";
    return 1;
}
