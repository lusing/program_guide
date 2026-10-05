// file: src/main.cpp
// 第 11 章驱动（无参运行，走"简单程序"对账协议）：
//   一、Pratt 语料求值（含幂右结合/调用/一元链）；
//   二、陷阱构造的 AST 形状（-a.b、*p+1、f(1)(2)——只看形状不求值）；
//   三、与 LL(1) 分层法对同一语料对账（同一词法、同一 AST、同一求值器）；
//   四、结合性实验：把减号改成右结合的"坏表"，2-3-4 从 -5 变 3；
//   五、断言汇总。
#include "llref.hpp"
#include "pratt.hpp"

#include <iostream>
#include <string>
#include <vector>

namespace {

using Env = std::map<std::string, long long>;

int g_failures = 0;

void check(const std::string &name, const std::string &got, const std::string &want) {
    bool ok = got == want;
    if (!ok) ++g_failures;
    std::cout << (ok ? "ok   " : "FAIL ") << name << " = " << got;
    if (!ok) std::cout << "（期望 " << want << "）";
    std::cout << "\n";
}

std::string evalStr(const tip::Expr &e, const Env &env,
                    const std::map<std::string, tip::BuiltinFn> &builtins) {
    std::string err;
    long long v = tip::evalExpr(e, env, builtins, &err);
    return err.empty() ? std::to_string(v) : "错误:" + err;
}

}  // namespace

int main() {
    // 语料变量：x=4, y=3, a=10, b=2, p=100, r=7
    Env env{{"x", 4}, {"y", 3}, {"a", 10}, {"b", 2}, {"p", 100}, {"r", 7}};
    std::map<std::string, tip::BuiltinFn> builtins{
        {"abs", [](std::vector<long long> v) { return v[0] < 0 ? -v[0] : v[0]; }},
        {"max", [](std::vector<long long> v) { return v[0] > v[1] ? v[0] : v[1]; }},
        {"gcd", [](std::vector<long long> v) {
             while (v[1] != 0) { long long t = v[0] % v[1]; v[0] = v[1]; v[1] = t; }
             return v[0];
         }},
    };

    auto evalPratt = [&](const std::string &src) {
        std::vector<tip::ParseError> errs;
        tip::ExprP e = tip::parsePratt(src, errs);
        if (!e) return "解析错误:" + (errs.empty() ? "?" : errs[0].msg);
        return evalStr(*e, env, builtins);
    };

    std::cout << "== 一、Pratt 语料求值 ==\n";
    struct Item { const char *src; const char *want; };
    const Item corpus[] = {
        {"1+2*3", "7"},           {"(1+2)*3", "9"},
        {"10-3-2", "5"},          {"100/10/5", "2"},
        {"2*3/4", "1"},           {"1+2==3", "1"},
        {"4-1>1+0", "1"},         {"3>=3", "1"},
        {"2<=1", "0"},            {"1!=2", "1"},
        {"-3+5", "2"},            {"-(2-5)", "3"},
        {"x+y*2", "10"},          {"a-b-1", "7"},
        {"abs(3-8)*2", "10"},     {"max(2,7)+1", "8"},
        {"gcd(12,18)+2", "8"},    {"2^3^2", "512"},
        {"(2^3)^2", "64"},        {"-2^2", "4"},
    };
    for (const auto &it : corpus) check(it.src, evalPratt(it.src), it.want);

    std::cout << "\n== 二、陷阱构造的 AST 形状 ==\n";
    struct Shape { const char *src; const char *want; };
    const Shape shapes[] = {
        // 一元负号先结合还是字段先结合？表说字段（Call 级）高于负号（Unary 级）
        {"-r.f", "(- (. r f))"},
        // 解引用同理：*p.f 是 *(p.f)，要 (*p).f 得写括号——匠书 §6.3 同款陷阱
        {"*p.f", "(* (. p f))"},
        {"(*p).f", "(. (* p) f)"},
        {"*p+1", "(+ (* p) 1)"},
        {"&x", "(& x)"},
        // 调用是后缀：f(1)(2) = (f(1))(2)，Pratt 的中缀 "(" 天然支持链式调用
        {"f(1)(2)", "(call (call f 1) 2)"},
        {"-f(3)", "(- (call f 3))"},
        {"--x", "(- (- x))"},
    };
    for (const auto &s : shapes) {
        std::vector<tip::ParseError> errs;
        tip::ExprP e = tip::parsePratt(s.src, errs);
        check(s.src, e ? tip::showAst(*e) : "解析错误", s.want);
    }

    std::cout << "\n== 三、与 LL(1) 分层法对账（共同语料）==\n";
    // 交集 = 两法都能接受的文法：算术/比较/一元负号/括号/变量（无幂、无调用、无字段）
    // 对账双保险：值相等（喂同一求值器）+ 形状相等（S-表达式逐字符）。
    const char *shared[] = {
        "1+2*3", "(1+2)*3", "10-3-2", "100/10/5", "2*3/4",
        "1+2==3", "4-1>1+0", "3>=3", "2<=1", "1!=2",
        "-3+5", "-(2-5)", "x+y*2", "a-b-1", "--x",
    };
    for (const char *src : shared) {
        std::vector<tip::ParseError> e1, e2;
        tip::ExprP p1 = tip::parsePratt(src, e1);
        tip::ExprP p2 = tip::parseLl(src, e2);
        std::string v1 = p1 ? evalStr(*p1, env, builtins) : "解析错误";
        std::string v2 = p2 ? evalStr(*p2, env, builtins) : "解析错误";
        check(std::string(src) + "（pratt=ll 值）", v1, v2);
        std::string s1 = p1 ? tip::showAst(*p1) : "解析错误";
        std::string s2 = p2 ? tip::showAst(*p2) : "解析错误";
        check(std::string(src) + "（pratt=ll 形状）", s1, s2);
    }

    std::cout << "\n== 四、结合性实验 ==\n";
    // 坏表：把减号改成右结合。左结合 2-3-4=(2-3)-4=-5；右结合=2-(3-4)=3。
    // 同一构造、只翻表里一格布尔值，结果就分岔——结合性住在表里，不住在代码里。
    check("2-3-4 左结合", evalPratt("2-3-4"), "-5");
    {
        std::vector<tip::ParseError> errs;
        std::vector<tip::Token> toks = tip::lex("2-3-4", errs);
        tip::PrattParser bad(std::move(toks));
        bad.setRightAssoc(tip::Tok::Minus);
        tip::ExprP e = bad.parseExpression(tip::Prec::None);
        check("2-3-4 右结合（坏表）", e ? evalStr(*e, env, builtins) : "解析错误", "3");
        check("坏表形状", e ? tip::showAst(*e) : "?", "(- 2 (- 3 4))");
    }
    check("2^3^2 右结合", evalPratt("2^3^2"), "512");
    check("(2^3)^2 括号强制", evalPratt("(2^3)^2"), "64");

    std::cout << "\n== 五、断言汇总 ==\n";
    if (g_failures == 0) {
        std::cout << "全部通过（" << (sizeof(corpus) / sizeof(corpus[0]) +
                                      sizeof(shapes) / sizeof(shapes[0]) +
                                      2 * (sizeof(shared) / sizeof(shared[0])) + 5)
                  << " 项）\n";
        return 0;
    }
    std::cout << g_failures << " 项失败\n";
    return 1;
}
