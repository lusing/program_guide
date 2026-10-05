// file: src/llref.hpp
// 第 9 章参照物：第 6 章 LL(1) 分层递归下降的最小副本。
// 每层优先级一个函数（cmp → add → mul → unary → primary），
// 与 Pratt 规则表产出同一形状的 AST、共用同一求值器——
// 解析策略是唯一变量，两法对同一语料必须算出同一个数。
#ifndef TIP_LLREF_HPP
#define TIP_LLREF_HPP

#include "pratt.hpp"

namespace tip {

// 文法（左递归已消除，与第 6 章同型）：
//   cmp    → add cmp'
//   cmp'   → (LE|LE|GT|GE|EQ|NE) add cmp' | ε
//   add    → mul add'
//   add'   → (PLUS|MINUS) mul add' | ε
//   mul    → unary mul'
//   mul'   → (STAR|SLASH) unary mul' | ε
//   unary  → MINUS unary | primary          // STAR 前缀（解引用）不进交集语料
//   primary→ INT | IDENT | LPAREN cmp RPAREN
class LlParser {
  public:
    explicit LlParser(std::vector<Token> toks);
    ExprP parse();  // = cmp()，出错返回 nullptr

    bool hadError() const { return !errs_.empty(); }
    const std::vector<ParseError> &errors() const { return errs_; }

  private:
    ExprP cmp();
    ExprP cmpRest(ExprP lhs);
    ExprP add();
    ExprP addRest(ExprP lhs);
    ExprP mul();
    ExprP mulRest(ExprP lhs);
    ExprP unary();
    ExprP primary();

    const Token &peek() const { return toks_[pos_]; }
    Token advance();
    bool match(Tok t);
    Token expect(Tok t, const std::string &msg);

    std::vector<Token> toks_;
    size_t pos_ = 0;
    std::vector<ParseError> errs_;
};

ExprP parseLl(const std::string &src, std::vector<ParseError> &errs);

}  // namespace tip

#endif  // TIP_LLREF_HPP
