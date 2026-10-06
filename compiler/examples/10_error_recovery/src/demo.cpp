// demo 层实现。词法与 LR 文法取自 09 章副本（零改动），新增 error 记号文法与 LL 版。
#include "demo.hpp"

#include <cmath>
#include <sstream>
#include <stdexcept>

namespace tip {

// ---------- mini-lex ----------

MiniLex::MiniLex(std::vector<TokenRule> rules, std::set<char> alphabet)
    : sc_(std::move(rules), std::move(alphabet)) {}

std::vector<LexTok> MiniLex::scan(const std::string &src) const {
    std::vector<LexTok> out;
    for (const std::string &s : sc_.lex(src)) {
        // 产物形如 NAME('text')：第一个 '(' 之前是名字，')' 之前是 yytext。
        size_t lp = s.find('(');
        size_t rp = s.rfind(')');
        LexTok t;
        t.kind = s.substr(0, lp);
        t.text = s.substr(lp + 2, rp - lp - 3);   // 跳过 '(' 与开引号，止于闭引号
        out.push_back(std::move(t));
    }
    return out;
}

// ---------- 词法规则 ----------

namespace {

// 把字符集拼成 (a|b|c) 的择一式——05 章迷你正则没有字符类语法，
// Lex 的 [0-9] 在这里展开成它的原形（教学价值：糖与核心的差）。
std::string altChars(const std::string &chars) {
    std::string s = "(";
    for (size_t i = 0; i < chars.size(); ++i)
        s += std::string(1, chars[i]) + (i + 1 < chars.size() ? "|" : "");
    return s + ")";
}

const std::string kLetters = "abcdefghijklmnopqrstuvwxyz_";
const std::string kDigits = "0123456789";

}  // namespace

std::vector<TokenRule> calcLexRules() {
    std::string L = altChars(kLetters);
    std::string D = altChars(kDigits);
    std::string LD = "(" + L + "|" + D + ")";
    return {
        // 先声明者优先：关键字在 ID 前——同长匹配 "print" 时 KW 胜出。
        {"print", "print"},
        {"NUM", D + D + "*"},
        {"ID", L + LD + "*"},
        // 最长匹配由扫描器保证：'<= '|'==' 无需声明在 '<'、'=' 前，长度定胜负。
        {"<=", "(<)(=)"},
        {"==", "(=)(=)"},
        {"<", "<"},
        {"=", "="},
        {"+", "+"}, {"-", "-"}, {"*", "\\*"}, {"/", "/"}, {"^", "^"},
        {"LPAREN", "\\("}, {"RPAREN", "\\)"}, {";", ";"},
    };
}

std::set<char> calcAlphabet() {
    std::set<char> a(kLetters.begin(), kLetters.end());
    a.insert(kDigits.begin(), kDigits.end());
    for (char c : std::string("<=+-*/^();"))
        a.insert(c);
    return a;
}

std::string fmt(double v) {
    std::ostringstream os;
    os << v;                       // %g 风格：14 而非 14.000000
    return os.str();
}

std::vector<YaccRule> calcRules(CalcEnv &env, int uminusLevel) {
    std::vector<YaccRule> r;
    r.push_back({"prog", {"prog", "stmt"}, {}, "prog-cons", 0});
    r.push_back({"prog", {"stmt"}, {}, "prog-base", 0});
    r.push_back({"stmt", {"ID", "=", "expr", ";"},
                 [&env](std::vector<YaccValue> &v) {
                     env.vars[v[0].asStr("stmt: $1")] = v[2].asNum("stmt: $3");
                     return YaccValue::empty();
                 },
                 "stmt-assign", 0});
    r.push_back({"stmt", {"print", "expr", ";"},
                 [&env](std::vector<YaccValue> &v) {
                     env.printed.push_back(fmt(v[1].asNum("stmt: $2")));
                     return YaccValue::empty();
                 },
                 "stmt-print", 0});
    struct Op { const char *sym; char tag; };
    for (Op op : {Op{"+", '+'}, Op{"-", '-'}, Op{"*", '*'}, Op{"/", '/'}, Op{"^", '^'}}) {
        std::string name = std::string("expr-") + op.tag;
        r.push_back({"expr", {"expr", op.sym, "expr"},
                     [tag = op.tag](std::vector<YaccValue> &v) {
                         double a = v[0].asNum("expr: $1"), b = v[2].asNum("expr: $3");
                         switch (tag) {
                         case '+': return YaccValue::ofNum(a + b);
                         case '-': return YaccValue::ofNum(a - b);
                         case '*': return YaccValue::ofNum(a * b);
                         case '/': return YaccValue::ofNum(a / b);
                         case '^': return YaccValue::ofNum(std::pow(a, b));
                         default: throw std::runtime_error("bad op");
                         }
                     },
                     name, 0});
    }
    r.push_back({"expr", {"-", "expr"},
                 [](std::vector<YaccValue> &v) {
                     return YaccValue::ofNum(-v[1].asNum("expr: $2"));
                 },
                 "expr-neg", uminusLevel});
    r.push_back({"expr", {"LPAREN", "expr", "RPAREN"},
                 [](std::vector<YaccValue> &v) { return v[1]; },
                 "expr-paren", 0});
    r.push_back({"expr", {"NUM"}, {}, "expr-num", 0});      // 缺省 $$ = $1
    r.push_back({"expr", {"ID"},
                 [&env](std::vector<YaccValue> &v) {
                     auto it = env.vars.find(v[0].asStr("expr: $1"));
                     if (it == env.vars.end())
                         throw std::runtime_error("undefined variable: " + v[0].str);
                     return YaccValue::ofNum(it->second);
                 },
                 "expr-id", 0});
    return r;
}

// ---------- error 记号文法（本章新件，L 书 §5.7.3） ----------
std::vector<YaccRule> calcRulesErr(CalcEnv &env) {
    std::vector<YaccRule> r = calcRules(env, 2);
    // stmt → error ';'  ：yacc 的 error 记号——一个不出现在任何词法规则里的
    // 伪终结符。表构造器把它当普通终结符对待（照常造出 shift 列），
    // 恢复驱动在出错时"注入"一个 error token 走这条路。
    r.push_back({"stmt", {"error", ";"},
                 [](std::vector<YaccValue> &) { return YaccValue::empty(); },
                 "stmt-err", 0});
    return r;
}

// ---------- LL(1) 版（第 6 章消左递归手法的应用） ----------
LLGrammar calcLL() {
    LLGrammar g;
    g.start = "prog";
    g.nonterms = {"prog", "progt", "stmt", "expr", "exprt", "term", "termt", "factor"};
    g.terms = {"ID", "NUM", "print", "=", ";", "+", "-", "*", "/", "LPAREN", "RPAREN"};
    g.prods = {
        {"prog",  {"stmt", "progt"}},
        {"progt", {"stmt", "progt"}},
        {"progt", {}},
        {"stmt",  {"ID", "=", "expr", ";"}},
        {"stmt",  {"print", "expr", ";"}},
        {"expr",  {"term", "exprt"}},
        {"exprt", {"+", "term", "exprt"}},
        {"exprt", {"-", "term", "exprt"}},
        {"exprt", {}},
        {"term",  {"factor", "termt"}},
        {"termt", {"*", "factor", "termt"}},
        {"termt", {"/", "factor", "termt"}},
        {"termt", {}},
        {"factor", {"NUM"}},
        {"factor", {"ID"}},
        {"factor", {"LPAREN", "expr", "RPAREN"}},
        {"factor", {"-", "factor"}},
    };
    return g;
}

}  // namespace tip
