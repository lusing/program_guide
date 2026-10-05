// 第 47 章配套：k-CFA 调用串上下文敏感常量传播。
// 调用串（call string）：从进入当前函数起，沿途经过的调用点序列（截断到
// 最近 k 个）。同一函数在不同调用串下各维护一份状态——k=0 退化为上下文
// 不敏感，k 越大分得越细，精度换状态数。
// k<0 表示"无限 k"：不截断调用串、靠状态去重（记忆化）终止。对无环调用
// 图这等价于函数式（functional）做法能给出的精度；为防有环失控仍设深度
// 上限 8，超过即回退 ⊤。
#pragma once

#include <map>
#include <string>
#include <utility>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"
#include "constant.hpp"

namespace tip {

// 调用点 = (调用方函数名, 调用所在 CFG 节点号)。CFG 节点号只在函数内
// 唯一，所以必须带上函数名才是一个全局调用点。
using Site = std::pair<std::string, int>;
// 调用串：Site 序列，back() 是最近的调用点。
using Ctx = std::vector<Site>;

// (调用串, 函数) → 节点 → 出口环境。
using CtxFun = std::pair<Ctx, std::string>;
using CtxStates = std::map<CtxFun, ConstPointEnv>;

struct ContextResult {
    CtxStates out;          // 每个上下文里每个函数的逐点出口状态
    std::map<std::string, int> ctxCount;  // 每个函数实际出现过的上下文数
};

// k >= 0：调用串截断到最近 k 个调用点；k < 0：无限 k（记忆化 + 深度上限）。
ContextResult solveContext(const Cfg &cfg, const ProgramA &program, int k);

// main（空调用串）中每个 output 点的常量预测：可能缺项（不可达点）。
std::vector<std::pair<const OutputS *, Const>> outputPredictionsCtx(
    const Cfg &cfg, const ContextResult &r);

}  // namespace tip
