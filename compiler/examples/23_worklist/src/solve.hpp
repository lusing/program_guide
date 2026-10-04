// Worklist 不动点求解（spa 4.4）：从全 ⊥ 出发反复重算受影响的程序点，
// 直到没有点再变化——结果是方程组的最小不动点。
#pragma once

#include <vector>

#include "cfg.hpp"
#include "equations.hpp"
#include "sign_transfer.hpp"

namespace tip {

// eqs 仅用于确认"求解的是第 22 章那组方程"；依赖关系取自 CFG。
PointEnv solveFixpoint(const Cfg &cfg, const ProgramA &program,
                       const std::vector<MonoEq> &eqs);

}  // namespace tip
