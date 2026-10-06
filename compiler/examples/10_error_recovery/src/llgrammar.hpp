// file: src/llgrammar.hpp
// 第 6 章配套：LL(1) 分析的“文法即数据”。
// 两个内置文法都是绿龙第 5 章的原装货：
//   expr  —— 文法 (5.9)，消除了左递归的经典表达式文法；
//   stmt  —— 文法 (5.11) 的 TIP 风格化身，自带悬挂 else 冲突。
#ifndef TIP_LL_GRAMMAR_HPP
#define TIP_LL_GRAMMAR_HPP

#include <string>
#include <vector>

namespace tip {

struct Production {
    std::string lhs;
    std::vector<std::string> rhs;   // 空向量 = ε 产生式
};

struct LLGrammar {
    std::string start;
    std::vector<std::string> nonterms;
    std::vector<std::string> terms;   // 不含 "$"；"$" 是输入与栈的公共同界符
    std::vector<Production> prods;

    bool isTerm(const std::string &s) const;
    bool isNonterm(const std::string &s) const;
    std::string show(const Production &p) const;
};

// E → T E' ; E' → + T E' | ε ; T → F T' ; T' → * F T' | ε ; F → INT|IDENT|INPUT|( E )
// 与绿龙 (5.9) 同构，只是 id 换成了 TIP 的 INT/IDENT/INPUT 三种“原子”。
LLGrammar exprLLGrammar();

// stmt  → if ( IDENT ) stmt stmt'
// stmt' → else stmt | ε
// 对应绿龙 (5.11)：M[stmt', else] 双定义——悬挂 else 的教科书现场。
LLGrammar stmtLLGrammar();

}  // namespace tip

#endif  // TIP_LL_GRAMMAR_HPP
