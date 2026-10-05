// file: src/dom.hpp
// 第 33 章配套之一：支配者（dominators）与支配树。
// dom[b] = { d | 每条 entry→b 的路径都经过 d }——
// 迭代方程：dom[entry]={entry}；dom[b]={b} ∪ ∩ dom[pred]。
// 这是“从全集出发、单调收缩”的不动点（与 may 分析方向相反的镜像）。
#ifndef TIP_DOM_HPP
#define TIP_DOM_HPP

#include <map>
#include <set>
#include <vector>


namespace tip {

struct DomInfo {
    std::vector<std::set<int>> dom;      // 每块（块号）的支配集
    std::vector<int> idom;               // 直接支配者（-1 = 无/入口）
    std::vector<std::vector<int>> children;   // 支配树孩子表
};

// 前驱表（邻接表反推）。
std::vector<std::set<int>> predsOf(const std::vector<std::vector<int>> &adj);

DomInfo dominators(const std::vector<std::vector<int>> &adj);

// 自检：由支配树推导的支配集 == 迭代解（idom 唯一性的机器验证）。
bool domTreeCheck(const DomInfo &di);

}  // namespace tip

#endif  // TIP_DOM_HPP
