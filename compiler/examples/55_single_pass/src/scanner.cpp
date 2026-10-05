// file: src/scanner.cpp
#include "scanner.hpp"

namespace tip {

char Scanner::advanceChar() {
    char c = src_[cur_++];
    if (c == '\n') ++line_;
    return c;
}

void Scanner::skipWhitespaceAndComments() {
    for (;;) {
        char c = peekChar();
        if (c == ' ' || c == '\t' || c == '\r' || c == '\n') {
            advanceChar();
        } else if (c == '/' && peekNext() == '/') {
            // 行注释：吃到行尾（换行留给空白处理记账行号）
            while (peekChar() != '\0' && peekChar() != '\n') advanceChar();
        } else {
            return;
        }
    }
}

bool Scanner::matchChar(char expect) {
    if (peekChar() != expect) return false;
    advanceChar();
    return true;
}

Token Scanner::scanToken() {
    skipWhitespaceAndComments();
    Token tk;
    tk.line = line_;
    char c = peekChar();
    if (c == '\0') {
        tk.t = Tok::Eof;
        return tk;
    }
    auto two = [&](Tok t, const char *s) {
        advanceChar();
        advanceChar();
        tk.t = t;
        tk.text = s;
    };
    auto one = [&](Tok t, const char *s) {
        advanceChar();
        tk.t = t;
        tk.text = s;
    };
    // 双字符运算符先于单字符（最长匹配，与第 9 章口径一致）
    if (c == '=' && peekNext() == '=') return two(Tok::Eq, "=="), tk;
    if (c == '!' && peekNext() == '=') return two(Tok::Ne, "!="), tk;
    if (c == '>' && peekNext() == '=') return two(Tok::Ge, ">="), tk;
    if (c == '<' && peekNext() == '=') return two(Tok::Le, "<="), tk;
    if (c == '&' && peekNext() == '&') return two(Tok::AndAnd, "&&"), tk;
    if (c == '|' && peekNext() == '|') return two(Tok::OrOr, "||"), tk;

    if (c >= '0' && c <= '9') {
        std::string s;
        while (peekChar() >= '0' && peekChar() <= '9') s += advanceChar();
        tk.t = Tok::Int;
        tk.text = s;
        tk.num = 0;
        for (char d : s) tk.num = tk.num * 10 + (d - '0');
        return tk;
    }
    if ((c >= 'a' && c <= 'z') || (c >= 'A' && c <= 'Z') || c == '_') {
        std::string s;
        for (;;) {
            char p = peekChar();
            if ((p >= 'a' && p <= 'z') || (p >= 'A' && p <= 'Z') ||
                (p >= '0' && p <= '9') || p == '_')
                s += advanceChar();
            else break;
        }
        tk.text = s;
        if (s == "var") tk.t = Tok::KwVar;
        else if (s == "return") tk.t = Tok::KwReturn;
        else if (s == "output") tk.t = Tok::KwOutput;
        else if (s == "if") tk.t = Tok::KwIf;
        else if (s == "else") tk.t = Tok::KwElse;
        else if (s == "while") tk.t = Tok::KwWhile;
        else tk.t = Tok::Ident;
        return tk;
    }
    switch (c) {
        case '+': return one(Tok::Plus, "+"), tk;
        case '-': return one(Tok::Minus, "-"), tk;
        case '*': return one(Tok::Star, "*"), tk;
        case '/': return one(Tok::Slash, "/"), tk;
        case '>': return one(Tok::Gt, ">"), tk;
        case '<': return one(Tok::Lt, "<"), tk;
        case '=': return one(Tok::Assign, "="), tk;
        case '(': return one(Tok::LParen, "("), tk;
        case ')': return one(Tok::RParen, ")"), tk;
        case '{': return one(Tok::LBrace, "{"), tk;
        case '}': return one(Tok::RBrace, "}"), tk;
        case ';': return one(Tok::Semi, ";"), tk;
        case ',': return one(Tok::Comma, ","), tk;
        default:
            // 即取即用扫描的错误口径：报出事字符与行号即止（单遍，
            // 错误恢复没有多遍可依赖——匠书 §16.2 的取舍同款）
            throw ScanError{std::string("意外字符 '") + c + "'", line_};
    }
}

}  // namespace tip
