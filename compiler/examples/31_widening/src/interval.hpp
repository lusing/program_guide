// 第 30 章配套：区间格与朴素迭代的不终止演示（spa 第 4→5 章的衔接）。
// 区间 [lo,hi] 回答"这个变量最小/最大能取多少"；lo>hi 编码 ⊥（不可达）。
// 与符号格不同，区间格**高度无穷**：[1,1] ⊑ [1,2] ⊑ [1,3] ⊑ … 没有尽头。
// Tarski 定理仍保证最小不动点存在，但朴素迭代不再保证在有限步内到达它——
// 本章用封顶 50 轮的朴素迭代把这个不终止"演出来"，为第 31 章 widening 铺路。
#pragma once

#include <climits>
#include <map>
#include <string>
#include <vector>

#include "ast.hpp"
#include "cfg.hpp"
#include "lattice.hpp"

namespace tip {

// INT_MIN/INT_MAX 哨兵表示 -∞/+∞；lo>hi 表示 ⊥。
struct Iv {
    int lo, hi;
};
inline bool operator==(const Iv &a, const Iv &b) {
    return a.lo == b.lo && a.hi == b.hi;
}

// 区间格：join 取包络（min lo, max hi），序为逐界包含。
Lattice<Iv> ivLattice();

// 区间文本：[1,3]、[1,+inf]、bottom。
std::string ivText(const Iv &v);

// 抽象环境：变量 → 区间；缺键按 ⊥。
using IvEnv = std::map<std::string, Iv>;

// 抽象求值：常量→[v,v]；input→全区间；加/减/乘按端点组合取包络；
// 除与未支持的运算保守取全区间。
Iv evalIv(const Expr *e, const IvEnv &env);

// 封顶轮数的朴素迭代轨迹：每轮记录"循环头"点（第一条 while 语句所在节点）
// 的完整环境，用于演示迭代序列如何一路变松而不收敛。
struct NaiveResult {
    bool converged = false;
    int rounds = 0;                       // 实际执行的轮数（含未收敛时的上限）
    std::vector<std::string> trace;       // 每轮循环头环境的文本
    int headNode = -1;                    // 循环头节点号（无循环时 -1）
};

NaiveResult runNaiveInterval(const Cfg &cfg, const ProgramA &program,
                             int maxRounds);

}  // namespace tip
