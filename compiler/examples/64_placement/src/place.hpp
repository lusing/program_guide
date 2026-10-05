// file: src/place.hpp
// 第 64 章配套：代码放置——热路径链构造与过程贪心聚簇（鲸书 §8.6.2 + §8.7.2）。
#ifndef TIP_PLACE_HPP
#define TIP_PLACE_HPP

#include <string>
#include <vector>

namespace tip {

// ---------- 块放置：热路径链 ----------

struct CfgEdge {
    int from, to;
    int freq;   // 执行频度（profile 或静态估计）
};

struct ChainPlan {
    std::vector<std::vector<int>> chains;   // 每条链的块序
    std::vector<int> priority;              // 链的优先级（小 = 热）
    std::vector<int> layout;                // 最终线性布局
    std::vector<std::string> steps;         // 链构造流水（边→合并）
};

// 鲸书 Figure 8.16：按边频降序扫描，x 是某链尾且 y 是某链头才合并；
// 新链优先级 = min(两链优先级, P++)；退化链初始优先级 = |edges|。
ChainPlan buildHotChains(int nBlocks, const std::vector<CfgEdge> &edges);

// 布局度量：顺直（fall-through）边频度合计 / 非顺直（taken）边频度合计。
// 布局里 y 紧跟 x 之后即顺直。
struct LayoutMetric {
    int fallFreq = 0;
    int takenFreq = 0;
};
LayoutMetric measure(const std::vector<int> &layout, const std::vector<CfgEdge> &edges);

// ---------- 过程放置：调用图贪心聚簇 ----------

struct CallEdge {
    std::string from, to;
    int weight;   // 调用频度
};

struct ProcPlan {
    std::vector<std::string> order;          // 最终过程布局
    std::vector<std::string> steps;          // 每步合并流水
};

// 鲸书 §8.7.2：边权降序贪心；合并 (x,y) 时 list(y) 接到 list(x)，
// ReSource (y,z)→(x,z)、ReTarget (z,y)→(z,x)，同边并权。
ProcPlan placeProcedures(const std::vector<std::string> &procs,
                         std::vector<CallEdge> edges);

// 调用图度量：边权 × 布局距离 的加权和；相邻（距离 1）边权合计。
struct ProcMetric {
    long weightedDist = 0;
    int adjacentWeight = 0;
};
ProcMetric measureProcs(const std::vector<std::string> &order,
                        const std::vector<CallEdge> &edges);

}  // namespace tip

#endif  // TIP_PLACE_HPP
