// file: src/lang.hpp
// 第 22 章配套：参数传递教学语言的 AST（L 书 §7.5 的实验台）。
// 语言面：函数 + 四种形参机制注记（val/ref/valres/name）+ 标量与一维数组 +
// 赋值/print/if/while/for/return——刚好够演出四种机制的全部语义差异。
#ifndef TIP_PLANG_HPP
#define TIP_PLANG_HPP

#include <memory>
#include <string>
#include <vector>

namespace plang {

// ---------- 表达式 ----------
struct Expr {
    enum class Kind { Num, Var, Index, Bin, Unary, Call };
    Kind kind;
    double num = 0;                      // Num
    std::string name;                    // Var / Call 的函数名
    std::unique_ptr<Expr> lhs, rhs;      // Bin；Unary 用 lhs；Index 的下标用 lhs
    std::string op;                      // "+", "-", "*", "/", "<", "<=", ">", ">=", "==", "!=", "u-"
    std::vector<std::unique_ptr<Expr>> args;   // Call 的实参表达式
};

// ---------- 语句 ----------
struct Stmt {
    enum class Kind { VarDecl, ArrayDecl, Assign, Print, If, While, For, Return, CallStmt };
    Kind kind;
    std::string name;                    // 声明/赋值目标；CallStmt 的函数名
    std::unique_ptr<Expr> index;         // 数组元素赋值的下标
    std::unique_ptr<Expr> value, cond, from, to;   // 赋值值 / 条件 / for 边界
    std::vector<std::unique_ptr<Stmt>> then, other, body;   // 分支与循环体
    std::vector<std::unique_ptr<Expr>> args;   // CallStmt 的实参表达式
};

// ---------- 函数与形参 ----------
enum class PassMode { Val, Ref, ValRes, Name };

struct Param {
    std::string name;
    PassMode mode;
};

struct Fun {
    std::string name;
    std::vector<Param> params;
    std::vector<std::unique_ptr<Stmt>> body;
};

struct Program {
    std::vector<std::unique_ptr<Fun>> funs;
};

const char *modeName(PassMode m);

}  // namespace plang

#endif  // TIP_PLANG_HPP
