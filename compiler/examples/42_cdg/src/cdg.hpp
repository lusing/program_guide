// file: src/cdg.hpp
// 第 42 章配套：后支配者、控制依赖图（CDG）、SSA 退出（虎书 §19.5–19.6）。
#ifndef TIP_CDG_HPP
#define TIP_CDG_HPP

#include <map>
#include <set>
#include <string>
#include <vector>

#include "tacgen.hpp"
#include "tacblocks.hpp"
#include "dom.hpp"
#include "ssa.hpp"

namespace tip {

// ---------- 后支配（pdom）：逆图上的支配 ----------
// pdom[b] = { d | 每条 b→exit 的路径都经过 d }。出口块的角色同入口。
// 实现：把邻接表反转（后继变前驱），出口块当“入口”，复用 33 章迭代。
// 出口块 = 无后继的块（多个则各算一份——教学程序单出口）。
DomInfo postDominators(const std::vector<std::vector<int>> &adj);

// ---------- 控制依赖图（CDG，Ferrante-Ottenstein-Warren） ----------
// 节点 n 控制依赖 c ⟺
//   (a) c 有后继 s 使 n ∈ pdom[s]（n 后支配某个 c 的后继），且
//   (b) n ∉ strict_pdom[c]（n 不严格后支配 c 本身）。
// 实现遍历每条边 c→s，从 s 沿 pdom 链上行到首个后支配 c 的节点止，
// 途经皆控制依赖 c（与支配边界的 CHK 同型！）。
struct CdgInfo {
    std::vector<std::set<int>> preds;   // 每块的 CDG 前驱（它依赖谁）
    std::vector<std::set<int>> succs;   // 每块的 CDG 后继（谁依赖它）
};

CdgInfo controlDependence(const std::vector<std::vector<int>> &adj, const DomInfo &pdom);

// ---------- SSA 退出（虎书 §19.6）：φ 拆成前驱块尾的复制 ----------
// 并行复制 → 串行：若有环（x↔y 互换），用临时断环。
// 返回非 SSA 的 TAC（跳转目标重贴），供解释器对账。
struct SsaBackResult {
    std::vector<Quad> code;
    int copies = 0;        // 拆出的复制数
    int swaps = 0;         // 用临时断环的环数
};

SsaBackResult ssaBack(const SsaProgram &ssa);

}  // namespace tip

#endif  // TIP_CDG_HPP
