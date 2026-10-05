// ORC JIT 执行：把 IRGen 的模块交给 LLJIT，注入 tip_input/tip_output
// 两个宿主 C 函数，真实执行 main，收集输出序列。
#pragma once

#include <vector>

#include "irgen.hpp"

namespace tip {

// 一次执行：inputs 按出现顺序被 tip_input 消费，返回 output 值序列。
// 模块所有权随 IRGen 一起移入 JIT。
std::vector<int> runJit(IRGen gen, const std::vector<int> &inputs);

}  // namespace tip
