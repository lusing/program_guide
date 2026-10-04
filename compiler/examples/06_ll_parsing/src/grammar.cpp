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
    if (p.rhs.empty()) {
        os << " ε";
    } else {
        for (const auto &x : p.rhs) os << ' ' << x;
    }
    return os.str();
}

Grammar exprGrammar() {
    Grammar g;
    g.start = "expr";
    g.nonterms = {"expr", "expr'", "term", "term'", "factor"};
    g.terms = {"INT", "IDENT", "INPUT", "LPAREN", "RPAREN", "PLUS", "STAR"};
    g.prods = {
        {"expr", {"term", "expr'"}},                    // 1
        {"expr'", {"PLUS", "term", "expr'"}},           // 2
        {"expr'", {}},                                  // 3
        {"term", {"factor", "term'"}},                  // 4
        {"term'", {"STAR", "factor", "term'"}},         // 5
        {"term'", {}},                                  // 6
        {"factor", {"INT"}},                            // 7
        {"factor", {"IDENT"}},                          // 8
        {"factor", {"INPUT"}},                          // 9
        {"factor", {"LPAREN", "expr", "RPAREN"}},       // 10
    };
    return g;
}

Grammar stmtGrammar() {
    Grammar g;
    g.start = "stmt";
    g.nonterms = {"stmt", "stmt'"};
    g.terms = {"IF", "LPAREN", "IDENT", "RPAREN", "ELSE"};
    g.prods = {
        {"stmt", {"IF", "LPAREN", "IDENT", "RPAREN", "stmt", "stmt'"}},  // 1
        {"stmt", {"IDENT"}},                                             // 2
        {"stmt'", {"ELSE", "stmt"}},                                     // 3
        {"stmt'", {}},                                                   // 4
    };
    return g;
}

}  // namespace tip
