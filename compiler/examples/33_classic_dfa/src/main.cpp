// 第 33 章配套程序：四大经典数据流分析总装。
//   --check FILE : 对同一程序分别跑活跃变量/到达定值/可用表达式/非常忙表达式，
//                  逐点打印"流出"因子集合
#include <fstream>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <string>

#include "TIPLexer.h"
#include "TIPParser.h"
#include "antlr4-runtime.h"

#include "ast_build.hpp"
#include "cfg.hpp"
#include "dfa.hpp"
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
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "usage: tipa --check FILE\n";
        return 1;
    }

    Parsed p = parseFile(argv[2]);
    tip::Cfg cfg = tip::buildCfg(*p.ast);
    using tip::FactSet;

    // 活跃变量（后向 may）：gen=语句使用的变量，kill=被赋值变量。
    tip::DfaSpec live{"live variables (backward, may)", false, true,
                      [](const tip::Stmt *s) -> FactSet {
                          const tip::Expr *e = tip::stmtExpr(s);
                          if (!e) return {};
                          return tip::exprVars(e);
                      },
                      [](const tip::Stmt *s) -> FactSet {
                          std::string t = tip::assignTargetName(s);
                          if (t.empty()) return {};
                          return {t};
                      }};

    // 到达定值（前向 may）：因子=定值点编号 dN；gen=本定值，kill=同变量的其余定值。
    std::map<const tip::Stmt *, std::string> defName;
    {
        int d = 0;
        for (const tip::FunCfg &fc : cfg.funs)
            for (const auto &[id, node] : fc.nodes)
                if (node.stmt && tip::assignTargetName(node.stmt) != "")
                    defName[node.stmt] = "d" + std::to_string(++d) + "(" +
                                         tip::assignTargetName(node.stmt) + "@" +
                                         fc.name + ":" + std::to_string(id) + ")";
    }
    tip::DfaSpec reaching{"reaching definitions (forward, may)", true, true,
                          [&defName](const tip::Stmt *s) -> FactSet {
                              auto it = defName.find(s);
                              if (it == defName.end()) return {};
                              return {it->second};
                          },
                          [&defName](const tip::Stmt *s) -> FactSet {
                              auto it = defName.find(s);
                              if (it == defName.end()) return {};
                              std::string t = tip::assignTargetName(s);
                              FactSet k;
                              for (const auto &[stmt, name] : defName)
                                  if (stmt != s &&
                                      tip::assignTargetName(stmt) == t)
                                      k.insert(name);
                              return k;
                          }};

    // 可用/非常忙表达式（must）：因子=子式文本；gen=语句计算的子式，
    // kill=全程序中含被赋值变量的子式（教学实现，够用且单调）。
    std::set<std::string> allTerms;
    for (const tip::FunCfg &fc : cfg.funs)
        for (const auto &[id, node] : fc.nodes)
            if (node.stmt) {
                const tip::Expr *e = tip::stmtExpr(node.stmt);
                if (e) {
                    FactSet fs = tip::exprSubTerms(e);
                    allTerms.insert(fs.begin(), fs.end());
                }
            }
    auto killByTarget = [&allTerms](const tip::Stmt *s) -> FactSet {
        std::string t = tip::assignTargetName(s);
        if (t.empty()) return {};
        FactSet k;
        for (const std::string &term : allTerms)
            if (term.find(t) != std::string::npos) k.insert(term);
        return k;
    };
    auto genTerms = [](const tip::Stmt *s) -> FactSet {
        const tip::Expr *e = tip::stmtExpr(s);
        if (!e) return {};
        return tip::exprSubTerms(e);
    };
    tip::DfaSpec available{"available expressions (forward, must)", true, false,
                           genTerms, killByTarget};
    tip::DfaSpec veryBusy{"very busy expressions (backward, must)", false, false,
                          genTerms, killByTarget};

    std::cout << tip::printDfa(cfg, tip::runDfa(cfg, live), live);
    std::cout << tip::printDfa(cfg, tip::runDfa(cfg, reaching), reaching);
    std::cout << tip::printDfa(cfg, tip::runDfa(cfg, available), available);
    std::cout << tip::printDfa(cfg, tip::runDfa(cfg, veryBusy), veryBusy);
    return 0;
}
