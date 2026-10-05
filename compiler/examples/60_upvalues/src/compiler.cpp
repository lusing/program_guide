// file: src/compiler.cpp
#include "compiler.hpp"

namespace tip {

// ---------- Pratt 规则表 ----------
enum class Prec {
    None = 0, OrOr, AndAnd, Equality, Comparison, Term, Factor, Unary, Call,
};

struct Compiler::CRule {
    void (Compiler::*prefix)() = nullptr;
    void (Compiler::*infix)() = nullptr;
    Prec prec = Prec::None;
};

Compiler::CRule Compiler::ruleFor(Tok t) {
    using C = Compiler;
    switch (t) {
        case Tok::Int:    return {&C::numberFn, nullptr, Prec::None};
        case Tok::Ident:  return {&C::identFn, nullptr, Prec::None};
        case Tok::LParen: return {&C::groupingFn, &C::callFn, Prec::Call};
        case Tok::Minus:  return {&C::unaryFn, &C::binaryFn, Prec::Term};
        case Tok::KwFun:  return {&C::funFn, nullptr, Prec::None};  // §25.1
        case Tok::OrOr:   return {nullptr, &C::orFn, Prec::OrOr};
        case Tok::AndAnd: return {nullptr, &C::andFn, Prec::AndAnd};
        case Tok::Eq: case Tok::Ne:
            return {nullptr, &C::binaryFn, Prec::Equality};
        case Tok::Gt: case Tok::Ge: case Tok::Lt: case Tok::Le:
            return {nullptr, &C::binaryFn, Prec::Comparison};
        case Tok::Plus: return {nullptr, &C::binaryFn, Prec::Term};
        case Tok::Star: case Tok::Slash:
            return {nullptr, &C::binaryFn, Prec::Factor};
        default: return {};
    }
}

// ---------- 词法层 ----------
Token Compiler::advance() {
    prev_ = cur_;
    cur_ = sc_.scanToken();
    return prev_;
}
bool Compiler::check(Tok t) const { return cur_.t == t; }
bool Compiler::match(Tok t) {
    if (!check(t)) return false;
    advance();
    return true;
}
Token Compiler::consume(Tok t, const char *msg) {
    if (check(t)) return advance();
    throw CompileError{std::string(msg) + "，但看到 '" + cur_.text + "'", cur_.line};
}

// ---------- 作用域与上值 ----------
void Compiler::beginScope() { ++ctx_->scopeDepth; }
void Compiler::endScope() {
    --ctx_->scopeDepth;
    int pop = 0;
    while (!ctx_->locals.empty() && ctx_->locals.back().depth > ctx_->scopeDepth) {
        // 被捕获的槽位：先 CLOSE_UPVALUE（值搬进盒子），再 POP（槽让位）
        if (ctx_->locals.back().isCaptured) emit(Op::CloseUpvalue);
        ctx_->locals.pop_back();
        ++pop;
    }
    for (; pop > 0; --pop) emit(Op::Pop);
}
int Compiler::resolveLocal(FnCtx *ctx, const std::string &name) const {
    for (int i = int(ctx->locals.size()) - 1; i >= 0; --i)
        if (ctx->locals[size_t(i)].name == name) return i;
    return -1;
}
int Compiler::resolveUpvalue(FnCtx *ctx, const std::string &name) {
    if (!ctx->parent) return -1;
    // 先在外层的局部里找：命中 → 本函数捕"外层栈槽"（isLocal 真）
    int local = resolveLocal(ctx->parent, name);
    if (local >= 0) {
        ctx->parent->locals[size_t(local)].isCaptured = true;
        return addUpvalue(ctx, /*isLocal=*/true, uint8_t(local));
    }
    // 外层也没有 → 递归穿更外层：命中 → 捕"外层的上值"（传递）
    int up = resolveUpvalue(ctx->parent, name);
    if (up >= 0) return addUpvalue(ctx, /*isLocal=*/false, uint8_t(up));
    return -1;
}
int Compiler::addUpvalue(FnCtx *ctx, bool isLocal, uint8_t index) {
    // 去重：同一变量捕获两次只占一格——两个闭包共享同一上值的基础
    for (size_t i = 0; i < ctx->fn->upvals.size(); ++i)
        if (ctx->fn->upvals[i].isLocal == isLocal && ctx->fn->upvals[i].index == index)
            return int(i);
    ctx->fn->upvals.push_back(UpvalDesc{isLocal, index});
    return int(ctx->fn->upvals.size()) - 1;
}
void Compiler::declareLocal(const std::string &name, int line) {
    for (int i = int(ctx_->locals.size()) - 1; i >= 0; --i) {
        const Local &l = ctx_->locals[size_t(i)];
        if (l.depth != ctx_->scopeDepth) break;
        if (l.name == name)
            throw CompileError{"同层重复声明：" + name, line};
    }
    ctx_->locals.push_back(Local{name, ctx_->scopeDepth, false});
    if (int(ctx_->locals.size()) > lastSlotPeak_)
        lastSlotPeak_ = int(ctx_->locals.size());
}

// ---------- 发码 ----------
void Compiler::emit(Op op) { ctx_->fn->code->write(op, line()); }
void Compiler::emitByte(uint8_t b) { ctx_->fn->code->writeByte(b, line()); }
void Compiler::emitConstant(const Value &v) {
    emit(Op::Constant);
    emitByte(uint8_t(ctx_->fn->code->addConstant(v)));
}
int Compiler::emitJump(Op op) {
    emit(op);
    ctx_->fn->code->writeU16(0xFFFF, line());
    return int(ctx_->fn->code->code.size()) - 2;
}
void Compiler::patchJump(int at) {
    size_t target = ctx_->fn->code->code.size();
    uint16_t off = uint16_t(target - at - 2);
    ctx_->fn->code->code[at] = uint8_t(off >> 8);
    ctx_->fn->code->code[at + 1] = uint8_t(off & 0xFF);
}
void Compiler::emitLoop(int loopStart) {
    emit(Op::Loop);
    size_t here = ctx_->fn->code->code.size();
    ctx_->fn->code->writeU16(uint16_t(here - loopStart + 2), line());
}

// ---------- 程序与函数 ----------
Program Compiler::compile(const std::string &src) {
    sc_ = Scanner(src);
    advance();
    while (!check(Tok::Eof)) function(/*named=*/true);
    return std::move(prog_);
}

// 顶层函数与 fun 字面量的公共身体——两类函数一视同仁（§25.1）。
// named=true：吃函数名，产物进 prog_（驱动注册进全局表）。
// named=false（funFn 回调进入）：匿名，产物进外层常量池并由
//   调用处发 CLOSURE（携带捕获表）。
void Compiler::function(bool named) {
    std::string name = named ? consume(Tok::Ident, "期望函数名").text : "%fun";

    FnCtx *outer = ctx_;
    auto owned = std::make_unique<FnCtx>();
    FnCtx *ctx = owned.get();
    ownedCtx_.push_back(std::move(owned));
    ctx->parent = outer;
    ctx->named = named;
    ctx->fn = std::make_shared<ObjFn>();
    ctx->fn->name = name;
    ctx->fn->code = std::make_shared<Chunk>();
    ctx->locals.push_back(Local{name, 0, false});  // 槽 0：函数自己占位
    ctx_ = ctx;

    consume(Tok::LParen, "期望 '('");
    if (!check(Tok::RParen)) {
        for (;;) {
            Token p = consume(Tok::Ident, "期望形参名");
            declareLocal(p.text, p.line);
            ++ctx->fn->arity;
            if (!match(Tok::Comma)) break;
        }
    }
    consume(Tok::RParen, "期望 ')'");
    consume(Tok::LBrace, "期望 '{'");

    if (match(Tok::KwVar)) {  // 函数头 var 声明（占位压栈，55 章同款）
        for (;;) {
            Token v = consume(Tok::Ident, "期望变量名");
            declareLocal(v.text, v.line);
            emitConstant(Value::num(0));
            if (!match(Tok::Comma)) break;
        }
        consume(Tok::Semi, "期望 ';'");
    }

    beginScope();
    while (!check(Tok::KwReturn) && !check(Tok::RBrace) && !check(Tok::Eof))
        statement();
    endScope();

    consume(Tok::KwReturn, "期望 'return'");
    expression();
    consume(Tok::Semi, "期望 ';'");
    emit(Op::Return);
    consume(Tok::RBrace, "期望 '}'");

    if (named) {
        prog_.fns.push_back(ctx->fn);
    } else {
        // 字面量：在外层常量池登记函数，随后发 CLOSURE：
        //   u8 常量索引 + u8 捕获数 + 每捕获两字节（isLocal?1:0, 索引）
        int k = outer->fn->code->addConstant(Value::ref(ctx->fn));
        FnCtx *o = outer;  // 发码走外层上下文
        o->fn->code->write(Op::Closure, line());
        o->fn->code->writeByte(uint8_t(k), line());
        o->fn->code->writeByte(uint8_t(ctx->fn->upvals.size()), line());
        for (const UpvalDesc &u : ctx->fn->upvals) {
            o->fn->code->writeByte(u.isLocal ? 1 : 0, line());
            o->fn->code->writeByte(u.index, line());
        }
    }
    ctx_ = outer;  // 回到外层继续
}

// ---------- 语句层 ----------
void Compiler::statement() {
    if (match(Tok::KwVar)) varStmt();
    else if (match(Tok::KwOutput)) outputStmt();
    else if (match(Tok::KwIf)) ifStmt();
    else if (match(Tok::KwWhile)) whileStmt();
    else if (match(Tok::LBrace)) blockStmt();
    else exprStmt();
}

void Compiler::blockStmt() {
    beginScope();
    while (!check(Tok::RBrace) && !check(Tok::Eof)) statement();
    endScope();  // 被捕获槽位在此 CLOSE（§25.5 的爆破点）
    consume(Tok::RBrace, "期望 '}'");
}

void Compiler::varStmt() {
    for (;;) {
        Token v = consume(Tok::Ident, "期望变量名");
        declareLocal(v.text, v.line);
        emitConstant(Value::num(0));
        if (!match(Tok::Comma)) break;
    }
    consume(Tok::Semi, "期望 ';'");
}

void Compiler::exprStmt() {
    Token name = consume(Tok::Ident, "期望语句");
    consume(Tok::Assign, "期望 '='");
    expression();
    int slot = resolveLocal(ctx_, name.text);
    if (slot >= 0) {
        emit(Op::SetLocal);
        emitByte(uint8_t(slot));
    } else {
        int up = resolveUpvalue(ctx_, name.text);  // 闭包也能写捕获（计数器！）
        if (up >= 0) {
            emit(Op::SetUpvalue);
            emitByte(uint8_t(up));
        } else {
            emit(Op::SetGlobal);
            emitByte(uint8_t(ctx_->fn->code->addName(name.text)));
        }
    }
    emit(Op::Pop);
    consume(Tok::Semi, "期望 ';'");
}

void Compiler::ifStmt() {
    consume(Tok::LParen, "期望 '('");
    expression();
    consume(Tok::RParen, "期望 ')'");
    int jElse = emitJump(Op::JumpIfFalse);
    statement();
    int jEnd = emitJump(Op::Jump);
    patchJump(jElse);
    if (match(Tok::KwElse)) statement();
    patchJump(jEnd);
}

void Compiler::whileStmt() {
    int loopStart = int(ctx_->fn->code->code.size());
    consume(Tok::LParen, "期望 '('");
    expression();
    consume(Tok::RParen, "期望 ')'");
    int jExit = emitJump(Op::JumpIfFalse);
    statement();
    emitLoop(loopStart);
    patchJump(jExit);
}

void Compiler::outputStmt() {
    expression();
    consume(Tok::Semi, "期望 ';'");
    emit(Op::Print);
}

// ---------- 表达式层 ----------
void Compiler::expression() { parsePrecedence(int(Prec::None)); }

void Compiler::parsePrecedence(int minPrec) {
    advance();
    CRule r = ruleFor(prev_.t);
    if (!r.prefix) throw CompileError{"期望表达式，但看到 '" + prev_.text + "'", prev_.line};
    (this->*r.prefix)();
    while (true) {
        r = ruleFor(cur_.t);
        if (int(r.prec) < minPrec || r.infix == nullptr) break;
        (this->*r.infix)();
    }
}

void Compiler::numberFn() { emitConstant(Value::num(prev_.num)); }

void Compiler::identFn() {
    // 名字的三个世界：本函数局部 → 栈槽；外层捕获 → 上值；全局 → 迟绑定
    int slot = resolveLocal(ctx_, prev_.text);
    if (slot >= 0) {
        emit(Op::GetLocal);
        emitByte(uint8_t(slot));
        return;
    }
    int up = resolveUpvalue(ctx_, prev_.text);
    if (up >= 0) {
        emit(Op::GetUpvalue);
        emitByte(uint8_t(up));
        return;
    }
    emit(Op::GetGlobal);
    emitByte(uint8_t(ctx_->fn->code->addName(prev_.text)));
}

void Compiler::groupingFn() {
    expression();
    consume(Tok::RParen, "期望 ')'");
}

void Compiler::unaryFn() {
    parsePrecedence(int(Prec::Unary));
    emit(Op::Negate);
}

void Compiler::funFn() {
    // fun (params) { body return e; } ——函数字面量（第 15 章教学扩展
    // 的编译器版）。整个身体的编译在 function(false) 里完成，回来时
    // CLOSURE（连同捕获表）已发在外层代码里。
    function(/*named=*/false);
}

void Compiler::binaryFn() {
    advance();
    Tok op = prev_.t;
    CRule r = ruleFor(op);
    parsePrecedence(int(r.prec) + 1);
    switch (op) {
        case Tok::Plus: emit(Op::Add); break;
        case Tok::Minus: emit(Op::Sub); break;
        case Tok::Star: emit(Op::Mul); break;
        case Tok::Slash: emit(Op::Div); break;
        case Tok::Gt: emit(Op::Gt); break;
        case Tok::Eq: emit(Op::Eq); break;
        case Tok::Ne: emit(Op::Ne); break;
        case Tok::Ge: emit(Op::Ge); break;
        case Tok::Le: emit(Op::Le); break;
        case Tok::Lt: emit(Op::Lt); break;
        default: break;
    }
}

void Compiler::andFn() {
    advance();
    int jf1 = emitJump(Op::JumpIfFalse);
    parsePrecedence(int(Prec::AndAnd) + 1);
    int jf2 = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je = emitJump(Op::Jump);
    patchJump(jf1);
    patchJump(jf2);
    emitConstant(Value::num(0));
    patchJump(je);
}

void Compiler::orFn() {
    advance();
    int jr = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je1 = emitJump(Op::Jump);
    patchJump(jr);
    parsePrecedence(int(Prec::OrOr) + 1);
    int jf = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je2 = emitJump(Op::Jump);
    patchJump(jf);
    emitConstant(Value::num(0));
    patchJump(je1);
    patchJump(je2);
}

void Compiler::callFn() {
    consume(Tok::LParen, "期望 '('");
    int argc = 0;
    if (!check(Tok::RParen)) {
        expression();
        ++argc;
        while (match(Tok::Comma)) {
            expression();
            ++argc;
        }
    }
    consume(Tok::RParen, "期望 ')'");
    emit(Op::Call);
    emitByte(uint8_t(argc));
}

}  // namespace tip
