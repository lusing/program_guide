#pragma once
// 36 表达式求值器实战：解释器（文法即类）+ 组合（树即对象结构）+
// variant 节点 + 备忘录（Var 结果缓存）。词法 -> 递归下降 -> AST -> 求值。
#include <expected>
#include <map>
#include <memory>
#include <span>
#include <string>
#include <string_view>
#include <utility>
#include <variant>
#include <vector>

namespace dp {

// ---- 文法四类：数字、变量、加、乘（递归：Add/Mul 持两棵子树）----
struct Num { double v; };
struct Var { std::string name; };

struct Ast;
struct Add { std::unique_ptr<Ast> l, r; };
struct Mul { std::unique_ptr<Ast> l, r; };

struct Ast {
    std::variant<Num, Var, Add, Mul> node;   // unique_ptr<未完整 Ast>：variant 拆环的标准手法
};

// ---- 词法：把 src 切成 token（数字/标识符/符号）----
struct Tok {
    enum class Kind { num, ident, plus, star, lparen, rparen, end } kind;
    std::string text;
    double num = 0.0;
};

inline std::expected<std::vector<Tok>, std::string> lex(std::string_view src) {
    std::vector<Tok> toks;
    std::size_t i = 0;
    while (i < src.size()) {
        const char c = src[i];
        if (c == ' ' || c == '\t' || c == '\n') { ++i; continue; }   // 空白容忍
        if (c == '+') { toks.push_back({Tok::Kind::plus, "+"}); ++i; continue; }
        if (c == '*') { toks.push_back({Tok::Kind::star, "*"}); ++i; continue; }
        if (c == '(') { toks.push_back({Tok::Kind::lparen, "("}); ++i; continue; }
        if (c == ')') { toks.push_back({Tok::Kind::rparen, ")"}); ++i; continue; }
        if (c >= '0' && c <= '9') {                                  // 数字（含小数）
            std::size_t j = i;
            while (j < src.size() && ((src[j] >= '0' && src[j] <= '9') || src[j] == '.'))
                ++j;
            std::string t{src.substr(i, j - i)};
            toks.push_back({Tok::Kind::num, t, std::stod(t)});
            i = j;
            continue;
        }
        if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_') {  // 标识符
            std::size_t j = i;
            while (j < src.size() && ((src[j] >= 'a' && src[j] <= 'z') ||
                                      (src[j] >= 'A' && src[j] <= 'Z') ||
                                      (src[j] >= '0' && src[j] <= '9') || src[j] == '_'))
                ++j;
            toks.push_back({Tok::Kind::ident, std::string{src.substr(i, j - i)}});
            i = j;
            continue;
        }
        return std::unexpected("bad char at " + std::to_string(i));
    }
    toks.push_back({Tok::Kind::end, ""});
    return toks;
}

// ---- 递归下降：expr := term ('+' term)*; term := factor ('*' factor)*;
//       factor := num | ident | '(' expr ')' ----
struct Parser {
    const std::vector<Tok>& toks;
    std::size_t pos = 0;

    const Tok& peek() const { return toks[pos]; }
    void eat() { if (peek().kind != Tok::Kind::end) ++pos; }

    std::expected<std::unique_ptr<Ast>, std::string> parse_expr() {
        auto lhs = parse_term();
        if (!lhs) return lhs;
        while (peek().kind == Tok::Kind::plus) {
            eat();
            auto rhs = parse_term();
            if (!rhs) return rhs;
            lhs = std::make_unique<Ast>(Ast{Add{std::move(*lhs), std::move(*rhs)}});
        }
        return lhs;
    }

    std::expected<std::unique_ptr<Ast>, std::string> parse_term() {
        auto lhs = parse_factor();
        if (!lhs) return lhs;
        while (peek().kind == Tok::Kind::star) {
            eat();
            auto rhs = parse_factor();
            if (!rhs) return rhs;
            lhs = std::make_unique<Ast>(Ast{Mul{std::move(*lhs), std::move(*rhs)}});
        }
        return lhs;
    }

    std::expected<std::unique_ptr<Ast>, std::string> parse_factor() {
        if (peek().kind == Tok::Kind::num) {
            double v = peek().num;
            eat();
            return std::make_unique<Ast>(Ast{Num{v}});
        }
        if (peek().kind == Tok::Kind::ident) {
            std::string n = peek().text;
            eat();
            return std::make_unique<Ast>(Ast{Var{n}});
        }
        if (peek().kind == Tok::Kind::lparen) {
            eat();
            auto inner = parse_expr();
            if (!inner) return inner;
            if (peek().kind != Tok::Kind::rparen)
                return std::unexpected("expected ')'");
            eat();
            return inner;
        }
        return std::unexpected("unexpected token '" + peek().text + "'");
    }
};

inline std::expected<Ast, std::string> parse(std::string_view src) {
    auto toks = lex(src);
    if (!toks) return std::unexpected(toks.error());
    Parser p{*toks};
    auto ast = p.parse_expr();
    if (!ast) return std::unexpected(ast.error());
    if (p.peek().kind != Tok::Kind::end)
        return std::unexpected("trailing input at '" + p.peek().text + "'");
    return std::move(**ast);   // unique_ptr<Ast> -> Ast（子树所有权随移动走）
}

// ---- 求值：环境是 (名字, 值) 列表；未定义变量是求值期错误 ----
using Env = std::span<const std::pair<std::string, double>>;

inline std::expected<double, std::string> eval(const Ast& a, Env env) {
    return std::visit([&](const auto& n) -> std::expected<double, std::string> {
        using T = std::decay_t<decltype(n)>;
        if constexpr (std::is_same_v<T, Num>) {
            return n.v;
        } else if constexpr (std::is_same_v<T, Var>) {
            for (const auto& [k, v] : env)
                if (k == n.name) return v;
            return std::unexpected("undefined variable: " + n.name);
        } else {   // Add / Mul：先算左子树，成功再算右子树
            auto l = eval(*n.l, env);
            if (!l) return l;
            auto r = eval(*n.r, env);
            if (!r) return r;
            if constexpr (std::is_same_v<T, Add>) return *l + *r;
            else return *l * *r;
        }
    }, a.node);
}

// ---- 备忘录版：Var 的值按名字缓存，重复出现的变量只查一次环境 ----
struct Memo {
    std::map<std::string, double> var_vals;
    int hits = 0;   // 命中计数：同一 Var 第二次出现走缓存
};

inline std::expected<double, std::string> eval_cached(const Ast& a, Env env, Memo& memo) {
    return std::visit([&](const auto& n) -> std::expected<double, std::string> {
        using T = std::decay_t<decltype(n)>;
        if constexpr (std::is_same_v<T, Num>) {
            return n.v;
        } else if constexpr (std::is_same_v<T, Var>) {
            if (auto it = memo.var_vals.find(n.name); it != memo.var_vals.end()) {
                ++memo.hits;
                return it->second;
            }
            for (const auto& [k, v] : env) {
                if (k == n.name) {
                    memo.var_vals.emplace(n.name, v);
                    return v;
                }
            }
            return std::unexpected("undefined variable: " + n.name);
        } else {
            auto l = eval_cached(*n.l, env, memo);
            if (!l) return l;
            auto r = eval_cached(*n.r, env, memo);
            if (!r) return r;
            if constexpr (std::is_same_v<T, Add>) return *l + *r;
            else return *l * *r;
        }
    }, a.node);
}

}  // namespace dp
