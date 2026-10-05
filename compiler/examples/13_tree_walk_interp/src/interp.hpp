// file: src/interp.hpp
// 第 13 章：树遍历解释器与环境链（匠书 §7–§10 精要 + §11 静态检查蒸馏）。
// 两层结构：SemCheck 求值前的静态检查（未声明/重复声明/确定赋值/直接调用
// 元数）+ Interpreter 环境链求值（闭包 = 函数身体 + 定义时环境指针）。
#ifndef TIP_INTERP_HPP
#define TIP_INTERP_HPP

#include <functional>
#include <iostream>
#include <map>
#include <memory>
#include <set>
#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

struct Environment;
struct Closure;

// ---------- 值：本章宇宙只有整数与闭包（指针/记录不求值，正文说明） ----------
struct Value {
    enum class Tag { Int, Closure } tag = Tag::Int;
    long long i = 0;
    std::shared_ptr<Closure> clo;

    static Value num(long long v) { Value x; x.tag = Tag::Int; x.i = v; return x; }
    static Value fun(std::shared_ptr<Closure> c) {
        Value x; x.tag = Tag::Closure; x.clo = std::move(c); return x;
    }
};

// 闭包：身体（FunDecl=顶层函数 或 FunLit=字面量）+ 定义时环境。
// 捕获即共享——两个闭包指向同一 Environment 时，经链的写会互相可见。
struct Closure {
    const FunDecl *decl = nullptr;  // 顶层函数（环境=全局）
    const FunLit *lit = nullptr;    // 函数字面量（环境=定义处）
    std::shared_ptr<Environment> env;

    int paramCount() const { return decl ? int(decl->params.size()) : int(lit->params.size()); }
};

// 环境：一个作用域一个节点。取值沿链查、赋值沿链写回（找定义处）。
struct Environment : std::enable_shared_from_this<Environment> {
    std::map<std::string, Value> values;
    std::shared_ptr<Environment> enclosing;

    explicit Environment(std::shared_ptr<Environment> parent) : enclosing(std::move(parent)) {}

    void define(const std::string &name, Value v) { values[name] = std::move(v); }
    Value *find(const std::string &name);  // 沿链；未命中返回 nullptr
};

// ---------- 诊断与运行时错误 ----------
struct Diag {
    std::string msg;
    int line = 0;
};

struct InterpError {
    std::string msg;
    int line = 0;
};

// ---------- 静态检查（求值前，§11 精要） ----------
// 1) 未声明使用 / 同层重复声明（作用域化栈式遍历，jlox Resolver 同型）
// 2) 确定赋值（definite assignment）：每个局部变量在每次使用前必已赋值
//    —— 匠书 "var a = a" 初始化窗口在 TIP 的对应物（TIP 声明与赋值
//    分离，窗口一般化为"声明到首次赋值之间的任何读取"）
// 3) 直接调用的元数（被调是全局函数名时静态可查；闭包调用留运行时兜底）
class SemCheck {
  public:
    std::vector<Diag> run(ProgramA &prog);

  private:
    void declare(const std::string &name, int line);   // 当前层登记，撞名即诊断
    int resolve(const std::string &name);              // 返回层数（0=全局函数），-1 未命中
    void checkStmt(const Stmt &s, std::set<std::string> &assigned);
    void checkExpr(const Expr &e, std::set<std::string> &assigned);
    void collectCapturedExpr(const Expr &e, int myDepth);
    void collectCapturedStmt(const Stmt &s, int myDepth);
    void checkFunBody(const std::vector<std::string> &params,
                      const std::vector<std::string> &vars, const Stmt &body,
                      const Expr &ret, int line);

    std::vector<Diag> diags_;
    std::vector<std::set<std::string>> scopes_;  // 作用域栈（字符串集合即可：
                                                 // 层内只问"在不在"，深度即索引）
    std::map<std::string, const FunDecl *> funs_;  // 全局函数表
    std::set<std::string> captured_;  // 被内嵌 FunLit 捕获的外层名字（豁免确定赋值）
};

// ---------- 解释器（环境链求值） ----------
class Interpreter {
  public:
    explicit Interpreter(ProgramA &prog);

    // 跑入口函数；output 语句写到 out。返回函数返回值。
    Value run(const std::string &entry, std::vector<Value> args, std::ostream &out);

    int envCreated() const { return envCreated_; }

  private:
    Value eval(const Expr &e, Environment &env);
    void exec(const Stmt &s, Environment &env);
    Value callClosure(const Closure &c, std::vector<Value> args, int line);
    std::shared_ptr<Environment> newEnv(std::shared_ptr<Environment> parent);

    ProgramA &prog_;
    std::shared_ptr<Environment> globals_;
    std::ostream *out_ = &std::cout;  // output 语句的去处（run 时切换）
    int envCreated_ = 0;
};

}  // namespace tip

#endif  // TIP_INTERP_HPP
