// 单调方程组（spa 4.4）：把"每点状态 = 传递函数作用于前驱合并"写成显式方程。
// 方程是分析的规格：第 16 章的 worklist 只是这组方程的一种求解算法。
#pragma once

#include <string>
#include <utility>
#include <vector>

#include "cfg.hpp"

namespace tip {

struct MonoEq {
    int point = 0;                 // 等号左边的程序点
    std::vector<int> deps;         // 右边依赖的前驱点（CFG 上的流依赖）
    std::string expr;              // 可读的右端表达
};

std::vector<MonoEq> signEquations(const Cfg &cfg);
std::string printEquations(const Cfg &cfg, const std::vector<MonoEq> &eqs);

}  // namespace tip
