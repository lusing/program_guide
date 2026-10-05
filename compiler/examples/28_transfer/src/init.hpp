// 第 28 章配套：可能未初始化分析（spa 9.1 的经典例子，作为"传递函数"一节的落地）。
// 与第 26 章 gen/kill 框架的关键差别：这里的传递函数依赖状态本身——
// "c = b" 当 b 可能未初始化时 c 也必须标记为可能未初始化（污染沿数据流传播）。
// 因此本章手写 worklist 求解器，并保存每个点的流入状态供警告定位使用。
#pragma once

#include <map>
#include <set>
#include <string>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"

namespace tip {

struct InitResult {
    // 程序点 → 流入/流出的"可能未初始化变量"集合（前向 may，幂集格）。
    std::map<int, std::set<std::string>> inState;
    std::map<int, std::set<std::string>> outState;
    // 不动点求完之后统一收集的 use-before-init 警告。
    std::vector<std::string> warnings;
};

InitResult runInitAnalysis(const Cfg &cfg, const ProgramA &program);

std::string printInit(const Cfg &cfg, const ProgramA &program,
                      const InitResult &r);

}  // namespace tip
