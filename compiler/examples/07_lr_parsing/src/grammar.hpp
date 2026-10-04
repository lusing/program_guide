// file: src/grammar.hpp
// 第 7 章配套：LR 分析用的文法数据。
// 与第 6 章的关键对照：这里的表达式文法保留左递归——
// LR 分析不但不怕左递归，左递归还天然给出左结合，
// 正是绿龙文法 (6.1) 的原味。
#ifndef TIP_LR_GRAMMAR_HPP
#define TIP_LR_GRAMMAR_HPP

#include <string>
#include <vector>

namespace tip {

struct Production {
    std::string lhs;
    std::vector<std::string> rhs;   // 空向量 = ε 产生式
};

struct Grammar {
    std::string start;
    std::vector<std::string> nonterms;
    std::vector<std::string> terms;   // 不含 "$"
    std::vector<Production> prods;

    bool isTerm(const std::string &s) const;
    bool isNonterm(const std::string &s) const;
    std::string show(const Production &p) const;
};

// 经典表达式文法（绿龙 6.1 的 TIP 化身，左递归原样保留）：
//   expr → expr + term | term ; term → term * factor | factor
//   factor → INT | IDENT | INPUT | ( expr )
Grammar exprGrammarLR();

// 悬挂 else 文法（绿龙 S → iCtS | iCtSeS 的 TIP 化身）：
//   stmt → if ( IDENT ) stmt
//        | if ( IDENT ) stmt else stmt
//        | IDENT
// SLR 造表必然在 ELSE 上出移进-归约冲突，prefer-shift 即“最近 else”。
Grammar danglingElseGrammar();

}  // namespace tip

#endif  // TIP_LR_GRAMMAR_HPP
