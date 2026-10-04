// 可靠性经验验证（spa 1.3 的 soundness 概念落地）：
//   1. 静态：符号分析（第 16 章 worklist）给出每个程序点上每个变量的符号；
//      常量分析（本章）给出部分点的确定常量。
//   2. 动态：对 INPUTS 里的每组输入，用 ORC JIT 真实执行程序，收集输出序列。
//   3. 对账：需要一个"第 k 次输出对应哪个 output 语句"的映射——
//      由一个具体解释器（与 JIT 同语义）在解释时记录每次执行的 output 语句，
//      JIT 只负责产生值序列。把具体值转成符号后断言 ⊑ 静态预测；
//      静态预测为常量处再断言逐点相等。任一断言失败即 UNSOUND。
#pragma once

#include <string>
#include <vector>

#include "ast.hpp"

namespace tip {

// 一次具体执行：输出值序列 + 每个值来自哪个 OutputS 语句（下标一一对应）。
struct ConcreteRun {
    std::vector<int> values;
    std::vector<const OutputS *> sites;
};

// 具体解释执行：inputs 按序供 input 表达式消费。
// 仅覆盖标量算术/控制流/函数调用；指针与记录构造在此抛错（验证程序不使用）。
ConcreteRun interpret(const ProgramA &program, const std::vector<int> &inputs);

}  // namespace tip
