// file: src/llref.cpp
#include "llref.hpp"

namespace tip {

LlParser::LlParser(std::vector<Token> toks) : toks_(std::move(toks)) {}

Token LlParser::advance() {
    if (toks_[pos_].t != Tok::Eof) ++pos_;
    return toks_[pos_ - 1];
}

bool LlParser::match(Tok t) {
    if (peek().t != t) return false;
    advance();
    return true;
}

Token LlParser::expect(Tok t, const std::string &msg) {
    if (peek().t == t) return advance();
    errs_.push_back({msg + "，但看到 '" + peek().text + "'", peek().line});
    return peek();
}

ExprP LlParser::parse() { return cmp(); }

// 每层一个函数：层的先后就是优先级，函数体里的 while 循环就是左结合，
// unary 里递归 unary 才容得下 --x——结合性全部焊死在调用图里（§09.1 的痛）。
ExprP LlParser::cmp() {
    ExprP lhs = add();
    return lhs ? cmpRest(std::move(lhs)) : nullptr;
}

ExprP LlParser::cmpRest(ExprP lhs) {
    Tok t = peek().t;
    if (t == Tok::Lt || t == Tok::Le || t == Tok::Gt || t == Tok::Ge ||
        t == Tok::Eq || t == Tok::Ne) {
        Token op = advance();
        ExprP rhs = add();
        if (!rhs) return nullptr;
        return cmpRest(std::make_unique<Binop>(op.t, std::move(lhs), std::move(rhs)));
    }
    return lhs;  // ε
}

ExprP LlParser::add() {
    ExprP lhs = mul();
    return lhs ? addRest(std::move(lhs)) : nullptr;
}

ExprP LlParser::addRest(ExprP lhs) {
    Tok t = peek().t;
    if (t == Tok::Plus || t == Tok::Minus) {
        Token op = advance();
        ExprP rhs = mul();
        if (!rhs) return nullptr;
        return addRest(std::make_unique<Binop>(op.t, std::move(lhs), std::move(rhs)));
    }
    return lhs;
}

ExprP LlParser::mul() {
    ExprP lhs = unary();
    return lhs ? mulRest(std::move(lhs)) : nullptr;
}

ExprP LlParser::mulRest(ExprP lhs) {
    Tok t = peek().t;
    if (t == Tok::Star || t == Tok::Slash) {
        Token op = advance();
        ExprP rhs = unary();
        if (!rhs) return nullptr;
        return mulRest(std::make_unique<Binop>(op.t, std::move(lhs), std::move(rhs)));
    }
    return lhs;
}

ExprP LlParser::unary() {
    if (match(Tok::Minus)) {
        ExprP sub = unary();  // 一元负号递归自身：允许 --x
        return sub ? std::make_unique<Unary>(Tok::Minus, std::move(sub)) : nullptr;
    }
    return primary();
}

ExprP LlParser::primary() {
    if (peek().t == Tok::Int) {
        Token t = advance();
        return std::make_unique<IntLit>(t.num);
    }
    if (peek().t == Tok::Ident) {
        Token t = advance();
        return std::make_unique<VarRef>(t.text);
    }
    if (match(Tok::LParen)) {
        ExprP inner = cmp();
        if (!inner) return nullptr;
        expect(Tok::RParen, "期望 ')'");
        return inner;
    }
    errs_.push_back({"期望表达式，但看到 '" + peek().text + "'", peek().line});
    return nullptr;
}

ExprP parseLl(const std::string &src, std::vector<ParseError> &errs) {
    std::vector<Token> toks = lex(src, errs);
    LlParser p(std::move(toks));
    ExprP e = p.parse();
    if (p.hadError()) {
        errs.insert(errs.end(), p.errors().begin(), p.errors().end());
        return nullptr;
    }
    return e;
}

}  // namespace tip
