// file: src/dom.hpp
// 第 35 章配套之一：支配者（dominators）与支配树。
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
    int sweeps = 0;                      // 全图扫描轮数（对照 CHK 用）
};

// 前驱表（邻接表反推）。
std::vector<std::set<int>> predsOf(const std::vector<std::vector<int>> &adj);

DomInfo dominators(const std::vector<std::vector<int>> &adj);

// 自检：由支配树推导的支配集 == 迭代解（idom 唯一性的机器验证）。
bool domTreeCheck(const DomInfo &di);

// ---------- 稀疏集（鲸书附录 B.2.3）----------
// dense/sparse 双数组 + 游标：clear 是 O(1)（游标归零，不必清数组）；
// 成员测试靠"双向互指"：0 ≤ sparse[i] < next 且 dense[sparse[i]] == i。
// 建在 |U| 已知的离线场景（编译器的节点全集恰是）；遍历 O(|S|) 而非 O(|U|)。
class SparseSet {
public:
    explicit SparseSet(int universe);
    void clear();
    bool insert(int i);
    bool contains(int i) const;
    std::vector<int> items() const;
    int size() const { return next_; }

private:
    std::vector<int> sparse_, dense_;
    int next_ = 0;
};

// ---------- CHK 快支配（鲸书 §9.5.2）----------
// 只存 idom（不存支配集），交运算 = 沿 idom 链上行到 RPO 号相同处
// （两链的公共后缀就是交集）；按 RPO 序扫描，通常 2~4 轮收敛。
struct FastDomResult {
    DomInfo di;
    int passes = 0;
};
FastDomResult fastDominators(const std::vector<std::vector<int>> &adj);

}  // namespace tip

#endif  // TIP_DOM_HPP
