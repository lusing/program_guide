// 第 36 章配套：路径精炼（spa 7.1 assertion 精炼思想的区间版）。
// 同一个区间求解器跑两档：关掉条件精炼 = 流不敏感基线；
// 打开条件精炼 = 分支内状态被 (x > k) 收紧，除零告警随之消除。
// 两档都用 ∇ 终止；差别只在"边是否携带条件信息"。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"
#include "interval.hpp"

namespace tip {

struct PathResult {
    bool converged = false;
    int rounds = 0;
    std::map<int, IvEnv> out;  // 每点流出状态
};

// refineOnEdges=false：分支边不精炼（对照基线）；true：真/假边按条件收紧。
PathResult solveInterval(const Cfg &cfg, const ProgramA &program,
                         int maxRounds, bool refineOnEdges);

// 除零检查：对每个除法子式，除数区间含 0 即告警（⊥ 区间不告警）。
std::vector<std::string> divZeroWarnings(const Cfg &cfg,
                                         const std::map<int, IvEnv> &out);

// output 点的区间预测一览。
std::vector<std::string> outputPredictions(const Cfg &cfg,
                                           const std::map<int, IvEnv> &out);

}  // namespace tip
