// 第 21 章配套：widening ∇ 与 narrowing Δ（spa 4.7/4.8 的区间版落地）。
// 区间格高度无穷，朴素迭代不终止；∇ 在加宽点（循环头）把发散的链
// 强行压到阈值表 {-inf,0,1,+inf} 上，有限步收敛但代价是过松；
// Δ 用原方程从 ∇ 解出发再推一遍，只把 ±∞ 处的界收回有限值。
#pragma once

#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"
#include "interval.hpp"

namespace tip {

// 单个区间的加宽/收窄算子（正文给出阈值表与规则）。
Iv widen(const Iv &a, const Iv &b);
Iv narrow(const Iv &a, const Iv &b);

// 条件精炼：进入 (x > k) 的"真"边时 x 的下界提到 k+1，
// 走"假"边时上界压到 k；(x == k) 的真边把 x 钉成 [k,k]。
IvEnv refineOnBranch(const Expr *cond, const IvEnv &env, bool taken);

struct WidenedResult {
    bool converged = false;
    int rounds = 0;
    int headNode = -1;                 // 循环头（加宽点）节点号
    std::vector<std::string> trace;    // 每轮循环头环境（∇ 已施加）
    std::map<int, IvEnv> out;          // ∇ 不动点的流出状态
};

// 带加宽的 round-robin 求解：加宽点 = 全部 while 条件节点。
WidenedResult solveWidenedInterval(const Cfg &cfg, const ProgramA &program,
                                   int maxRounds);

// 一次收窄：从 ∇ 解出发按原方程重推一遍，用 Δ 规则只收 ±∞ 端。
// 返回收窄后的流出状态（键与 widened 相同）。
std::map<int, IvEnv> narrowPass(const Cfg &cfg, const ProgramA &program,
                                const std::map<int, IvEnv> &widened);

std::string printIvEnv(const IvEnv &env, const std::set<std::string> &keys);

}  // namespace tip
