// demo 层：mini-lex（Lex 心脏的规则表包装）与计算器文法（yacc 心脏的消费者）。
#ifndef TIP_DEMO_HPP
#define TIP_DEMO_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "re.hpp"    // TokenRule / Scanner：Lex 心脏住在第 5 章的机器里
#include "yacc.hpp"

namespace tip {

// ---------- mini-lex：Lex 规格的最小对应物 ----------
// Lex 心脏 = 规则表（正则→动作）+ 最长匹配 + 同长先声明优先。
// 这三样恰好是第 5 章多模式 Scanner 的全部——所以这里一行不改地复用它，
// 只把 "NAME('text')" 的字符串产物拆回结构化 token（yylval 的填充点）。
struct LexTok {
    std::string kind, text;   // kind 即文法终结符名；text 即 yytext
};

class MiniLex {
public:
    MiniLex(std::vector<TokenRule> rules, std::set<char> alphabet);
    // 空白跳过；无法成词的字符输出 kind="ERR"。
    std::vector<LexTok> scan(const std::string &src) const;
    std::string stats() const { return sc_.stats(); }

private:
    Scanner sc_;
};

// ---------- 计算器语言 ----------
// stmt → ID '=' expr ';' | 'print' expr ';'
// expr → expr op expr | '-' expr | '(' expr ')' | NUM | ID     （op ∈ + - * / ^）
// 表达式文法刻意二义（yacc 用优先级声明消解，而非改文法）——见 demo.cpp。

struct CalcEnv {
    std::map<std::string, double> vars;     // ID 的家
    std::vector<std::string> printed;       // print 语句的输出
};

std::string fmt(double v);

// 规则集三份口径：uminusLevel = '-' expr 的 %prec 级别（0 = 不声明）。
std::vector<YaccRule> calcRules(CalcEnv &env, int uminusLevel);

// 计算器语言的词法规则（先声明者优先：print 在 ID 前）。
std::vector<TokenRule> calcLexRules();
std::set<char> calcAlphabet();

// ---------- 嵌入动作改写的对照文法 ----------
// A 形（用户写法）  ：stmt2 → ID #chk1 '=' expr #chk2 ';'
// B 形（改写产物）  ：#chk / #chk2 变 ε 非终结符——rewriteEmbedded 的输出
// C 形（手写等价）  ：N1/N2 手写 ε 规则——独立复核
struct EmbedEnv {
    std::map<std::string, double> vars;
    std::vector<std::string> log;
};
std::vector<YaccRule> embedRulesA(EmbedEnv &env);   // 含 '#' 占位符（不可直接构造表）
std::vector<YaccRule> embedRulesC(EmbedEnv &env);   // 手写 N1/N2 版
std::map<std::string, std::pair<YaccAction, std::string>> embedActions(EmbedEnv &env);

}  // namespace tip

#endif  // TIP_DEMO_HPP
