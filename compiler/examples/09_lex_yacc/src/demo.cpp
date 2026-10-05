// demo 层实现。
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

// ---------- 计算器文法 ----------

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

// ---------- 嵌入动作对照 ----------

std::vector<YaccRule> embedRulesA(EmbedEnv &env) {
    // 用户写法：两个嵌入动作夹在产生式中间（'#' 占位）。
    return {
        {"prog2", {"prog2", "stmt2"}, {}, "prog2-cons", 0},
        {"prog2", {"stmt2"}, {}, "prog2-base", 0},
        {"stmt2", {"ID", "#chk1", "=", "expr2", "#chk2", ";"},
         [&env](std::vector<YaccValue> &v) {
             env.vars[v[0].asStr("stmt2: $1")] = v[3].asNum("stmt2: $4");
             env.log.push_back("stmt2-done");
             return YaccValue::empty();
         },
         "stmt2", 0},
        {"expr2", {"expr2", "+", "expr2"},
         [](std::vector<YaccValue> &v) { return YaccValue::ofNum(v[0].asNum("$1") + v[2].asNum("$3")); },
         "expr2-add", 0},
        {"expr2", {"expr2", "*", "expr2"},
         [](std::vector<YaccValue> &v) { return YaccValue::ofNum(v[0].asNum("$1") * v[2].asNum("$3")); },
         "expr2-mul", 0},
        {"expr2", {"NUM"}, {}, "expr2-num", 0},
        {"expr2", {"ID"},
         [&env](std::vector<YaccValue> &v) {
             auto it = env.vars.find(v[0].asStr("expr2: $1"));
             if (it == env.vars.end())
                 throw std::runtime_error("undefined variable: " + v[0].str);
             return YaccValue::ofNum(it->second);
         },
         "expr2-id", 0},
    };
}

std::vector<YaccRule> embedRulesC(EmbedEnv &env) {
    // 手写改写：N1/N2 是 ε 非终结符——与 rewriteEmbedded 的自动产物对账。
    return {
        {"prog2", {"prog2", "stmt2"}, {}, "prog2-cons", 0},
        {"prog2", {"stmt2"}, {}, "prog2-base", 0},
        {"stmt2", {"ID", "N1", "=", "expr2", "N2", ";"},
         [&env](std::vector<YaccValue> &v) {
             env.vars[v[0].asStr("stmt2: $1")] = v[3].asNum("stmt2: $4");
             env.log.push_back("stmt2-done");
             return YaccValue::empty();
         },
         "stmt2", 0},
        {"expr2", {"expr2", "+", "expr2"},
         [](std::vector<YaccValue> &v) { return YaccValue::ofNum(v[0].asNum("$1") + v[2].asNum("$3")); },
         "expr2-add", 0},
        {"expr2", {"expr2", "*", "expr2"},
         [](std::vector<YaccValue> &v) { return YaccValue::ofNum(v[0].asNum("$1") * v[2].asNum("$3")); },
         "expr2-mul", 0},
        {"expr2", {"NUM"}, {}, "expr2-num", 0},
        {"expr2", {"ID"},
         [&env](std::vector<YaccValue> &v) {
             auto it = env.vars.find(v[0].asStr("expr2: $1"));
             if (it == env.vars.end())
                 throw std::runtime_error("undefined variable: " + v[0].str);
             return YaccValue::ofNum(it->second);
         },
         "expr2-id", 0},
        {"N1", {}, [&env](std::vector<YaccValue> &) { env.log.push_back("#chk1-after-ID"); return YaccValue::empty(); }, "N1", 0},
        {"N2", {}, [&env](std::vector<YaccValue> &) { env.log.push_back("#chk2-after-expr"); return YaccValue::empty(); }, "N2", 0},
    };
}

std::map<std::string, std::pair<YaccAction, std::string>> embedActions(EmbedEnv &env) {
    return {
        {"#chk1", {[&env](std::vector<YaccValue> &) {
                       env.log.push_back("#chk1-after-ID");
                       return YaccValue::empty();
                   }, "#chk1"}},
        {"#chk2", {[&env](std::vector<YaccValue> &) {
                       env.log.push_back("#chk2-after-expr");
                       return YaccValue::empty();
                   }, "#chk2"}},
    };
}

}  // namespace tip
