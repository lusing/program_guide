// file: src/scanner.hpp
// 第 55 章：即取即用扫描器（匠书 §16）——无 token 缓冲，编译器
// 要一个取一个。advance/peek/match 三函数即全部协议。
#ifndef TIP_SCANNER_HPP
#define TIP_SCANNER_HPP

#include <cstdint>
#include <string>
#include <vector>

namespace tip {

enum class Tok : uint8_t {
    Int, Ident,
    KwVar, KwReturn, KwOutput, KwIf, KwElse, KwWhile, KwFun,
    Plus, Minus, Star, Slash,
    Eq, Ne, Gt, Ge, Lt, Le,        // 双字符优先
    AndAnd, OrOr,                  // && ||（教学扩展，C 风格布尔化）
    Assign,                        // '='（单字符；'==' 已被上面吃掉）
    LParen, RParen, LBrace, RBrace, Semi, Comma,
    Eof,
};

struct Token {
    Tok t = Tok::Eof;
    std::string text;   // 标识符/数字原文
    long long num = 0;  // Int 有效
    int line = 1;
};

struct ScanError {
    std::string msg;
    int line = 0;
};

class Scanner {
  public:
    Scanner() = default;  // Compiler 按值持有时需要（compile 时再喂源）
    explicit Scanner(std::string src) : src_(std::move(src)) {}

    // 三函数协议（匠书 makeToken/advance/peek 同型）
    Token scanToken();           // 取下一个 token（跳过空白与注释）
    char peekChar() const { return cur_ < src_.size() ? src_[cur_] : '\0'; }
    char peekNext() const { return cur_ + 1 < src_.size() ? src_[cur_ + 1] : '\0'; }
    int line() const { return line_; }

  private:
    char advanceChar();
    void skipWhitespaceAndComments();
    bool matchChar(char expect);  // 条件消费：匹配则前进

    std::string src_;
    size_t cur_ = 0;
    int line_ = 1;
};

}  // namespace tip

#endif  // TIP_SCANNER_HPP
