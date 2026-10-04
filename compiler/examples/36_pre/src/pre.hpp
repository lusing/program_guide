// file: src/pre.hpp
// 第 36 章配套：部分冗余消除——六方程分析与教学版变换。
#ifndef TIP_PRE_HPP
#define TIP_PRE_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"

namespace tip {

using FValS = std::set<std::string>;

std::string exprKeyP(const Quad &q);

struct PreInfo {
    const std::vector<Quad> *code = nullptr;
    const std::vector<Block> *blocks = nullptr;
    std::vector<FValS> egen, ekill;
    std::vector<std::vector<int>> adj;
    std::vector<FValS> anticIn, anticOut;   // ① anticipated
    std::vector<FValS> availIn, availOut;   // ② available
    std::vector<FValS> earliest;            // ③
    std::vector<FValS> postIn, postOut;     // ④ postponable
    std::vector<FValS> usedIn, usedOut;     // ⑤ used
    std::vector<FValS> latest;              // ⑥
};

PreInfo preAnalyse(const std::vector<Quad> &code, const std::vector<Block> &blocks);

struct PreStats {
    int inserted = 0;   // 改写为 pe = e 的首计算位（含紧随复制）
    int replaced = 0;   // 改写为复制的重复计算位
};

std::pair<std::vector<Quad>, PreStats> preTransform(const std::vector<Quad> &code,
                                                    const std::vector<Block> &blocks,
                                                    const PreInfo &p);

}  // namespace tip

#endif  // TIP_PRE_HPP
