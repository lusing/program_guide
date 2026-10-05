// file: src/ssa.hpp
// 第 34 章配套：支配边界（CHK）、φ 插入、支配树改名——SSA 构造全套。
#ifndef TIP_SSA_HPP
#define TIP_SSA_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "dom.hpp"

namespace tip {

// ---------- 支配边界（Cooper–Harvey–Kennedy） ----------
// DF[b] = { c | b 支配 c 的某个前驱，但 b 不严格支配 c }。
// 直觉：“b 的影响沿支配树下行，DF 是它‘管不到’却‘够得着’的汇合点”。
std::vector<std::set<int>> dominanceFrontiers(const std::vector<std::vector<int>> &adj,
                                              const DomInfo &di,
                                              const std::vector<std::set<int>> &preds);

// ---------- SSA ----------
struct SsaInst {
    TOp op = TOp::Copy;
    std::string dst, a, b;
    int target = -1;                    // 跳转目标 = 块号
    std::vector<std::string> phiArgs;   // φ 专用：按前驱次序的实参
};

struct SsaBlock {
    std::vector<SsaInst> body;          // φ 在最前
};

struct SsaProgram {
    std::vector<SsaBlock> blocks;
    std::vector<std::vector<int>> preds;   // 每块前驱（块号，定序）
};

// 构造：φ 插入（iterated DF 的不动点）+ 支配树先序改名（版本栈）。
// 单定值自检：每个 SSA 名字恰好定义一次（返回 false 即违例）。
SsaProgram buildSsa(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                    bool &singleDefOk);

std::string show(const SsaInst &q);

// ---------- SSA 解释器（对账证人） ----------
std::vector<int> ssaRun(const SsaProgram &p);

}  // namespace tip

#endif  // TIP_SSA_HPP
