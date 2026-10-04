// 常量格（spa 4.1/4.3 的 Flat 常量域）：每个变量取值 ∈ {⊥, c, ⊤}。
//   ⊥（不可达） < 具体常量 c < ⊤（非常量/未知）
// join 规则：两边相等取该值；一边 ⊥ 取另一边；否则 ⊤。
#pragma once

#include <string>

#include "ast.hpp"
#include "cfg.hpp"
#include "sign_transfer.hpp"  // PointEnv 形态与 printPointEnv 复用

namespace tip {

struct Const {
    int kind = 0;  // 0=⊥, 1=常量, 2=⊤
    int v = 0;     // kind==1 时有效

    bool operator==(const Const &o) const { return kind == o.kind && v == o.v; }
};

std::string constShow(const Const &c);

Const cBot();         // ⊥
Const cTop();         // ⊤
Const cVal(int v);    // 具体常量
Const cJoin(const Const &a, const Const &b);

// 常量传递函数：复用 CFG，环境改为 变量→Const。
using ConstEnv = std::map<std::string, Const>;
using ConstPointEnv = std::map<int, ConstEnv>;

ConstEnv constEntryEnv(const FunDecl &f);
ConstEnv constJoinEnv(const ConstEnv &a, const ConstEnv &b);
Const evalConstExpr(const Expr *e, const ConstEnv &env);
ConstEnv constTransferNode(const CfgNode &node, const ConstEnv &in);

ConstPointEnv solveConstFixpoint(const Cfg &cfg, const ProgramA &program);
std::string printConstEnv(const Cfg &cfg, const ProgramA &program,
                          const ConstPointEnv &states);

}  // namespace tip
