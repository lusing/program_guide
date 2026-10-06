// file: src/tiny.hpp
// TINY 语言的 AST（L 书 §1.7.2 的文法、§8.8.2 的树构型——StmtK/ExpK 双族）。
#ifndef TIP_TINY_HPP
#define TIP_TINY_HPP

#include <memory>
#include <string>
#include <vector>

namespace tiny {

enum class Tok {
    If, Then, Else, End, Repeat, Until, Read, Write,   // 关键字 8 个
    Assign,        // :=
    Eq,            // =
    Lt,            // <
    Add, Sub, Mul, Div,
    LParen, RParen, Semi,
    Num, Id,
    EndOfFile,
};

// ---------- 表达式（ExpK） ----------
struct Exp {
    enum class Kind { Op, Const, Id } kind;
    Tok op = Tok::Add;        // Kind::Op 时有效（Add/Sub/Mul/Div/Lt/Eq）
    long long val = 0;        // Kind::Const
    std::string name;         // Kind::Id
    std::unique_ptr<Exp> lhs, rhs;   // Kind::Op 的两个孩子
};

// ---------- 语句（StmtK） ----------
struct Stmt {
    enum class Kind { If, Repeat, Assign, Read, Write } kind;
    // If: cond + thenSeq + elseSeq；Repeat: body + cond（直到型）；
    // Assign: name + exp；Read: name；Write: exp。
    std::unique_ptr<Exp> cond, exp;
    std::string name;
    std::vector<std::unique_ptr<Stmt>> thenSeq, elseSeq, body;
    int line = 0;
};

struct Program {
    std::vector<std::unique_ptr<Stmt>> stmts;
};

// 语法错误（带行号——第 10 章黄金句式）。
struct ParseError {
    std::string msg;
    int line;
};

}  // namespace tiny

#endif  // TIP_TINY_HPP
