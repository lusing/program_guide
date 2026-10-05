// file: src/compiler.cpp
#include "compiler.hpp"


namespace tip {

// ---------- Pratt 规则表（第 11 章的表，回调换成发码） ----------
// 优先级从松到紧（枚举值即比较序），与第 11 章 Prec 同序。
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
    for (;;) {
        cur_ = sc_.scanToken();
        return prev_;
    }
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

// ---------- 作用域 ----------
void Compiler::beginScope() { ++scopeDepth_; }
void Compiler::endScope() {
    --scopeDepth_;
    int pop = 0;
    while (!locals_.empty() && locals_.back().depth > scopeDepth_) {
        locals_.pop_back();
        ++pop;
    }
    // 槽位回收：每弹一个局部发一条 POP（§22.3）
    for (; pop > 0; --pop) emit(Op::Pop);
}
int Compiler::resolveLocal(const std::string &name) const {
    for (int i = int(locals_.size()) - 1; i >= 0; --i)
        if (locals_[size_t(i)].name == name) return i;
    return -1;
}
void Compiler::declareLocal(const std::string &name, int line) {
    // 同层重名拒绝（跨层遮蔽合法——第 15 章 V5 的口径）
    for (int i = int(locals_.size()) - 1; i >= 0; --i) {
        const Local &l = locals_[size_t(i)];
        if (l.depth != scopeDepth_) break;  // 更外层不必再查
        if (l.name == name)
            throw CompileError{"同层重复声明：" + name, line};
    }
    locals_.push_back(Local{name, scopeDepth_});
    if (int(locals_.size()) > lastSlotPeak_) lastSlotPeak_ = int(locals_.size());
}

// ---------- 发码与回填 ----------
void Compiler::emit(Op op) { fn_->code->write(op, line()); }
void Compiler::emitByte(uint8_t b) { fn_->code->writeByte(b, line()); }
void Compiler::emitConstant(const Value &v) {
    emit(Op::Constant);
    emitByte(uint8_t(fn_->code->addConstant(v)));
}
int Compiler::emitJump(Op op) {
    emit(op);
    fn_->code->writeU16(0xFFFF, line());  // 占位：目标此刻不存在
    return int(fn_->code->code.size()) - 2;  // 记住偏移字段的位置
}
void Compiler::patchJump(int at) {
    // 回填：目标 = 当前代码末尾（then 支编译完成后恰是要跳到的地方）
    size_t target = fn_->code->code.size();
    uint16_t off = uint16_t(target - at - 2);  // 读操作数后 ip=at+2
    fn_->code->code[at] = uint8_t(off >> 8);
    fn_->code->code[at + 1] = uint8_t(off & 0xFF);
}
void Compiler::emitLoop(int loopStart) {
    emit(Op::Loop);
    // 向后跳。emit 已写下操作码，here = Loop 地址 + 1；VM 读码后
    // ip = Loop地址 + 3，要回到 loopStart：偏移 = here - loopStart + 2。
    size_t here = fn_->code->code.size();
    fn_->code->writeU16(uint16_t(here - loopStart + 2), line());
}

// ---------- 程序与函数 ----------
Program Compiler::compile(const std::string &src) {
    sc_ = Scanner(src);
    advance();  // 填充 cur_
    while (!check(Tok::Eof)) function();
    return std::move(prog_);
}

void Compiler::function() {
    Token name = consume(Tok::Ident, "期望函数名");
    fn_ = std::make_shared<ObjFn>();
    fn_->name = name.text;
    fn_->code = std::make_shared<Chunk>();

    // 槽 0 = 函数自己占位（第 57 章帧协议），随后形参逐个入槽
    locals_.clear();
    scopeDepth_ = 0;
    locals_.push_back(Local{name.text, 0});

    consume(Tok::LParen, "期望 '('");
    if (!check(Tok::RParen)) {
        for (;;) {
            Token p = consume(Tok::Ident, "期望形参名");
            declareLocal(p.text, p.line);
            ++fn_->arity;
            if (!match(Tok::Comma)) break;
        }
    }
    consume(Tok::RParen, "期望 ')'");
    consume(Tok::LBrace, "期望 '{'");

    // 函数头 var 声明（TIP 原味：声明组）。声明即发占位压栈
    //（CONSTANT 0）——槽位必须在代码执行到使用点前已在栈上成形
    //（clox 的 var 发 OP_NIL 同款；第 15 章"声明即占位"的编译版）。
    if (match(Tok::KwVar)) {
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

    prog_.fns.push_back(fn_);
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
    beginScope();               // 块即作用域（第 15 章块环境的编译版）
    while (!check(Tok::RBrace) && !check(Tok::Eof)) statement();
    endScope();                 // 出块发 POP：槽位回收
    consume(Tok::RBrace, "期望 '}'");
}

void Compiler::varStmt() {
    // 块级 var（教学扩展，jlox 同款）：声明即占槽并压占位 0
    //（确定赋值检查是第 15 章的领地——单遍编译器不做，如实说明）
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
    // 赋值目标：局部 → SET_LOCAL；否则 SET_GLOBAL（迟绑定写）
    int slot = resolveLocal(name.text);
    if (slot >= 0) {
        emit(Op::SetLocal);
        emitByte(uint8_t(slot));
    } else {
        emit(Op::SetGlobal);
        emitByte(uint8_t(fn_->code->addName(name.text)));
    }
    emit(Op::Pop);  // 语句值丢弃（TIP 赋值是语句）
    consume(Tok::Semi, "期望 ';'");
}

void Compiler::ifStmt() {
    // §23.3 双跳转模板：then/else 各占一个前向跳转，支编译完回填
    consume(Tok::LParen, "期望 '('");
    expression();
    consume(Tok::RParen, "期望 ')'");
    int jElse = emitJump(Op::JumpIfFalse);
    statement();               // then 支
    int jEnd = emitJump(Op::Jump);
    patchJump(jElse);          // else 支从这里开始
    if (match(Tok::KwElse)) statement();
    patchJump(jEnd);           // 汇合点
}

void Compiler::whileStmt() {
    int loopStart = int(fn_->code->code.size());  // 条件的位置：回边目标
    consume(Tok::LParen, "期望 '('");
    expression();
    consume(Tok::RParen, "期望 ')'");
    int jExit = emitJump(Op::JumpIfFalse);
    statement();
    emitLoop(loopStart);       // 向后跳：目标已知，直接写
    patchJump(jExit);
}

void Compiler::outputStmt() {
    expression();
    consume(Tok::Semi, "期望 ';'");
    emit(Op::Print);
}

void Compiler::returnStmt() {
    expression();
    consume(Tok::Semi, "期望 ';'");
    emit(Op::Return);
}

// ---------- 表达式层（Pratt） ----------
void Compiler::expression() { parsePrecedence(int(Prec::None)); }

void Compiler::parsePrecedence(int minPrec) {
    advance();  // 当前 token 进 prev_（回调通过 prev_ 知道自己是谁）
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
    // 名字的两个世界：函数局部（编译期已解析 → 槽位）与全局（迟绑定）
    int slot = resolveLocal(prev_.text);
    if (slot >= 0) {
        emit(Op::GetLocal);
        emitByte(uint8_t(slot));
    } else {
        emit(Op::GetGlobal);
        emitByte(uint8_t(fn_->code->addName(prev_.text)));
    }
}

void Compiler::groupingFn() {
    expression();
    consume(Tok::RParen, "期望 ')'");
}

void Compiler::unaryFn() {
    // 一元负号：先发操作数，再发 NEGATE（后缀序！——第 57 章的教训）
    parsePrecedence(int(Prec::Unary));
    emit(Op::Negate);
}

void Compiler::binaryFn() {
    advance();  // 吃掉运算符 token（与第 11 章 binary 开头的 advance 同位）
    // 左操作数已在栈上（调用者发的）；先发右操作数，再发运算符。
    // 压栈序即求值序（后缀序）——第 57 章 fib 手编翻车的机器版教训：
    // 编译器把"序"一次性想清楚，人从此不用每次想。
    Tok op = prev_.t;
    CRule r = ruleFor(op);
    parsePrecedence(int(r.prec) + 1);  // 左结合：右操作数抬一级
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
        default: break;
    }
}

void Compiler::andFn() {
    advance();  // 吃掉 && 
    // C 风格布尔化（真 1 假 0，TIP 整数宇宙口径）：
    //   a; JIF Lf; b; JIF Lf; CONST 1; JMP Le; Lf: CONST 0; Le:
    // a 假 → 0（b 的发码完全不执行：短路）；a 真 b 假 → 0；双真 → 1。
    int jf1 = emitJump(Op::JumpIfFalse);
    parsePrecedence(int(Prec::AndAnd) + 1);   // 右操作数
    int jf2 = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je = emitJump(Op::Jump);
    patchJump(jf1);   // 两处假出口汇到 CONST 0
    patchJump(jf2);
    emitConstant(Value::num(0));
    patchJump(je);    // 真出口越过 CONST 0
}

void Compiler::orFn() {
    advance();  // 吃掉 ||
    // a || b：a; JIF Lr; CONST 1; JMP Le; Lr: b; JIF Lf; CONST 1; JMP Le;
    //         Lf: CONST 0; Le:
    // a 真 → 1（b 不执行）；a 假 → 看 b。
    int jr = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je1 = emitJump(Op::Jump);
    patchJump(jr);                        // Lr：右侧从这开始
    parsePrecedence(int(Prec::OrOr) + 1);
    int jf = emitJump(Op::JumpIfFalse);
    emitConstant(Value::num(1));
    int je2 = emitJump(Op::Jump);
    patchJump(jf);                        // Lf：假出口
    emitConstant(Value::num(0));
    patchJump(je1);                       // Le：两个真出口都越过 CONST 0
    patchJump(je2);
}

void Compiler::callFn() {
    // 被调者已在栈上（identFn/groupingFn 发的）；发实参后 CALL
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
