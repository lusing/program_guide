// 第 10 章配套：错误语料的舞台——同一门计算器语言的两种文法 + 词法（09 副本）。
#ifndef TIP_DEMO10_HPP
#define TIP_DEMO10_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "llgrammar.hpp"
#include "re.hpp"
#include "yacc.hpp"

namespace tip {

// ---------- 词法（09 章副本，规则表与拆包原样） ----------
struct LexTok {
    std::string kind, text;
};
class MiniLex {
public:
    MiniLex(std::vector<TokenRule> rules, std::set<char> alphabet);
    std::vector<LexTok> scan(const std::string &src) const;
    std::string stats() const { return sc_.stats(); }

private:
    Scanner sc_;
};
std::vector<TokenRule> calcLexRules();
std::set<char> calcAlphabet();

// ---------- 计算环境（09 章副本） ----------
struct CalcEnv {
    std::map<std::string, double> vars;
    std::vector<std::string> printed;
};
std::string fmt(double v);

// ---------- LR 版文法：左递归（09 章副本） ----------
std::vector<YaccRule> calcRules(CalcEnv &env, int uminusLevel);
// ---------- LR 版 + error 记号（本章新件） ----------
// 多一条 stmt → error ';'：错误发生时弹栈至 error 可移进处、丢输入至 ';'。
std::vector<YaccRule> calcRulesErr(CalcEnv &env);

// ---------- LL(1) 版文法：消左递归（第 6 章手法） ----------
// prog  → stmt prog'      prog' → stmt prog' | ε
// stmt  → ID = expr ; | print expr ;
// expr  → term expr'      expr' → (+|-) term expr' | ε
// term  → factor term'    term' → (*|/) factor term' | ε
// factor → NUM | ID | ( expr ) | - factor
LLGrammar calcLL();

}  // namespace tip

#endif  // TIP_DEMO10_HPP
