// file: src/compiler.hpp
// 第 57 章：单遍编译器 + 函数字面量与上值（匠书 §25.1–25.5）。
// 相对第 55 章的改造：单函数状态升级为 **FnCtx 链**（嵌套函数各有
// 上下文、经 parent 链解析上值）；Local 加 isCaptured；出块对被捕获
// 槽位先发 CLOSE_UPVALUE 再 POP；新增 fun 前缀回调发 CLOSURE。
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

struct Program {
    std::vector<std::shared_ptr<ObjFn>> fns;  // 顶层函数（驱动注册用）
};

class Compiler {
  public:
    Program compile(const std::string &src);
    int lastSlotPeak() const { return lastSlotPeak_; }

  private:
    // —— 函数上下文链：嵌套函数各一层，parent 指向外层（§25.2）——
    struct Local {
        std::string name;
        int depth;
        bool isCaptured = false;  // 被内嵌函数捕获 → 出块前要 CLOSE
    };
    struct FnCtx {
        std::shared_ptr<ObjFn> fn;     // 编译产物
        std::vector<Local> locals;     // 槽位表（下标即槽号）
        int scopeDepth = 0;
        FnCtx *parent = nullptr;       // 词法外层（上值解析的路）
        bool named = true;             // 顶层函数 or 字面量
    };

    // Pratt 表（私有静态）
    struct CRule;
    static CRule ruleFor(Tok t);

    Token advance();
    bool check(Tok t) const;
    bool match(Tok t);
    Token consume(Tok t, const char *msg);

    void beginScope();
    void endScope();
    int resolveLocal(FnCtx *ctx, const std::string &name) const;
    int resolveUpvalue(FnCtx *ctx, const std::string &name);  // 递归穿层
    int addUpvalue(FnCtx *ctx, bool isLocal, uint8_t index);  // 去重
    void declareLocal(const std::string &name, int line);

    void function(bool named);   // 顶层函数与 fun 字面量共用（§25.1）
    void statement();
    void blockStmt();
    void varStmt();
    void exprStmt();
    void ifStmt();
    void whileStmt();
    void outputStmt();

    void expression();
    void parsePrecedence(int minPrec);
    void numberFn();
    void identFn();
    void groupingFn();
    void unaryFn();
    void funFn();               // fun 前缀回调：编身体 + 发 CLOSURE
    void binaryFn();
    void andFn();
    void orFn();
    void callFn();

    void emit(Op op);
    void emitByte(uint8_t b);
    void emitConstant(const Value &v);
    int emitJump(Op op);
    void patchJump(int at);
    void emitLoop(int loopStart);

    int line() const { return prev_.line; }

    Scanner sc_;
    Token prev_{}, cur_{};
    FnCtx *ctx_ = nullptr;                  // 当前函数上下文
    std::vector<std::unique_ptr<FnCtx>> ownedCtx_;  // 所有权
    Program prog_;
    int lastSlotPeak_ = 0;
};

}  // namespace tip

#endif  // TIP_COMPILER_HPP
