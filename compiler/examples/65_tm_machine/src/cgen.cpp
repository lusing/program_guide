// file: src/cgen.cpp
// 代码生成器实现。寄存器约定与回填公式全部照 L 书 §8.8：
//   ac=r0（结果家）、ac1=r1（左操作数家）、mp=r5（内存顶=临时栈基）、gp=r6（变量基址）。
// 回填公式（写公式先写模拟器三行注释再代数，不许心算）：
//   模拟器执行位于 pc 的 RM 跳转时 reg[7] 已是 pc+1，目标 a = d + reg[7]；
//   要跳到绝对地址 addr ⇒ d = addr - (pc + 1)。
#include "cgen.hpp"

#include <algorithm>
#include <functional>
#include <sstream>

namespace tiny {

// ---------- 发码与回填 ----------

void Cgen::emitRO(const char *op, int r, int s, int t, const std::string &cmt) {
    std::ostringstream os;
    os << op << " " << r << "," << s << "," << t;
    if (!cmt.empty()) os << " ; " << cmt;
    code_.push_back(os.str());
}

void Cgen::emitRM(const char *op, int r, int d, int s, const std::string &cmt) {
    std::ostringstream os;
    os << op << " " << r << "," << d << "(" << s << ")";
    if (!cmt.empty()) os << " ; " << cmt;
    code_.push_back(os.str());
}

void Cgen::emitRMAbs(const char *op, int r, int addr, const std::string &cmt) {
    int here = static_cast<int>(code_.size());
    emitRM(op, r, addr - (here + 1), PC, cmt);
}

int Cgen::emitSkip() {
    code_.push_back("; <skip>");
    return static_cast<int>(code_.size()) - 1;
}

void Cgen::backpatch(int at, const std::string &line) { code_[at] = line; }

// ---------- 变量表 ----------

Cgen::VarInfo &Cgen::var(const std::string &name) {
    auto it = vars_.find(name);
    if (it == vars_.end()) {
        VarInfo v;
        v.memLoc = static_cast<int>(vars_.size());
        it = vars_.emplace(name, v).first;
    }
    return it->second;
}

void Cgen::countWeights(const Program &p) {
    // 引用计数 ×10^循环深度（L 书 8.10.2 的加权法：循环内引用重复执行）
    std::function<void(const std::vector<std::unique_ptr<Stmt>> &, int)> walk =
        [&](const std::vector<std::unique_ptr<Stmt>> &ss, int depth) {
            for (const auto &s : ss) {
                long long w = 1;
                for (int k = 0; k < depth; ++k) w *= 10;
                std::function<void(const Exp &)> countExp = [&](const Exp &e) {
                    if (e.kind == Exp::Kind::Id) var(e.name).weight += w;
                    if (e.lhs) countExp(*e.lhs);
                    if (e.rhs) countExp(*e.rhs);
                };
                switch (s->kind) {
                case Stmt::Kind::Assign: var(s->name).weight += w; countExp(*s->exp); break;
                case Stmt::Kind::Read: var(s->name).weight += w; break;
                case Stmt::Kind::Write: countExp(*s->exp); break;
                case Stmt::Kind::If:
                    countExp(*s->cond);
                    walk(s->thenSeq, depth);
                    walk(s->elseSeq, depth);
                    break;
                case Stmt::Kind::Repeat:
                    walk(s->body, depth + 1);
                    countExp(*s->cond);
                    break;
                }
            }
        };
    walk(p.stmts, 0);
}

void Cgen::assignResidentRegs() {
    // 8.10.2：权重最高的两个变量驻留 r3/r4（r0-r2 留给临时与工作寄存器）
    std::vector<std::pair<long long, std::string>> order;
    for (const auto &kv : vars_) order.push_back({kv.second.weight, kv.first});
    std::sort(order.begin(), order.end(),
              [](const std::pair<long long, std::string> &a,
                 const std::pair<long long, std::string> &b) { return a.first > b.first; });
    int reg = 3;
    for (const auto &w : order) {
        if (reg > 4 || w.first == 0) break;
        vars_[w.second].reg = reg;
        resident_.push_back({w.second, reg});
        ++reg;
    }
}

// ---------- 临时变量：档位分派 ----------

int Cgen::tempRegFor(int depth) const {
    if (!optTemps_) return -1;
    if (optVars_) return depth == 0 ? 2 : -1;   // 8.10.2：r3/r4 让给变量，临时只剩 r2
    return depth <= 2 ? 2 + depth : -1;          // 8.10.1：r2/r3/r4 三档
}

void Cgen::saveTemp(const char *why) {
    int r = tempRegFor(tmpDepth_);
    ++tmpDepth_;
    if (r >= 0) emitRM("LDA", r, 0, AC, why);
    else emitRM("ST", AC, tmpOffset_--, MP, why);
}

void Cgen::loadTemp(const char *why) {
    --tmpDepth_;
    int r = tempRegFor(tmpDepth_);
    if (r >= 0) emitRM("LDA", AC1, 0, r, why);
    else emitRM("LD", AC1, ++tmpOffset_, MP, why);
}

// ---------- 表达式 ----------

// 叶子（常量/变量）直发目标寄存器——压弹消除的主角。
void Cgen::genLeafInto(const Exp &e, int r, const char *why) {
    if (e.kind == Exp::Kind::Const) emitRM("LDC", r, static_cast<int>(e.val), 0, why);
    else {
        VarInfo &v = var(e.name);
        if (v.reg >= 0) emitRM("LDA", r, 0, v.reg, why);
        else emitRM("LD", r, v.memLoc, GP, why);
    }
}

void Cgen::genExp(const Exp &e) {
    switch (e.kind) {
    case Exp::Kind::Const:
        emitRM("LDC", AC, static_cast<int>(e.val), 0, "load const");
        break;
    case Exp::Kind::Id: {
        VarInfo &v = var(e.name);
        if (v.reg >= 0) emitRM("LDA", AC, 0, v.reg, "var in reg");
        else emitRM("LD", AC, v.memLoc, GP, "load var");
        break;
    }
    case Exp::Kind::Op: {
        const char *op;
        switch (e.op) {
        case Tok::Add: op = "ADD"; break;
        case Tok::Sub: op = "SUB"; break;
        case Tok::Mul: op = "MUL"; break;
        case Tok::Div: op = "DIV"; break;
        default: op = "SUB"; break;   // 比较的差值在 ac，布尔化/直转在条件位处理
        }
        // 档 1 起的叶子直发：右部是常量/变量时直接发进 ac1，省掉一压一弹。
        // 操作数位两路不同：压弹路径 ac=右、ac1=左（RO dst,s,t = ac1 op ac）；
        // 叶路径 ac=左、ac1=右（dst,s,t = ac op ac1）——都要保证 dst = 左 op 右。
        if (optTemps_ && e.rhs->kind != Exp::Kind::Op) {
            genExp(*e.lhs);
            genLeafInto(*e.rhs, AC1, "leaf rhs -> ac1");
            emitRO(op, AC, AC, AC1, "apply op (leaf)");
        } else {
            genExp(*e.lhs);
            saveTemp("op: push left");
            genExp(*e.rhs);
            loadTemp("op: pop left");
            emitRO(op, AC, AC1, AC, "apply op");
        }
        break;
    }
    }
}

// ---------- 条件：布尔化（低档）与直转（8.10.3） ----------

void Cgen::emitCond(const Exp &cond) {
    genExp(*cond.lhs);
    saveTemp("cond: push left");
    genExp(*cond.rhs);
    loadTemp("cond: pop left");
    emitRO("SUB", AC, AC1, AC, "left - right");
    lastRelop_ = cond.op;
    if (!optTest_) {
        // C 风格布尔化五指令模板（§8.8.2）。执行时的 reg[7] 已是 pc+1：
        //   JLT/JEQ +2(7) 落到 LDC 1（真臂）；否则 LDC 0 后 LDA 跳过真臂。
        const char *j = cond.op == Tok::Lt ? "JLT" : "JEQ";
        emitRM(j, AC, 2, PC, "bool: jump true arm");
        emitRM("LDC", AC, 0, 0, "bool: false = 0");
        emitRMAbs("LDA", PC, static_cast<int>(code_.size()) + 2, "bool: skip true arm");
        emitRM("LDC", AC, 1, 0, "bool: true = 1");
    }
    // tier3：差值留 ac，跳转由 emitJumpIfFalse/True 补条件直发
}

void Cgen::emitJumpIfFalse(int addr, const std::string &why) {
    if (!optTest_) emitRMAbs("JEQ", AC, addr, why);
    else emitRMAbs(lastRelop_ == Tok::Lt ? "JGE" : "JNE", AC, addr, why);
}

void Cgen::emitJumpIfTrue(int addr, const std::string &why) {
    if (!optTest_) emitRMAbs("JNE", AC, addr, why);
    else emitRMAbs(lastRelop_ == Tok::Lt ? "JLT" : "JEQ", AC, addr, why);
}

// ---------- 语句 ----------

void Cgen::genSeq(const std::vector<std::unique_ptr<Stmt>> &ss) {
    for (const auto &s : ss) genStmt(*s);
}

void Cgen::genStmt(const Stmt &s) {
    switch (s.kind) {
    case Stmt::Kind::Assign: {
        genExp(*s.exp);
        VarInfo &v = var(s.name);
        if (v.reg >= 0) emitRM("LDA", v.reg, 0, AC, "assign into reg var");
        else emitRM("ST", AC, v.memLoc, GP, "assign: store var");
        break;
    }
    case Stmt::Kind::Read: {
        emitRO("IN", AC, 0, 0, "read");
        VarInfo &v = var(s.name);
        if (v.reg >= 0) emitRM("LDA", v.reg, 0, AC, "read into reg var");
        else emitRM("ST", AC, v.memLoc, GP, "read: store");
        break;
    }
    case Stmt::Kind::Write: {
        genExp(*s.exp);
        emitRO("OUT", AC, 0, 0, "write");
        break;
    }
    case Stmt::Kind::If: {
        emitCond(*s.cond);
        int toElse = emitSkip();          // 假 → else/end 的跳转占位
        genSeq(s.thenSeq);
        if (!s.elseSeq.empty()) {
            int overElse = emitSkip();    // then 完 → 跳过 else 占位
            int elseAddr = static_cast<int>(code_.size());
            // 回填占位：绝对地址换相对偏移的公式同 emitRMAbs
            std::ostringstream os;
            if (optTest_) os << (lastRelop_ == Tok::Lt ? "JGE" : "JNE");
            else os << "JEQ";
            os << " " << AC << "," << (elseAddr - (toElse + 1)) << "(" << PC << ")"
                << " ; if: jmp to else";
            backpatch(toElse, os.str());
            genSeq(s.elseSeq);
            int endAddr = static_cast<int>(code_.size());
            std::ostringstream os2;
            os2 << "LDA " << PC << "," << (endAddr - (overElse + 1)) << "(" << PC << ")"
                << " ; if: jmp over else";
            backpatch(overElse, os2.str());
        } else {
            int endAddr = static_cast<int>(code_.size());
            std::ostringstream os;
            if (optTest_) os << (lastRelop_ == Tok::Lt ? "JGE" : "JNE");
            else os << "JEQ";
            os << " " << AC << "," << (endAddr - (toElse + 1)) << "(" << PC << ")"
                << " ; if: jmp to end";
            backpatch(toElse, os.str());
        }
        break;
    }
    case Stmt::Kind::Repeat: {
        int top = static_cast<int>(code_.size());
        genSeq(s.body);
        emitCond(*s.cond);
        // until 语义：条件真则落下（退出循环）、假则回跳——回跳就是"假跳"
        emitJumpIfFalse(top, "repeat: while false, loop");
        break;
    }
    }
}

// ---------- 顶层 ----------

std::string Cgen::gen(const Program &p, Tier tier) {
    code_.clear();
    vars_.clear();
    resident_.clear();
    tmpOffset_ = 0;
    tmpDepth_ = 0;
    optTemps_ = tier != Tier::None;
    optVars_ = tier == Tier::Vars || tier == Tier::Test;
    optTest_ = tier == Tier::Test;
    if (optVars_) {
        countWeights(p);
        assignResidentRegs();
    }
    // 标准序幕（§8.8.2）：mp 指向数据区顶（临时栈基）；清 dMem[0]（启动标记）
    emitRM("LDC", MP, 511, 0, "prelude: mp = top of dMem");
    emitRM("ST", AC, 0, 0, "prelude: clear dMem[0]");
    genSeq(p.stmts);
    emitRO("HALT", 0, 0, 0, "end of program");
    std::ostringstream os;
    for (size_t i = 0; i < code_.size(); ++i) os << i << ": " << code_[i] << "\n";
    return os.str();
}

}  // namespace tiny
