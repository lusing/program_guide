// file: src/pratt.cpp
#include "pratt.hpp"

#include <cctype>
#include <sstream>

namespace tip {

// ---------- 词法 ----------
std::vector<Token> lex(const std::string &src, std::vector<ParseError> &errs) {
    std::vector<Token> out;
    size_t i = 0;
    int line = 1;
    auto push2 = [&](Tok t, std::string s) { out.push_back({t, std::move(s), 0, line}); };
    while (i < src.size()) {
        char c = src[i];
        if (c == '\n') { ++line; ++i; continue; }
        if (std::isspace(static_cast<unsigned char>(c))) { ++i; continue; }
        if (std::isdigit(static_cast<unsigned char>(c))) {
            std::string s;
            while (i < src.size() && std::isdigit(static_cast<unsigned char>(src[i]))) s += src[i++];
            long long v = 0;
            std::istringstream(s) >> v;
            out.push_back({Tok::Int, s, v, line});
            continue;
        }
        if (std::isalpha(static_cast<unsigned char>(c)) || c == '_') {
            std::string s;
            while (i < src.size() &&
                   (std::isalnum(static_cast<unsigned char>(src[i])) || src[i] == '_'))
                s += src[i++];
            push2(Tok::Ident, std::move(s));
            continue;
        }
        // 双字符运算符先行
        if (i + 1 < src.size()) {
            std::string two = src.substr(i, 2);
            if (two == "<=") { push2(Tok::Le, two); i += 2; continue; }
            if (two == ">=") { push2(Tok::Ge, two); i += 2; continue; }
            if (two == "==") { push2(Tok::Eq, two); i += 2; continue; }
            if (two == "!=") { push2(Tok::Ne, two); i += 2; continue; }
        }
        switch (c) {
            case '+': push2(Tok::Plus, "+"); break;
            case '-': push2(Tok::Minus, "-"); break;
            case '*': push2(Tok::Star, "*"); break;
            case '/': push2(Tok::Slash, "/"); break;
            case '^': push2(Tok::Caret, "^"); break;
            case '(': push2(Tok::LParen, "("); break;
            case ')': push2(Tok::RParen, ")"); break;
            case '<': push2(Tok::Lt, "<"); break;
            case '>': push2(Tok::Gt, ">"); break;
            case '=': push2(Tok::Eq, "="); break;   // 语料只用 ==
            case '&': push2(Tok::Amp, "&"); break;
            case '.': push2(Tok::Dot, "."); break;
            case ',': push2(Tok::Comma, ","); break;
            default:
                errs.push_back({"意外字符 '" + std::string(1, c) + "'", line});
                break;
        }
        ++i;
    }
    out.push_back({Tok::Eof, "", 0, line});
    return out;
}

// ---------- 形状打印 ----------
std::string showAst(const Expr &e) {
    if (auto *n = dynamic_cast<const IntLit *>(&e)) return std::to_string(n->v);
    if (auto *n = dynamic_cast<const VarRef *>(&e)) return n->name;
    if (auto *n = dynamic_cast<const Unary *>(&e)) {
        std::string op = n->op == Tok::Minus ? "-" : (n->op == Tok::Star ? "*" : "&");
        return "(" + op + " " + showAst(*n->sub) + ")";
    }
    if (auto *n = dynamic_cast<const Binop *>(&e)) {
        std::string op;
        switch (n->op) {
            case Tok::Plus: op = "+"; break;   case Tok::Minus: op = "-"; break;
            case Tok::Star: op = "*"; break;   case Tok::Slash: op = "/"; break;
            case Tok::Caret: op = "^"; break;  case Tok::Lt: op = "<"; break;
            case Tok::Le: op = "<="; break;    case Tok::Gt: op = ">"; break;
            case Tok::Ge: op = ">="; break;    case Tok::Eq: op = "=="; break;
            default: op = "!="; break;
        }
        return "(" + op + " " + showAst(*n->l) + " " + showAst(*n->r) + ")";
    }
    if (auto *n = dynamic_cast<const CallE *>(&e)) {
        std::string s = "(call " + showAst(*n->callee);
        for (const auto &a : n->args) s += " " + showAst(*a);
        return s + ")";
    }
    if (auto *n = dynamic_cast<const FieldA *>(&e))
        return "(. " + showAst(*n->rec) + " " + n->field + ")";
    return "?";
}

// ---------- Pratt 解析器 ----------
PrattParser::PrattParser(std::vector<Token> toks) : toks_(std::move(toks)) {}

Prec up(Prec p) { return static_cast<Prec>(static_cast<int>(p) + 1); }

// 规则表本体：一张表就是整门语言的表达式文法。
// 对比第 6 章 LL(1)：那里每层优先级一个函数（cmp/add/mul/unary/primary），
// 这里每层只是表里的一行；加运算符 = 加/改一格，函数一个不动。
static Rule makeRule(PrefixFn p, InfixFn i, Prec prec, bool right = false) {
    return Rule{p, i, prec, right};
}

const Rule &PrattParser::rule(Tok t) const {
    // 匠书把表写成 Parser 类里的 static 数组；C++ 成员函数指针表这里用
    // 进程级单例 map（线程安全局部 static，本教程单线程）。
    struct Tables {
        std::map<Tok, Rule> map;
        Tables() {
            auto P = &PrattParser::number, V = &PrattParser::variable;
            auto G = &PrattParser::grouping, U = &PrattParser::unaryExpr;
            auto B = &PrattParser::binary, C = &PrattParser::callExpr, F = &PrattParser::fieldExpr;
            map[Tok::Int]    = makeRule(P, nullptr, Prec::None);
            map[Tok::Ident]  = makeRule(V, nullptr, Prec::None);
            map[Tok::LParen] = makeRule(G, C, Prec::Call);   // 前缀=分组，中缀=调用
            map[Tok::Minus]  = makeRule(U, B, Prec::Term);   // 前缀=负号，中缀=减
            map[Tok::Star]   = makeRule(U, B, Prec::Factor); // 前缀=解引用，中缀=乘
            map[Tok::Amp]    = makeRule(U, nullptr, Prec::None);
            map[Tok::Plus]   = makeRule(nullptr, B, Prec::Term);
            map[Tok::Slash]  = makeRule(nullptr, B, Prec::Factor);
            map[Tok::Caret]  = makeRule(nullptr, B, Prec::Power, /*right=*/true);
            map[Tok::Eq]     = makeRule(nullptr, B, Prec::Equality);
            map[Tok::Ne]     = makeRule(nullptr, B, Prec::Equality);
            map[Tok::Lt]     = makeRule(nullptr, B, Prec::Comparison);
            map[Tok::Le]     = makeRule(nullptr, B, Prec::Comparison);
            map[Tok::Gt]     = makeRule(nullptr, B, Prec::Comparison);
            map[Tok::Ge]     = makeRule(nullptr, B, Prec::Comparison);
            map[Tok::Dot]    = makeRule(nullptr, F, Prec::Call);
        }
    };
    static const Tables tbl;
    static const Rule kNone{};  // 不在表里的 token（) , EOF）无前缀无中缀
    auto it = tbl.map.find(t);
    return it != tbl.map.end() ? it->second : kNone;
}

void PrattParser::setRightAssoc(Tok t) {
    Rule r = lookup(t);  // 拷贝一份进实例覆盖表——结合性实验只动这个实例
    r.rightAssoc = true;
    override_.insert_or_assign(t, r);
}

Token PrattParser::advance() {
    if (toks_[pos_].t != Tok::Eof) ++pos_;
    return toks_[pos_ - 1];
}

bool PrattParser::match(Tok t) {
    if (peek().t != t) return false;
    advance();
    return true;
}

Token PrattParser::expect(Tok t, const std::string &msg) {
    if (peek().t == t) return advance();
    errs_.push_back({msg + "，但看到 '" + peek().text + "'", peek().line});
    return peek();
}

ExprP PrattParser::parseExpression(Prec minPrec) {
    const Rule &start = rule(peek().t);
    if (start.prefix == nullptr) {
        errs_.push_back({"期望表达式，但看到 '" + peek().text + "'", peek().line});
        return nullptr;
    }
    ExprP lhs = (this->*start.prefix)();
    if (!lhs) return nullptr;
    while (true) {
        const Rule &r = lookup(peek().t);  // 先看实例覆盖（结合性实验），再查全局表
        if (r.infix == nullptr || static_cast<int>(r.prec) < static_cast<int>(minPrec)) break;
        lhs = (this->*r.infix)(std::move(lhs));
        if (!lhs) return nullptr;
    }
    return lhs;
}

const Rule &PrattParser::lookup(Tok t) const {
    if (auto it = override_.find(t); it != override_.end()) return it->second;
    return rule(t);
}

ExprP PrattParser::number() {
    Token t = advance();
    return std::make_unique<IntLit>(t.num);
}

ExprP PrattParser::variable() {
    Token t = advance();
    return std::make_unique<VarRef>(t.text);
}

ExprP PrattParser::grouping() {
    advance();  // 吃掉 (
    ExprP inner = parseExpression(Prec::None);  // 分组回到最低优先级：括号内是完整表达式
    expect(Tok::RParen, "期望 ')'");
    return inner;
}

ExprP PrattParser::unaryExpr() {
    Token op = advance();                       // - * & 三种前缀
    ExprP sub = parseExpression(Prec::Unary);   // 操作数允许更高优先级的前缀链：- - x、* * p
    if (!sub) return nullptr;
    return std::make_unique<Unary>(op.t, std::move(sub));
}

ExprP PrattParser::binary(ExprP lhs) {
    Token op = advance();
    // 结合性在此一行分岔（第 6 章把它焊死在函数调用图里）：
    //   左结合：右操作数用"高一级"minPrec —— 同级运算符回到外层循环，左边先结合；
    //   右结合：右操作数用"同级"minPrec —— 递归先吃掉右边的同级运算符。
    const Rule &r = lookup(op.t);
    Prec rhsMin = r.rightAssoc ? r.prec : up(r.prec);
    ExprP rhs = parseExpression(rhsMin);
    if (!rhs) return nullptr;
    return std::make_unique<Binop>(op.t, std::move(lhs), std::move(rhs));
}

ExprP PrattParser::callExpr(ExprP callee) {
    advance();  // 吃掉 (
    std::vector<ExprP> args;
    if (peek().t != Tok::RParen) {
        args.push_back(parseExpression(Prec::None));
        while (match(Tok::Comma)) args.push_back(parseExpression(Prec::None));
        for (const auto &a : args) if (!a) return nullptr;
    }
    expect(Tok::RParen, "期望 ')'");
    return std::make_unique<CallE>(std::move(callee), std::move(args));
}

ExprP PrattParser::fieldExpr(ExprP rec) {
    advance();  // 吃掉 .
    if (peek().t != Tok::Ident) {
        errs_.push_back({"期望字段名", peek().line});
        return nullptr;
    }
    Token f = advance();
    return std::make_unique<FieldA>(std::move(rec), f.text);
}

ExprP parsePratt(const std::string &src, std::vector<ParseError> &errs) {
    std::vector<Token> toks = lex(src, errs);
    PrattParser p(std::move(toks));
    ExprP e = p.parseExpression(Prec::None);
    if (p.hadError()) {
        errs.insert(errs.end(), p.errors().begin(), p.errors().end());
        return nullptr;
    }
    return e;
}

// ---------- 求值 ----------
long long evalExpr(const Expr &e,
                   const std::map<std::string, long long> &env,
                   const std::map<std::string, BuiltinFn> &builtins,
                   std::string *err) {
    auto fail = [&](const std::string &m) {
        if (err) *err = m;
        return 0;
    };
    if (auto *n = dynamic_cast<const IntLit *>(&e)) return n->v;
    if (auto *n = dynamic_cast<const VarRef *>(&e)) {
        auto it = env.find(n->name);
        if (it == env.end()) return fail("未定义变量 " + n->name);
        return it->second;
    }
    if (auto *n = dynamic_cast<const Unary *>(&e)) {
        long long v = evalExpr(*n->sub, env, builtins, err);
        if (err && !err->empty()) return 0;
        if (n->op == Tok::Minus) return -v;
        return fail("解引用/取址只在形状语料出现，不求值");
    }
    if (auto *n = dynamic_cast<const Binop *>(&e)) {
        long long a = evalExpr(*n->l, env, builtins, err);
        if (err && !err->empty()) return 0;
        long long b = evalExpr(*n->r, env, builtins, err);
        if (err && !err->empty()) return 0;
        switch (n->op) {
            case Tok::Plus: return a + b;
            case Tok::Minus: return a - b;
            case Tok::Star: return a * b;
            case Tok::Slash:
                if (b == 0) return fail("除零");
                return a / b;
            case Tok::Caret: {  // 幂（教学扩展）：小指数整数幂
                long long r = 1;
                if (b < 0) return fail("负指数");
                for (long long k = 0; k < b; ++k) r *= a;
                return r;
            }
            case Tok::Lt: return a < b;
            case Tok::Le: return a <= b;
            case Tok::Gt: return a > b;
            case Tok::Ge: return a >= b;
            case Tok::Eq: return a == b;
            default: return a != b;
        }
    }
    if (auto *n = dynamic_cast<const CallE *>(&e)) {
        auto *f = dynamic_cast<const VarRef *>(n->callee.get());
        if (!f) return fail("被调者必须是标识符（语料口径）");
        auto it = builtins.find(f->name);
        if (it == builtins.end()) return fail("未定义函数 " + f->name);
        std::vector<long long> args;
        for (const auto &a : n->args) {
            long long v = evalExpr(*a, env, builtins, err);
            if (err && !err->empty()) return 0;
            args.push_back(v);
        }
        return it->second(std::move(args));
    }
    return fail("字段访问只在形状语料出现，不求值");
}

}  // namespace tip
