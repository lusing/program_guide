// file: src/compiler.hpp
// 第 55 章：单遍编译器——扫描、语法、发码一次完成，无 AST
//（匠书 §16–§17、§21–§23）。Pratt 表来自第 9 章，回调从
// "合成 AST 节点"换成"发一条字节码"——表一行不用改。
#ifndef TIP_COMPILER_HPP
#define TIP_COMPILER_HPP

#include <memory>
#include <string>
#include <vector>

#include "chunk.hpp"
#include "scanner.hpp"

namespace tip {

struct CompileError {
    std::string msg;
    int line = 0;
};

// 编译产物：函数表（名字 → ObjFn），供驱动注册进 VM 全局表。
struct Program {
    std::vector<std::shared_ptr<ObjFn>> fns;
};

class Compiler {
  public:
    // 编译整个源文件（函数序列）。出错抛 CompileError（单遍口径：
    // 第一处错误即终止——没有后续遍历可依赖，恢复无从谈起）。
    Program compile(const std::string &src);

    // 断言用：各函数的槽位峰值（§22 编译期账）
    int lastSlotPeak() const { return lastSlotPeak_; }

  private:
    // Pratt 规则表（私有静态：表要取本类成员指针）
    struct CRule;
    static CRule ruleFor(Tok t);

    // —— 词法层（即取即用三函数 + 一个前看缓冲）——
    Token advance();
    bool check(Tok t) const;
    bool match(Tok t);
    Token consume(Tok t, const char *msg);

    // —— 声明与作用域（§22）——
    struct Local {
        std::string name;
        int depth;
    };
    void beginScope();
    void endScope();          // 弹出本层局部并按数发 POP（槽位回收）
    int resolveLocal(const std::string &name) const;  // -1 = 不在本函数
    void declareLocal(const std::string &name, int line);

    // —— 语句层（递归下降骨架）——
    void function();          // IDENT ( params ) { varDecls? stmt* return expr ; }
    void statement();
    void blockStmt();
    void varStmt();           // 块级 var（教学扩展，jlox 同款）
    void exprStmt();          // 赋值语句：lvalue = expr ;（lvalue 仅 IDENT）
    void ifStmt();            // §23.3：双跳转模板 + 回填
    void whileStmt();         // §23.5：Loop 回边
    void outputStmt();
    void returnStmt();

    // —— 表达式层（Pratt，§17.5）——
    void expression();        // parseExpression(Prec::None) 的入口
    void parsePrecedence(int minPrec);
    // 前缀回调
    void numberFn();
    void identFn();           // 局部 → GET_LOCAL；否则 GET_GLOBAL（迟绑定）
    void groupingFn();
    void unaryFn();
    // 中缀回调
    void binaryFn();          // 双目：左右已发，此处发运算符
    void andFn();             // 短路（C 风格布尔化）
    void orFn();
    void callFn();            // 被调者已发；发实参 + CALL

    // —— 发码与回填（§23.1）——
    void emit(Op op);
    void emitByte(uint8_t b);
    void emitConstant(const Value &v);
    int emitJump(Op op);          // 占位 0xFFFF，返回 Patch 位置
    void patchJump(int at);       // 前向跳转目标此刻才存在——回填
    void emitLoop(int loopStart); // 向后跳：目标已知，直接写

    int line() const { return prev_.line; }  // 行号随"上一 token"走

    Scanner sc_;
    Token prev_{};   // 刚消费的 token（发码行号的来源）
    Token cur_{};    // 前看一个（即取即用的最小缓冲）
    std::vector<Local> locals_;
    int scopeDepth_ = 0;
    std::shared_ptr<ObjFn> fn_;   // 正在编译的函数
    Program prog_;
    int lastSlotPeak_ = 0;
};

}  // namespace tip

#endif  // TIP_COMPILER_HPP
