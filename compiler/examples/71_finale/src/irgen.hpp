// LLVM IR 生成：把 AST 翻译成 LLVM Module。
// 本章只覆盖整数核心：算术、比较、input/output、if/while、直接函数调用；
// 指针、记录、间接调用在第 53 章以后扩展，遇到时直接报错。
#pragma once

#include <map>
#include <memory>
#include <string>

#include "llvm/IR/IRBuilder.h"
#include "llvm/IR/LLVMContext.h"
#include "llvm/IR/Module.h"

#include "ast.hpp"
#include "symtab.hpp"

namespace tip {

struct IRGen {
    // 三者均以 unique_ptr 持有：JIT 需要接管 Module 与 Context 的所有权。
    std::unique_ptr<llvm::LLVMContext> ctx;
    std::unique_ptr<llvm::Module> mod;
    std::unique_ptr<llvm::IRBuilder<>> b;

    const Bindings *bindings = nullptr;
    const FunDecl *cur = nullptr;
    std::map<const Symbol *, llvm::AllocaInst *> locals;

    IRGen();

    // 生成全部 TIP 函数 + C main（main 改名 tip_main）。
    // 结束后模块必须通过 verify。
    void gen(const ProgramA &program, const Bindings &resolved);

    llvm::Value *expr(const Expr *e);
    void stmt(const Stmt *s);

    bool verify() const;
    std::string dump() const;

  private:
    llvm::FunctionCallee rtInput_, rtOutput_;

    void genFun(const FunDecl *f, Scope *scope);
    void genWrapper(const FunDecl *mainFun);
};

}  // namespace tip
