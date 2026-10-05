// file: src/pratt.hpp
// 第 11 章：Pratt 分析——运算符优先级爬升（precedence climbing）。
// 词法共享（llref 也用它）；AST 与第 14 章 TIP 表达式节点同名同形；
// 解析策略是本章唯一变量，求值器两法共用，输出必须一致。
#ifndef TIP_PRATT_HPP
#define TIP_PRATT_HPP

#include <functional>
#include <map>
#include <memory>
#include <string>
#include <vector>

namespace tip {

// ---------- 词法 ----------
enum class Tok {
    Int, Ident, Plus, Minus, Star, Slash, Caret,  // Caret（^）是教学扩展：TIP 无幂
    LParen, RParen, Lt, Le, Gt, Ge, Eq, Ne, Amp, Dot, Comma, Eof,
};

struct Token {
    Tok t;
    std::string text;   // 原文（标识符/多字符运算符）
    long long num = 0;  // Int 时有效
    int line = 1;
};

struct ParseError {
    std::string msg;
    int line;
};

// 共享词法器：跳过空白，识别多字符运算符（<= >= == !=）。
std::vector<Token> lex(const std::string &src, std::vector<ParseError> &errs);

// ---------- AST（形状与第 14 章一致，便于读者前后对照） ----------
struct Expr;
using ExprP = std::unique_ptr<Expr>;

struct Expr {
    virtual ~Expr() = default;
};
struct IntLit : Expr { long long v = 0; explicit IntLit(long long x) : v(x) {} };
struct VarRef : Expr { std::string name; explicit VarRef(std::string n) : name(std::move(n)) {} };
// 一元三种：负号 -、解引用 *、取址 &（op 记 Tok）
struct Unary : Expr {
    Tok op;
    ExprP sub;
    Unary(Tok o, ExprP s) : op(o), sub(std::move(s)) {}
};
struct Binop : Expr {
    Tok op;
    ExprP l, r;
    Binop(Tok o, ExprP a, ExprP b) : op(o), l(std::move(a)), r(std::move(b)) {}
};
struct CallE : Expr {  // 被调表达式本身是任意表达式（TIP 一等函数）
    ExprP callee;
    std::vector<ExprP> args;
    CallE(ExprP c, std::vector<ExprP> a) : callee(std::move(c)), args(std::move(a)) {}
};
struct FieldA : Expr {  // 记录字段访问
    ExprP rec;
    std::string field;
    FieldA(ExprP r, std::string f) : rec(std::move(r)), field(std::move(f)) {}
};

// 括号化形状打印：(- 2 3) 式 S-表达式，嵌套一目了然。
std::string showAst(const Expr &e);

// ---------- Pratt 规则表（匠书 §17.5 的 Rule/getRule） ----------
enum class Prec {
    None = 0,    // 最低：完整表达式
    Equality,    // == !=
    Comparison,  // < <= > >=
    Term,        // + -
    Factor,      // * /
    Power,       // ^（教学扩展，右结合）
    Unary,       // 一元 -、*、&（前缀）
    Call,        // 调用 ( 与字段 .（后缀，最高）
};

// 一条规则 = 前缀回调 + 中缀回调 + 优先级 + 结合性（匠书表加一列）。
// 前缀回调：此 token 出现在"操作数位"时怎么起步；
// 中缀回调：此 token 出现在"运算符位"时左操作数已在手。
struct PrattParser;
using PrefixFn = ExprP (PrattParser::*)();
using InfixFn = ExprP (PrattParser::*)(ExprP);

struct Rule {
    PrefixFn prefix = nullptr;
    InfixFn infix = nullptr;
    Prec prec = Prec::None;
    bool rightAssoc = false;  // 右结合：递归用同级而不是高一级（见 §09.2）
};

class PrattParser {
  public:
    explicit PrattParser(std::vector<Token> toks);

    // 匠书 parsePrecedence：先吃一个前缀，再按表滚中缀循环，
    // 直到撞见优先级低于 minPrec 的运算符（或无中缀）。
    ExprP parseExpression(Prec minPrec);

    const Rule &rule(Tok t) const;         // 匠书 getRule
    void setRightAssoc(Tok t);             // 结合性实验：把某运算符改成右结合
    bool hadError() const { return !errs_.empty(); }
    const std::vector<ParseError> &errors() const { return errs_; }

  private:
    // 前缀回调
    ExprP number();      // IntLit
    ExprP variable();   // VarRef
    ExprP grouping();   // ( expr )
    ExprP unaryExpr();  // - * & 前缀
    // 中缀回调
    ExprP binary(ExprP lhs);   // 双目
    ExprP callExpr(ExprP callee);  // callee ( args )
    ExprP fieldExpr(ExprP rec);    // rec . field

    const Rule &lookup(Tok t) const;  // 先查实例覆盖（结合性实验），再查全局表

    const Token &peek() const { return toks_[pos_]; }
    Token advance();
    bool match(Tok t);
    Token expect(Tok t, const std::string &msg);

    std::vector<Token> toks_;
    size_t pos_ = 0;
    std::vector<ParseError> errs_;
    std::map<Tok, Rule> override_;  // 结合性实验的实例级改写
};

// 高一级优先级（左结合的右操作数下限）。
Prec up(Prec p);

// 一步到位：词法 + 语法。失败时返回 nullptr 并写 errs。
ExprP parsePratt(const std::string &src, std::vector<ParseError> &errs);

// ---------- 共享求值器 ----------
// env：变量值；builtins：内建函数（abs/max）。求值与解析策略无关，
// 两个解析器产出同一形状的 AST，在这里必须算出同一个数。
using BuiltinFn = std::function<long long(std::vector<long long>)>;
long long evalExpr(const Expr &e,
                   const std::map<std::string, long long> &env,
                   const std::map<std::string, BuiltinFn> &builtins,
                   std::string *err = nullptr);

}  // namespace tip

#endif  // TIP_PRATT_HPP
