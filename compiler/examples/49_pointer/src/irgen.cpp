#include "irgen.hpp"

#include <functional>
#include <stdexcept>
#include <utility>
#include <vector>

#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Constants.h"
#include "llvm/IR/DerivedTypes.h"
#include "llvm/IR/Function.h"
#include "llvm/IR/Verifier.h"
#include "llvm/Support/raw_ostream.h"

using namespace llvm;

namespace tip {

IRGen::IRGen()
    : ctx(std::make_unique<LLVMContext>()),
      mod(std::make_unique<Module>("tip", *ctx)),
      b(std::make_unique<IRBuilder<>>(*ctx)) {
    // 运行时入口先声明：input 无参返回 i32，output 吃一个 i32。
    auto *i32 = Type::getInt32Ty(*ctx);
    rtInput_ = mod->getOrInsertFunction(
        "tip_input", FunctionType::get(i32, false));
    rtOutput_ = mod->getOrInsertFunction(
        "tip_output", FunctionType::get(Type::getVoidTy(*ctx), {i32}, false));
    malloc_ = mod->getOrInsertFunction(
        "malloc", FunctionType::get(b->getPtrTy(), {Type::getInt64Ty(*ctx)},
                                    false));
}

namespace {

// TIP 的 main 改名 tip_main：真正的 @main 是我们生成的 C 入口。
std::string emitName(const std::string &name) {
    return name == "main" ? "tip_main" : name;
}

}  // namespace

void IRGen::inferDepths(const ProgramA &program) {
    // 符号索引：(函数名, 名字) → Symbol*，形参与局部变量都收录。
    std::map<std::pair<std::string, std::string>, const Symbol *> allSym;
    for (size_t i = 0; i < program.funs.size(); ++i) {
        const FunDecl *f = program.funs[i].get();
        for (const auto &[name, sym] : bindings->scopes[i]->table)
            allSym[{f->name, name}] = &sym;
    }

    // std::function：Deref 分支需要递归调用自身。
    std::function<int(const Expr *)> depthOf = [&](const Expr *e) -> int {
        if (const auto *x = dynamic_cast<const VarRef *>(e)) {
            auto it = bindings->uses.find(x);
            if (it != bindings->uses.end()) {
                auto dit = depth.find(it->second);
                return dit == depth.end() ? 0 : dit->second;
            }
        } else if (const auto *x = dynamic_cast<const AddrOf *>(e)) {
            // &z：在符号索引中找到 z，深度 +1。
            for (const auto &[key, sym] : allSym)
                if (key.second == x->name) {
                    auto dit = depth.find(sym);
                    return (dit == depth.end() ? 0 : dit->second) + 1;
                }
        } else if (dynamic_cast<const AllocE *>(e) ||
                   dynamic_cast<const NullE *>(e)) {
            return 1;
        } else if (const auto *x = dynamic_cast<const Deref *>(e)) {
            int d = depthOf(x->e.get());
            return d > 0 ? d - 1 : 0;
        }
        return 0;
    };

    auto raise = [&](const Symbol *s, int d) {
        auto it = depth.find(s);
        int old = it == depth.end() ? 0 : it->second;
        if (d > old) {
            depth[s] = d;
            return true;
        }
        return false;
    };

    bool changed = true;
    while (changed) {
        changed = false;

        for (const auto &fp : program.funs) {
            const FunDecl *f = fp.get();

            std::function<void(const Stmt *)> walk = [&](const Stmt *s) {
                if (const auto *x = dynamic_cast<const AssignS *>(s)) {
                    if (const auto *t =
                            dynamic_cast<const VarRef *>(x->target.get())) {
                        auto it = bindings->uses.find(t);
                        if (it != bindings->uses.end())
                            if (raise(it->second, depthOf(x->value.get())))
                                changed = true;
                    } else if (const auto *t =
                                   dynamic_cast<const Deref *>(x->target.get())) {
                        // *p = v：p 至少比 v 深一层。
                        int vd = depthOf(x->value.get());
                        if (const auto *v =
                                dynamic_cast<const VarRef *>(t->e.get())) {
                            auto pit = bindings->uses.find(v);
                            if (pit != bindings->uses.end())
                                if (raise(pit->second, vd + 1)) changed = true;
                        }
                    }
                } else if (const auto *x = dynamic_cast<const IfS *>(s)) {
                    walk(x->then.get());
                    if (x->els) walk(x->els.get());
                } else if (const auto *x = dynamic_cast<const WhileS *>(s)) {
                    walk(x->body.get());
                } else if (const auto *x = dynamic_cast<const BlockS *>(s)) {
                    for (const auto &st : x->ss) walk(st.get());
                }
            };
            walk(f->body.get());

            // 返回值深度。
            int rd = depthOf(f->ret->e.get());
            if (rd > retDepth[f->name]) {
                retDepth[f->name] = rd;
                changed = true;
            }

            // 直接调用：实参深度提升形参深度。
            std::function<void(const Expr *)> calls = [&](const Expr *e) {
                if (const auto *x = dynamic_cast<const CallE *>(e)) {
                    if (const auto *fn =
                            dynamic_cast<const VarRef *>(x->callee.get())) {
                        auto fit = bindings->uses.find(fn);
                        if (fit != bindings->uses.end() &&
                            fit->second->kind == Symbol::Fun) {
                            const std::string &calleeName = fit->second->name;
                            const auto &ps = fit->second->fun->params;
                            for (size_t i = 0;
                                 i < x->args.size() && i < ps.size(); ++i) {
                                auto pit = allSym.find(
                                    {calleeName, ps[i]});
                                if (pit != allSym.end())
                                    if (raise(pit->second,
                                              depthOf(x->args[i].get())))
                                        changed = true;
                            }
                        }
                    }
                    for (const auto &a : x->args) calls(a.get());
                } else if (const auto *x = dynamic_cast<const Binop *>(e)) {
                    calls(x->l.get());
                    calls(x->r.get());
                } else if (const auto *x = dynamic_cast<const Deref *>(e)) {
                    calls(x->e.get());
                }
            };
            calls(f->ret->e.get());
            std::function<void(const Stmt *)> cwalk = [&](const Stmt *s) {
                if (const auto *x = dynamic_cast<const AssignS *>(s))
                    calls(x->value.get());
                else if (const auto *x = dynamic_cast<const OutputS *>(s))
                    calls(x->e.get());
                else if (const auto *x = dynamic_cast<const IfS *>(s)) {
                    calls(x->cond.get());
                    cwalk(x->then.get());
                    if (x->els) cwalk(x->els.get());
                } else if (const auto *x = dynamic_cast<const WhileS *>(s)) {
                    calls(x->cond.get());
                    cwalk(x->body.get());
                } else if (const auto *x = dynamic_cast<const BlockS *>(s)) {
                    for (const auto &st : x->ss) cwalk(st.get());
                }
            };
            cwalk(f->body.get());
        }
    }
}

void IRGen::gen(const ProgramA &program, const Bindings &resolved) {
    bindings = &resolved;
    inferDepths(program);

    auto *i32 = Type::getInt32Ty(*ctx);
    for (size_t i = 0; i < program.funs.size(); ++i) {
        const auto &f = program.funs[i];
        std::vector<Type *> args;
        for (const std::string &p : f->params) {
            const Symbol *s = &resolved.scopes[i]->table.at(p);
            int d = depth.count(s) ? depth.at(s) : 0;
            args.push_back(d > 0 ? static_cast<Type *>(b->getPtrTy())
                                 : static_cast<Type *>(i32));
        }
        Type *ret = retDepth[f->name] > 0
                        ? static_cast<Type *>(b->getPtrTy())
                        : static_cast<Type *>(i32);
        Function::Create(FunctionType::get(ret, args, false),
                         Function::ExternalLinkage, emitName(f->name), *mod);
    }

    for (size_t i = 0; i < program.funs.size(); ++i) {
        const auto &f = program.funs[i];
        cur = f.get();
        genFun(f.get(), resolved.scopes[i].get());
    }

    const FunDecl *mainFun = nullptr;
    for (const auto &f : program.funs)
        if (f->name == "main") mainFun = f.get();
    if (!mainFun) throw std::runtime_error("program has no main");
    genWrapper(mainFun);
}

void IRGen::genFun(const FunDecl *f, Scope *scope) {
    auto *fn = llvm::cast<Function>(mod->getFunction(emitName(f->name)));
    auto *entry = BasicBlock::Create(*ctx, "entry", fn);
    b->SetInsertPoint(entry);

    // 形参：按深度开槽 + 存入实参；var 局部：按深度开槽 + 零初始化。
    for (size_t j = 0; j < f->params.size(); ++j) {
        const Symbol *s = &scope->table.at(f->params[j]);
        int d = depth.count(s) ? depth.at(s) : 0;
        Type *ty = d > 0 ? static_cast<Type *>(b->getPtrTy())
                         : static_cast<Type *>(b->getInt32Ty());
        auto *slot = b->CreateAlloca(ty, nullptr, f->params[j]);
        b->CreateStore(fn->getArg(j), slot);
        locals[s] = slot;
    }
    for (const std::string &v : f->vars) {
        const Symbol *s = &scope->table.at(v);
        int d = depth.count(s) ? depth.at(s) : 0;
        Type *ty = d > 0 ? static_cast<Type *>(b->getPtrTy())
                         : static_cast<Type *>(b->getInt32Ty());
        auto *slot = b->CreateAlloca(ty, nullptr, v);
        if (d > 0)
            b->CreateStore(ConstantPointerNull::get(b->getPtrTy()), slot);
        else
            b->CreateStore(b->getInt32(0), slot);
        locals[s] = slot;
    }

    stmt(f->body.get());
    b->CreateRet(expr(f->ret->e.get()));
}

Value *IRGen::expr(const Expr *e) {
    if (const auto *x = dynamic_cast<const IntLit *>(e))
        return ConstantInt::get(b->getInt32Ty(), x->v, true);

    if (const auto *x = dynamic_cast<const VarRef *>(e)) {
        const Symbol *s = bindings->uses.at(x);
        int d = depth.count(s) ? depth.at(s) : 0;
        if (d > 0)
            return b->CreateLoad(b->getPtrTy(), locals.at(s), x->name);
        return b->CreateLoad(b->getInt32Ty(), locals.at(s), x->name);
    }

    if (dynamic_cast<const InputE *>(e))
        return b->CreateCall(rtInput_);

    if (dynamic_cast<const NullE *>(e))
        return ConstantPointerNull::get(b->getPtrTy());

    if (const auto *x = dynamic_cast<const AllocE *>(e)) {
        Value *cell = b->CreateCall(malloc_, {b->getInt64(4)});
        b->CreateStore(expr(x->e.get()), cell);
        return cell;
    }

    if (const auto *x = dynamic_cast<const AddrOf *>(e)) {
        const Symbol *s = nullptr;
        for (const auto &[sym, slot] : locals)
            if (sym->fun == cur && sym->name == x->name) {
                s = sym;
                break;
            }
        if (!s) throw std::runtime_error("&z: z not found in function");
        return locals.at(s);
    }

    if (const auto *x = dynamic_cast<const Deref *>(e)) {
        Value *p = expr(x->e.get());
        // 结果深度 = 基址深度 − 1：决定 load i32 还是 ptr。
        int baseD = 0;
        if (const auto *v = dynamic_cast<const VarRef *>(x->e.get())) {
            const Symbol *s = bindings->uses.at(v);
            baseD = depth.count(s) ? depth.at(s) : 0;
        }
        if (baseD - 1 >= 1)
            return b->CreateLoad(b->getPtrTy(), p);
        return b->CreateLoad(b->getInt32Ty(), p);
    }

    if (const auto *x = dynamic_cast<const Binop *>(e)) {
        if (x->op == BOp::Eq) {
            const Expr *other = nullptr;
            if (dynamic_cast<const NullE *>(x->l.get()))
                other = x->r.get();
            else if (dynamic_cast<const NullE *>(x->r.get()))
                other = x->l.get();

            Value *lv, *rv;
            if (other) {
                Value *ov = expr(other);
                Value *nv = ConstantPointerNull::get(b->getPtrTy());
                if (other == x->l.get()) {
                    lv = ov; rv = nv;
                } else {
                    lv = nv; rv = ov;
                }
            } else {
                lv = expr(x->l.get());
                rv = expr(x->r.get());
            }
            Value *p = b->CreateICmpEQ(lv, rv);
            return b->CreateZExt(p, b->getInt32Ty());
        }

        Value *l = expr(x->l.get());
        Value *r = expr(x->r.get());
        switch (x->op) {
            case BOp::Add: return b->CreateAdd(l, r);
            case BOp::Sub: return b->CreateSub(l, r);
            case BOp::Mul: return b->CreateMul(l, r);
            case BOp::Div: return b->CreateSDiv(l, r);
            case BOp::Gt: {
                Value *p = b->CreateICmpSGT(l, r);
                return b->CreateZExt(p, b->getInt32Ty());
            }
            case BOp::Eq: break;
        }
    }

    if (const auto *x = dynamic_cast<const CallE *>(e)) {
        const auto *nameUse = dynamic_cast<const VarRef *>(x->callee.get());
        if (!nameUse)
            throw std::runtime_error("indirect call not supported");
        const Symbol *s = bindings->uses.at(nameUse);
        if (s->kind != Symbol::Fun)
            throw std::runtime_error("indirect call not supported");
        auto *callee = mod->getFunction(emitName(s->name));
        std::vector<Value *> args;
        for (const auto &a : x->args) args.push_back(expr(a.get()));
        return b->CreateCall(callee, args);
    }

    throw std::runtime_error("unsupported expression (records etc.)");
}

void IRGen::stmt(const Stmt *s) {
    if (const auto *x = dynamic_cast<const AssignS *>(s)) {
        if (const auto *target = dynamic_cast<const VarRef *>(x->target.get())) {
            const Symbol *sym = bindings->uses.at(target);
            b->CreateStore(expr(x->value.get()), locals.at(sym));
            return;
        }
        if (const auto *t = dynamic_cast<const Deref *>(x->target.get())) {
            Value *p = expr(t->e.get());
            b->CreateStore(expr(x->value.get()), p);
            return;
        }
        throw std::runtime_error("field store not supported");
    }

    if (const auto *x = dynamic_cast<const OutputS *>(s)) {
        b->CreateCall(rtOutput_, {expr(x->e.get())});
        return;
    }

    if (const auto *x = dynamic_cast<const IfS *>(s)) {
        Function *fn = b->GetInsertBlock()->getParent();
        auto *thenBB = BasicBlock::Create(*ctx, "then", fn);
        auto *elseBB = BasicBlock::Create(*ctx, "else", fn);
        auto *mergeBB = BasicBlock::Create(*ctx,"merge", fn);

        Value *cc = b->CreateICmpNE(expr(x->cond.get()), b->getInt32(0));
        b->CreateCondBr(cc, thenBB, elseBB);

        b->SetInsertPoint(thenBB);
        stmt(x->then.get());
        if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(mergeBB);

        b->SetInsertPoint(elseBB);
        if (x->els) {
            stmt(x->els.get());
            if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(mergeBB);
        } else {
            b->CreateBr(mergeBB);
        }
        b->SetInsertPoint(mergeBB);
        return;
    }

    if (const auto *x = dynamic_cast<const WhileS *>(s)) {
        Function *fn = b->GetInsertBlock()->getParent();
        auto *header = BasicBlock::Create(*ctx, "wh.cond", fn);
        auto *bodyBB = BasicBlock::Create(*ctx, "wh.body", fn);
        auto *exitBB = BasicBlock::Create(*ctx, "wh.exit", fn);

        b->CreateBr(header);
        b->SetInsertPoint(header);
        Value *cc = b->CreateICmpNE(expr(x->cond.get()), b->getInt32(0));
        b->CreateCondBr(cc, bodyBB, exitBB);

        b->SetInsertPoint(bodyBB);
        stmt(x->body.get());
        if (!b->GetInsertBlock()->getTerminator()) b->CreateBr(header);

        b->SetInsertPoint(exitBB);
        return;
    }

    if (const auto *x = dynamic_cast<const BlockS *>(s)) {
        for (const auto &st : x->ss) stmt(st.get());
        return;
    }

    if (const auto *x = dynamic_cast<const ReturnS *>(s))
        b->CreateRet(expr(x->e.get()));
}

void IRGen::genWrapper(const FunDecl *mainFun) {
    // C 入口：按 TIP main 形参数目读 input，再调用 tip_main。
    // 不命名为 main——MinGW 目标会向 main 注入对 CRT 符号 __main 的调用。
    auto *fn = Function::Create(FunctionType::get(b->getInt32Ty(), false),
                                Function::ExternalLinkage, "tip_entry", *mod);
    auto *entry = BasicBlock::Create(*ctx, "entry", fn);
    b->SetInsertPoint(entry);

    std::vector<Value *> args;
    for (size_t j = 0; j < mainFun->params.size(); ++j)
        args.push_back(b->CreateCall(rtInput_));
    Value *r = b->CreateCall(mod->getFunction("tip_main"), args);
    b->CreateRet(r);
}

bool IRGen::verify() const {
    std::string err;
    llvm::raw_string_ostream os(err);
    bool bad = llvm::verifyModule(*mod, &os);
    os.str();
    return !bad;
}

std::string IRGen::dump() const {
    std::string out;
    llvm::raw_string_ostream os(out);
    mod->print(os, nullptr);
    return os.str();
}

}  // namespace tip
