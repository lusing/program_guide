// file: src/grammar.cpp
#include "grammar.hpp"

#include <sstream>

namespace tip {

bool Grammar::isTerm(const std::string &s) const {
    for (const auto &t : terms)
        if (t == s) return true;
    return false;
}

bool Grammar::isNonterm(const std::string &s) const {
    for (const auto &t : nonterms)
        if (t == s) return true;
    return false;
}

std::string Grammar::show(const Production &p) const {
    std::ostringstream os;
    os << p.lhs << " ->";
    if (p.rhs.empty()) os << " ε";
    else for (const auto &x : p.rhs) os << ' ' << x;
    return os.str();
}

Grammar exprGrammarLR() {
    Grammar g;
    g.start = "expr";
    g.nonterms = {"expr", "term", "factor"};
    g.terms = {"INT", "IDENT", "INPUT", "LPAREN", "RPAREN", "PLUS", "STAR"};
    g.prods = {
        {"expr", {"expr", "PLUS", "term"}},            // 1
        {"expr", {"term"}},                            // 2
        {"term", {"term", "STAR", "factor"}},          // 3
        {"term", {"factor"}},                          // 4
        {"factor", {"INT"}},                           // 5
        {"factor", {"IDENT"}},                         // 6
        {"factor", {"INPUT"}},                         // 7
        {"factor", {"LPAREN", "expr", "RPAREN"}},      // 8
    };
    return g;
}

Grammar danglingElseGrammar() {
    Grammar g;
    g.start = "stmt";
    g.nonterms = {"stmt"};
    g.terms = {"IF", "LPAREN", "IDENT", "RPAREN", "ELSE"};
    g.prods = {
        {"stmt", {"IF", "LPAREN", "IDENT", "RPAREN", "stmt"}},                   // 1
        {"stmt", {"IF", "LPAREN", "IDENT", "RPAREN", "stmt", "ELSE", "stmt"}},   // 2
        {"stmt", {"IDENT"}},                                                     // 3
    };
    return g;
}

}  // namespace tip
