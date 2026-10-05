// 符号传递函数与单趟执行：抽象环境沿 CFG 逐点传播。
// 本章按程序点编号顺序只走一遍——回边在被走到时目标尚未计算，按 ⊥ 处理，
// 因此循环携带的信息会丢失。第 28 章用 worklist 反复走到不动点解决。
#pragma once

#include <map>
#include <string>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

using SignEnv = std::map<std::string, int>;  // 变量名 → 符号；缺键视为 ⊥
using PointEnv = std::map<int, SignEnv>;     // 程序点 → 该点执行后的抽象环境

int signOfLiteral(int v);
int evalExprSign(const Expr *e, const SignEnv &env);

SignEnv entryEnv(const FunDecl &f);                 // 参数 = ⊤，局部变量缺省 ⊥
SignEnv joinEnv(const SignEnv &a, const SignEnv &b);
SignEnv transferNode(const CfgNode &node, const SignEnv &in);

// 单趟：按节点编号顺序，每点 = transfer(join(前驱已有状态))。
PointEnv singlePass(const Cfg &cfg, const ProgramA &program);

std::string printPointEnv(const Cfg &cfg, const ProgramA &program,
                          const PointEnv &states);

}  // namespace tip
