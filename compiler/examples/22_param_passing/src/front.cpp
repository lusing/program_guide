// file: src/front.cpp
// 手写扫描器 + 递归下降前端（Louden 路线：§2.5 的扫描器风格 + §4.4 的分析程序风格）。
// 不用生成器——本章的主题是运行期语义，前端越朴素越好读。
#include "front.hpp"

#include <cctype>
#include <stdexcept>

namespace plang {

namespace {

// ---------- 扫描器 ----------
struct Tok {
    std::string text;   // 关键字/名字/数字原文，或单符号
    int line;
};

bool isIdentStart(char c) { return std::isalpha(static_cast<unsigned char>(c)) || c == '_'; }
bool isIdentChar(char c) { return std::isalnum(static_cast<unsigned char>(c)) || c == '_'; }

std::vector<Tok> scan(const std::string &src) {
    std::vector<Tok> out;
    int line = 1;
    size_t i = 0;
    while (i < src.size()) {
        char c = src[i];
        if (c == '\n') { ++line; ++i; continue; }
        if (std::isspace(static_cast<unsigned char>(c))) { ++i; continue; }
        if (c == '/' && i + 1 < src.size() && src[i + 1] == '/') {   // 行注释
            while (i < src.size() && src[i] != '\n') ++i;
            continue;
        }
        if (isIdentStart(c)) {
            size_t j = i;
            while (j < src.size() && isIdentChar(src[j])) ++j;
            out.push_back({src.substr(i, j - i), line});
            i = j;
            continue;
        }
        if (std::isdigit(static_cast<unsigned char>(c))) {
            size_t j = i;
            while (j < src.size() && (std::isdigit(static_cast<unsigned char>(src[j])) || src[j] == '.'))
                ++j;
            out.push_back({src.substr(i, j - i), line});
            i = j;
            continue;
        }
        // 两字符运算符
        if (i + 1 < src.size()) {
            std::string two = src.substr(i, 2);
            if (two == "<=" || two == ">=" || two == "==" || two == "!=") {
                out.push_back({two, line});
                i += 2;
                continue;
            }
        }
        out.push_back({std::string(1, c), line});
        ++i;
    }
    return out;
}

// ---------- 递归下降分析器 ----------
// Stmt 的字段多且带 unique_ptr，部分聚合初始化会触发 -Wextra——工厂逐字段赋值。
std::unique_ptr<Stmt> newStmt(Stmt::Kind k) {
    auto st = std::make_unique<Stmt>();
    st->kind = k;
    return st;
}
class Parser {
public:
    explicit Parser(std::vector<Tok> toks) : t_(std::move(toks)) {}

    Program parseProgram() {
        Program p;
        while (!atEnd()) p.funs.push_back(parseFun());
        return p;
    }

private:
    std::vector<Tok> t_;
    size_t i_ = 0;

    bool atEnd() const { return i_ >= t_.size(); }
    const Tok &cur() const {
        static Tok eof{"?", 0};
        if (atEnd()) return eof;
        return t_[i_];
    }
    std::string peek() const { return cur().text; }
    std::string take() { return t_[i_++].text; }
    bool eat(const std::string &s) {
        if (peek() == s) { ++i_; return true; }
        return false;
    }
    void want(const std::string &s) {
        if (!eat(s))
            throw std::runtime_error("第 " + std::to_string(cur().line) + " 行：期待 '" + s +
                                     "'，遇到 '" + cur().text + "'");
    }

    std::unique_ptr<Fun> parseFun() {
        auto f = std::make_unique<Fun>();
        want("fun");
        f->name = take();
        want("(");
        while (peek() != ")") {
            Param pm;
            std::string m = take();
            if (m == "val") pm.mode = PassMode::Val;
            else if (m == "ref") pm.mode = PassMode::Ref;
            else if (m == "valres") pm.mode = PassMode::ValRes;
            else if (m == "name") pm.mode = PassMode::Name;
            else throw std::runtime_error("第 " + std::to_string(cur().line) + " 行：未知机制 '" + m + "'");
            pm.name = take();
            f->params.push_back(pm);
            if (!eat(",")) break;
        }
        want(")");
        f->body = parseBlock();
        return f;
    }

    std::vector<std::unique_ptr<Stmt>> parseBlock() {
        std::vector<std::unique_ptr<Stmt>> out;
        want("{");
        while (peek() != "}") out.push_back(parseStmt());
        want("}");
        return out;
    }

