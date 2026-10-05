// file: src/dfs.hpp
// 第 37 章配套之二：DFS 边分类、自然循环、可归约性。
// 边分类用发现/完成区间（白灰黑三色）：
//   树边（灰→白）、前向边（灰→黑 且先发现）、交叉边（灰→黑 且后发现）、
//   后退边（灰→灰，即指向仍在栈上的祖先）——回边的候选。
// 自然循环（回边 n→h）：{h} ∪ {能不经过 h 到达 n 的块}（反向可达）。
// 可归约：每个“后退方向”的边的目标都支配源（结构化控制流的图论化身）。
#ifndef TIP_DFS_HPP
#define TIP_DFS_HPP

#include <set>
#include <string>
#include <vector>

#include "dom.hpp"

namespace tip {

struct DfsInfo {
    std::vector<int> discover, finish;          // 时间戳
    std::vector<std::pair<int, int>> treeEdges; // (from, to)
    std::vector<std::tuple<int, int, std::string>> classified;   // (u,v,种类)
};

// succFrom: 块号 → 后继块号列表（由 blocks 预转换）。
DfsInfo dfsClassify(const std::vector<std::vector<int>> &adj);

struct NaturalLoop {
    int from, header;              // 回边 from→header
    std::set<int> body;
};

std::vector<NaturalLoop> naturalLoops(const std::vector<std::vector<int>> &adj,
                                      const DfsInfo &dfsi, const DomInfo &di);

// 可归约性：所有“指向祖先（retreating）”边的目标支配源。
bool reducible(const std::vector<std::vector<int>> &adj, const DfsInfo &dfsi,
               const DomInfo &di);

}  // namespace tip

#endif  // TIP_DFS_HPP
