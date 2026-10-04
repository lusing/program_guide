// file: src/main.cpp
// 第 7 章驱动：--check FILE
//   1) 左递归表达式文法（绿龙 6.1 的 TIP 化身）：
//      规范 LR(0) 项集族 -> SLR 表 -> 对 FILE 的移进-归约全程；
//   2) 悬挂 else 文法：SLR 冲突现场 + prefer-shift 消解。
#include "grammar.hpp"
#include "lr.hpp"

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
        if (t->getType() == antlr4::Token::EOF) continue;
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

void dumpItems(const tip::SLR &s) {
    std::cout << "== canonical LR(0) collection ==\n";
    for (size_t i = 0; i < s.states.size(); ++i) {
        std::cout << "  I" << i << ":\n";
        for (const auto &it : s.states[i])
            std::cout << "    " << s.showItem(it) << '\n';
    }
}

void dumpTable(const tip::SLR &s) {
    std::cout << "== SLR table ==\n";
    std::vector<std::string> cols = s.g.terms;
    cols.push_back(tip::LR_DOLLAR);
    std::cout << "  state";
    for (const auto &c : cols) std::cout << '\t' << c;
    for (const auto &n : s.g.nonterms) std::cout << '\t' << n;
    std::cout << '\n';
    for (size_t st = 0; st < s.states.size(); ++st) {
        std::cout << "  " << st;
        for (const auto &c : cols) {
            auto it = s.action.find({static_cast<int>(st), c});
            if (it == s.action.end()) std::cout << "\t.";
            else switch (it->second.kind) {
                case tip::Act::Shift: std::cout << "\ts" << it->second.target; break;
                case tip::Act::Reduce: std::cout << "\tr" << it->second.target; break;
                case tip::Act::Accept: std::cout << "\tacc"; break;
                default: std::cout << "\t.";
            }
        }
        for (const auto &n : s.g.nonterms) {
            auto it = s.gotof.find({static_cast<int>(st), n});
            if (it == s.gotof.end()) std::cout << "\t.";
            else std::cout << '\t' << it->second;
        }
        std::cout << '\n';
    }
    if (s.conflicts.empty()) {
        std::cout << "== conflicts ==\n  none\n";
    } else {
        std::cout << "== conflicts ==\n";
        for (const auto &cf : s.conflicts) {
            std::cout << "  action[" << cf.state << ", " << cf.look << "]: "
                      << cf.kind << "（移进 " << cf.shiftTarget;
            for (int r : cf.reduceProds) std::cout << " vs 归约 [" << r << "]";
            std::cout << "）-> " << cf.resolution << '\n';
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

    tip::Grammar eg = tip::exprGrammarLR();
    std::cout << "== grammar: 左递归表达式文法（绿龙 6.1 的 TIP 化身）==\n";
    dumpGrammar(eg);
    tip::SLR slr(eg);
    slr.buildItems();
    slr.buildTable(false);
    dumpItems(slr);
    dumpTable(slr);

    std::cout << "== moves ==\n";
    std::ostringstream os;
    tip::SLR::RunResult r = slr.run(input, os);
    std::cout << os.str();
    if (!r.ok) {
        std::cerr << "syntax error: " << r.error << '\n';
        return 1;
    }

    // ---------- 悬挂 else ----------
    tip::Grammar dg = tip::danglingElseGrammar();
    std::cout << "== grammar: 悬挂 else 文法 ==\n";
    dumpGrammar(dg);
    tip::SLR dslr(dg);
    dslr.buildItems();
    dslr.buildTable(true);
    dumpTable(dslr);
    std::cout << "== moves: if (a) if (b) c else d ==\n";
    std::vector<std::string> demo = {"IF", "LPAREN", "IDENT", "RPAREN",
                                     "IF", "LPAREN", "IDENT", "RPAREN",
                                     "IDENT", "ELSE", "IDENT"};
    std::ostringstream dos;
    tip::SLR::RunResult dr = dslr.run(demo, dos);
    std::cout << dos.str();
    if (!dr.ok) std::cerr << "syntax error: " << dr.error << '\n';
    return dr.ok ? 0 : 1;
}
