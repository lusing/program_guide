// file: src/tinyparse.cpp
#include "tinyparse.hpp"

#include "tinyscan.hpp"

#include <stdexcept>

namespace tiny {

namespace {

class Parser {
public:
    explicit Parser(const std::vector<ScanTok> &toks) : t_(toks) {}

    Program parseProgram() {
        Program p;
        p.stmts = stmtSeq();
        want(Tok::EndOfFile);
        return p;
    }

private:
    const std::vector<ScanTok> &t_;
    size_t i_ = 0;

    const ScanTok &cur() const { return t_[i_]; }
    bool eat(Tok k) {
        if (cur().kind == k) { ++i_; return true; }
        return false;
    }
    void want(Tok k) {
        if (!eat(k))
            throw ParseError{"语法: 期待 '" + std::string(tokName(k)) + "'，遇到 '" +
                                 tokName(cur().kind) + "'",
                             cur().line};
    }
    [[noreturn]] void fail(const std::string &why) {
        throw ParseError{"语法: " + why + "（遇到 '" + tokName(cur().kind) + "'）", cur().line};
    }

    // stmt-seq → stmt { ';' stmt }——语句以分号分隔（最后一条不带）。
    std::vector<std::unique_ptr<Stmt>> stmtSeq() {
        std::vector<std::unique_ptr<Stmt>> out;
        out.push_back(stmt());
        while (eat(Tok::Semi)) out.push_back(stmt());
        return out;
    }

    std::unique_ptr<Stmt> stmt() {
        int line = cur().line;
        switch (cur().kind) {
        case Tok::If: return ifStmt(line);
        case Tok::Repeat: return repeatStmt(line);
        case Tok::Read: return readStmt(line);
        case Tok::Write: return writeStmt(line);
        case Tok::Id: return assignStmt(line);
        default: fail("语句起点非法");
        }
    }

    std::unique_ptr<Stmt> ifStmt(int line) {
        want(Tok::If);
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::If;
        s->line = line;
        s->cond = cond();
        want(Tok::Then);
        s->thenSeq = stmtSeq();
        if (eat(Tok::Else)) s->elseSeq = stmtSeq();
        want(Tok::End);
        return s;
    }

    std::unique_ptr<Stmt> repeatStmt(int line) {
        want(Tok::Repeat);
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::Repeat;
        s->line = line;
        s->body = stmtSeq();
        want(Tok::Until);
        s->cond = cond();
        return s;
    }

    std::unique_ptr<Stmt> assignStmt(int line) {
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::Assign;
        s->line = line;
        s->name = cur().text;
        want(Tok::Id);
        want(Tok::Assign);
        s->exp = exp();
        return s;
    }

    std::unique_ptr<Stmt> readStmt(int line) {
        want(Tok::Read);
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::Read;
        s->line = line;
        s->name = cur().text;
        want(Tok::Id);
        return s;
    }

    std::unique_ptr<Stmt> writeStmt(int line) {
        want(Tok::Write);
        auto s = std::make_unique<Stmt>();
        s->kind = Stmt::Kind::Write;
        s->line = line;
        s->exp = exp();
        return s;
    }

    // 条件专用：exp relop exp（L 书口径：比较只出现在 if/repeat 的条件位）
    std::unique_ptr<Exp> cond() {
        auto lhs = exp();
        if (cur().kind != Tok::Lt && cur().kind != Tok::Eq)
            fail("条件期待比较运算符");
        auto e = std::make_unique<Exp>();
        e->kind = Exp::Kind::Op;
        e->op = cur().kind;
        ++i_;
        e->lhs = std::move(lhs);
        e->rhs = exp();
        return e;
    }

    std::unique_ptr<Exp> exp() {
        auto a = term();
        while (cur().kind == Tok::Add || cur().kind == Tok::Sub) {
            Tok op = cur().kind;
            ++i_;
            auto e = std::make_unique<Exp>();
            e->kind = Exp::Kind::Op;
            e->op = op;
            e->lhs = std::move(a);
            e->rhs = term();
            a = std::move(e);
        }
        return a;
    }

    std::unique_ptr<Exp> term() {
        auto a = factor();
        while (cur().kind == Tok::Mul || cur().kind == Tok::Div) {
            Tok op = cur().kind;
            ++i_;
            auto e = std::make_unique<Exp>();
            e->kind = Exp::Kind::Op;
            e->op = op;
            e->lhs = std::move(a);
            e->rhs = factor();
            a = std::move(e);
        }
        return a;
    }

    std::unique_ptr<Exp> factor() {
        if (eat(Tok::LParen)) {
            auto e = exp();
            want(Tok::RParen);
            return e;
        }
        if (cur().kind == Tok::Num) {
            auto e = std::make_unique<Exp>();
            e->kind = Exp::Kind::Const;
            e->val = cur().num;
            ++i_;
            return e;
        }
        if (cur().kind == Tok::Id) {
            auto e = std::make_unique<Exp>();
            e->kind = Exp::Kind::Id;
            e->name = cur().text;
            ++i_;
            return e;
        }
        fail("表达式起点非法");
    }
};

}  // namespace

Program parse(const std::vector<ScanTok> &toks) {
    Parser p(toks);
    return p.parseProgram();
}

}  // namespace tiny
