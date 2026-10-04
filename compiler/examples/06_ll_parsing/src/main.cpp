// file: src/main.cpp
// 第 6 章驱动：--check FILE
//   1) 表达式文法（绿龙 5.9）：FIRST/FOLLOW/表 + 对 FILE 的 token 流做预测分析；
//   2) 悬挂 else 文法（绿龙 5.11）：冲突现场 + “最近 else”消解 + 内嵌样例的推导。
// 词法外包给 ANTLR（第 4 章的 TIP.g4），语法分析完全自研——正好对上
// “词法是自动机（第 5 章），语法是下推自动机（本章）”的分工。
#include "grammar.hpp"
#include "ll1.hpp"

#include "antlr4-runtime.h"
#include "TIPLexer.h"

#include <fstream>
#include <iostream>
#include <sstream>
#include <vector>

namespace {

struct Tok {
    std::string type, text;
};

std::vector<Tok> lexTip(const std::string &path) {
    std::ifstream stream(path);
    if (!stream) throw std::runtime_error("打不开 " + path);
    antlr4::ANTLRInputStream input(stream);
    TIPLexer lexer(&input);
    antlr4::CommonTokenStream tokens(&lexer);
    tokens.fill();
    std::vector<Tok> out;
    for (antlr4::Token *t : tokens.getTokens()) {
        if (t->getType() == antlr4::Token::EOF) continue;   // 结尾的 $ 由调用方补
        std::string name(lexer.getVocabulary().getSymbolicName(t->getType()));
        out.push_back({name, t->getText()});
    }
    return out;
}

void dumpGrammar(const tip::Grammar &g) {
    int i = 0;
    for (const auto &p : g.prods)
        std::cout << "  [" << ++i << "] " << g.show(p) << '\n';
}

void dumpSets(const tip::LL1 &ll) {
    std::cout << "== FIRST ==\n";
    for (const auto &A : ll.g.nonterms) {
        std::cout << "  " << A << ": {";
        bool first = true;
        for (const auto &t : ll.first.at(A)) {
            if (!first) std::cout << ", ";
            std::cout << t;
            first = false;
        }
        std::cout << "}\n";
    }
    std::cout << "== FOLLOW ==\n";
    for (const auto &A : ll.g.nonterms) {
        std::cout << "  " << A << ": {";
        bool first = true;
        for (const auto &t : ll.follow.at(A)) {
            if (!first) std::cout << ", ";
            std::cout << t;
            first = false;
        }
        std::cout << "}\n";
    }
}

void dumpTable(const tip::LL1 &ll) {
    std::cout << "== table ==\n";
    std::vector<std::string> cols = ll.g.terms;
    cols.push_back(tip::DOLLAR);
    std::cout << "  ";
    for (const auto &c : cols) std::cout << '\t' << c;
    std::cout << '\n';
    for (const auto &A : ll.g.nonterms) {
        std::cout << "  " << A;
        for (const auto &c : cols) {
            auto it = ll.table.find({A, c});
            if (it == ll.table.end()) std::cout << "\t.";
            else std::cout << '\t' << (it->second + 1);
        }
        std::cout << '\n';
    }
    if (ll.conflicts.empty()) {
        std::cout << "== conflicts ==\n  none\n";
    } else {
        std::cout << "== conflicts ==\n";
        for (const auto &cf : ll.conflicts) {
            std::cout << "  M[" << cf.A << ", " << cf.a << "]: 候选 {";
            for (size_t i = 0; i < cf.candidates.size(); ++i)
                std::cout << (i ? ", " : "") << (cf.candidates[i] + 1);
            std::cout << "} -> 取 [" << (cf.winner + 1) << "]（最近 else 策略）\n";
        }
    }
}

}  // namespace

int main(int argc, char **argv) {
    if (argc != 3 || std::string(argv[1]) != "--check") {
        std::cerr << "用法: tipa --check FILE\n";
        return 2;
    }
    std::vector<Tok> toks = lexTip(argv[2]);
    std::vector<std::string> input;
    std::cout << "== tokens ==\n";
    for (const auto &t : toks) {
        std::cout << t.type << "('" << t.text << "') ";
        input.push_back(t.type);
    }
    std::cout << "$\n";

    tip::Grammar eg = tip::exprGrammar();
    std::cout << "== grammar: 表达式文法（绿龙 5.9 的 TIP 化身）==\n";
    dumpGrammar(eg);
    tip::LL1 el(eg);
    el.computeFirst();
    el.computeFollow();
    el.buildTable(false);
    dumpSets(el);
    dumpTable(el);

    std::cout << "== parse ==\n";
    tip::ParseResult r = tip::predict(el, input);
    if (r.ok) {
        std::cout << "  leftmost derivation: ";
        for (size_t i = 0; i < r.usedProds.size(); ++i)
            std::cout << (i ? " " : "") << (r.usedProds[i] + 1);
        std::cout << '\n';
        std::cout << "  result: accept\n";
    } else {
        std::cout << "  result: reject\n";
        std::cerr << "syntax error: 第 " << (r.consumed + 1) << " 个 token 处 "
                  << r.error << '\n';
        return 1;
    }

    // ---------- 悬挂 else ----------
    tip::Grammar sg = tip::stmtGrammar();
    std::cout << "== grammar: 悬挂 else 文法（绿龙 5.11 的 TIP 化身）==\n";
    dumpGrammar(sg);
    tip::LL1 sl(sg);
    sl.computeFirst();
    sl.computeFollow();
    sl.buildTable(true);
    dumpTable(sl);
    std::cout << "== parse: if (a) if (b) c else d ==\n";
    std::vector<std::string> demo = {"IF", "LPAREN", "IDENT", "RPAREN",
                                     "IF", "LPAREN", "IDENT", "RPAREN",
                                     "IDENT", "ELSE", "IDENT"};
    tip::ParseResult dr = tip::predict(sl, demo);
    if (dr.ok) {
        std::cout << "  leftmost derivation: ";
        for (size_t i = 0; i < dr.usedProds.size(); ++i)
            std::cout << (i ? " " : "") << (dr.usedProds[i] + 1);
        std::cout << '\n';
        std::cout << "  result: accept（else 归属最内层 then）\n";
    } else {
        std::cout << "  result: reject " << dr.error << '\n';
    }
    return 0;
}