    std::unique_ptr<Stmt> parseStmt() {
        std::string s = peek();
        if (s == "var") {
            ++i_;
            auto st = newStmt(Stmt::Kind::VarDecl);
            st->name = take();
            want(";");
            return st;
        }
        if (s == "array") {
            ++i_;
            auto st = newStmt(Stmt::Kind::ArrayDecl);
            st->name = take();
            want("[");
            st->value = parseExpr();   // 长度（通常是 NUM）
            want("]");
            want(";");
            return st;
        }
        if (s == "print") {
            ++i_;
            auto st = newStmt(Stmt::Kind::Print);
            st->value = parseExpr();
            want(";");
            return st;
        }
        if (s == "if") {
            ++i_;
            auto st = newStmt(Stmt::Kind::If);
            st->cond = parseExpr();
            st->then = parseBlock();
            if (eat("else")) st->other = parseBlock();
            return st;
        }
        if (s == "while") {
            ++i_;
            auto st = newStmt(Stmt::Kind::While);
            st->cond = parseExpr();
            st->body = parseBlock();
            return st;
        }
        if (s == "for") {
            ++i_;
            auto st = newStmt(Stmt::Kind::For);
            st->name = take();
            want("=");
            st->from = parseExpr();
            want("to");
            st->to = parseExpr();
            want("do");
            st->body = parseBlock();
            return st;
        }
        if (s == "return") {
            ++i_;
            auto st = newStmt(Stmt::Kind::Return);
            st->value = parseExpr();
            want(";");
            return st;
        }
        // 赋值或过程调用：看第二个 token
        if (i_ + 1 < t_.size()) {
            const std::string &nxt = t_[i_ + 1].text;
            if (nxt == "=" || nxt == "[") {
                auto st = newStmt(Stmt::Kind::Assign);
                st->name = take();
                if (eat("[")) {
                    st->index = parseExpr();
                    want("]");
                }
                want("=");
                st->value = parseExpr();
                want(";");
                return st;
            }
            if (nxt == "(") {
                auto st = newStmt(Stmt::Kind::CallStmt);
                st->name = take();
                eat("(");
                while (peek() != ")") {
                    st->args.push_back(parseExpr());
                    if (!eat(",")) break;
                }
                want(")");
                want(";");
                return st;
            }
        }
        throw std::runtime_error("第 " + std::to_string(cur().line) + " 行：无法解释的语句起点 '" + s + "'");
    }

    // 表达式：cmp → add → mul → unary → atom（每层一个函数，第 6 章的分层法）
    std::unique_ptr<Expr> parseExpr() { return parseCmp(); }

    std::unique_ptr<Expr> mkBin(std::string op, std::unique_ptr<Expr> a, std::unique_ptr<Expr> b) {
        auto e = std::make_unique<Expr>();
        e->kind = Expr::Kind::Bin;
        e->op = std::move(op);
        e->lhs = std::move(a);
        e->rhs = std::move(b);
        return e;
    }

    std::unique_ptr<Expr> parseCmp() {
        auto a = parseAdd();
        while (peek() == "<" || peek() == "<=" || peek() == ">" || peek() == ">=" ||
               peek() == "==" || peek() == "!=") {
            std::string op = take();
            a = mkBin(op, std::move(a), parseAdd());
        }
        return a;
    }
    std::unique_ptr<Expr> parseAdd() {
        auto a = parseMul();
        while (peek() == "+" || peek() == "-") {
            std::string op = take();
            a = mkBin(op, std::move(a), parseMul());
        }
        return a;
    }
    std::unique_ptr<Expr> parseMul() {
        auto a = parseUnary();
        while (peek() == "*" || peek() == "/") {
            std::string op = take();
            a = mkBin(op, std::move(a), parseUnary());
        }
        return a;
    }
    std::unique_ptr<Expr> parseUnary() {
        if (peek() == "-") {
            ++i_;
            auto e = std::make_unique<Expr>();
            e->kind = Expr::Kind::Unary;
            e->op = "u-";
            e->lhs = parseUnary();
            return e;
        }
        return parseAtom();
    }
    std::unique_ptr<Expr> parseAtom() {
        if (eat("(")) {
            auto e = parseExpr();
            want(")");
            return e;
        }
        if (std::isdigit(static_cast<unsigned char>(peek()[0]))) {
            auto e = std::make_unique<Expr>();
            e->kind = Expr::Kind::Num;
            e->num = std::stod(take());
            return e;
        }
        if (isIdentStart(peek()[0])) {
            std::string n = take();
            if (eat("(")) {   // 调用
                auto e = std::make_unique<Expr>();
                e->kind = Expr::Kind::Call;
                e->name = n;
                while (peek() != ")") {
                    e->args.push_back(parseExpr());
                    if (!eat(",")) break;
                }
                want(")");
                return e;
            }
            if (eat("[")) {   // 数组元素
                auto e = std::make_unique<Expr>();
                e->kind = Expr::Kind::Index;
                e->name = n;
                e->lhs = parseExpr();
                want("]");
                return e;
            }
            auto e = std::make_unique<Expr>();
            e->kind = Expr::Kind::Var;
            e->name = n;
            return e;
        }
        throw std::runtime_error("第 " + std::to_string(cur().line) + " 行：表达式起点非法 '" + peek() + "'");
    }
};

}  // namespace

Program parse(const std::string &src) {
    Parser p(scan(src));
    return p.parseProgram();
}

}  // namespace plang
