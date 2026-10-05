// file: src/main.cpp
// 第 69 章驱动（无参运行，走"简单程序"对账协议）：
//   CFG 频度 → 热路径链构造（流水+链表+优先级）→ 链布局 → 顺直/taken 度量
//   → 调用图贪心聚簇（流水+最终序）→ 加权距离度量 → 四断言。
#include "place.hpp"

#include <iostream>
#include <map>

int main() {
    // ---------- 块放置 ----------
    // 六块 CFG：入口频度 10；分支 7/3；B1 再分支 5/2。
    const int nBlocks = 6;
    std::vector<tip::CfgEdge> cfg = {
        {0, 1, 7}, {0, 2, 3}, {1, 3, 5}, {1, 2, 2}, {2, 4, 3}, {3, 5, 5}, {4, 5, 3},
    };
    std::cout << "== 热路径链构造 ==\n";
    tip::ChainPlan plan = tip::buildHotChains(nBlocks, cfg);
    for (const auto &s : plan.steps) std::cout << "  " << s << "\n";
    std::cout << "  链集合:";
    for (size_t i = 0; i < plan.chains.size(); ++i) {
        std::cout << " (";
        for (size_t k = 0; k < plan.chains[i].size(); ++k)
            std::cout << (k ? "," : "") << "B" << plan.chains[i][k];
        std::cout << ")p" << plan.priority[i];
    }
    std::cout << "\n";

    std::cout << "== 布局 ==\n";
    std::cout << "  基线（块号序）:";
    std::vector<int> baseline;
    for (int b = 0; b < nBlocks; ++b) baseline.push_back(b);
    for (int b : baseline) std::cout << " B" << b;
    tip::LayoutMetric mb = tip::measure(baseline, cfg);
    std::cout << "  顺直频度=" << mb.fallFreq << " taken频度=" << mb.takenFreq << "\n";
    std::cout << "  链布局:";
    for (int b : plan.layout) std::cout << " B" << b;
    tip::LayoutMetric ml = tip::measure(plan.layout, cfg);
    std::cout << "  顺直频度=" << ml.fallFreq << " taken频度=" << ml.takenFreq << "\n";

    // ---------- 过程放置 ----------
    // 鲸书 Figure 8.22 的调用图：七个过程、八条加权边。
    // 初始序故意打乱（≈源码声明序，与调用热度无关——真实二进制的常态）。
    std::vector<std::string> procs = {"P0", "P3", "P6", "P1", "P4", "P2", "P5"};
    std::vector<tip::CallEdge> calls = {
        {"P0", "P1", 10}, {"P0", "P5", 2}, {"P1", "P2", 20}, {"P1", "P3", 10},
        {"P1", "P4", 10}, {"P1", "P5", 10}, {"P5", "P4", 52}, {"P5", "P6", 104},
    };
    std::cout << "== 过程贪心聚簇 ==\n";
    tip::ProcPlan pp = tip::placeProcedures(procs, calls);
    for (const auto &s : pp.steps) std::cout << "  " << s << "\n";
    std::cout << "  基线（原序）:";
    for (const auto &p : procs) std::cout << " " << p;
    tip::ProcMetric pb = tip::measureProcs(procs, calls);
    std::cout << "  加权距离=" << pb.weightedDist
              << " 相邻边权=" << pb.adjacentWeight << "\n";
    std::cout << "  聚簇序:";
    for (const auto &p : pp.order) std::cout << " " << p;
    tip::ProcMetric pm = tip::measureProcs(pp.order, calls);
    std::cout << "  加权距离=" << pm.weightedDist
              << " 相邻边权=" << pm.adjacentWeight << "\n";

    // ---------- 断言 ----------
    std::cout << "== 对账 ==\n";
    bool ok1 = ml.takenFreq < mb.takenFreq && ml.fallFreq > mb.fallFreq;
    // 窗口邻近度（|距离|≤3 记权，近似"同一组缓存行"）：贪心优化的是热簇同居，
    // 不是全图线性距离——线性距离会惩罚冷被调者的合理流放（见正文）。
    auto windowWeight = [&](const std::vector<std::string> &order) {
        std::map<std::string, int> q;
        for (size_t i = 0; i < order.size(); ++i) q[order[i]] = static_cast<int>(i);
        int w = 0;
        for (const auto &e : calls)
            if (std::abs(q[e.from] - q[e.to]) <= 3) w += e.weight;
        return w;
    };
    int winBefore = windowWeight(procs);
    int winAfter = windowWeight(pp.order);
    std::cout << "  窗口邻近度（|距离|≤3 记权）: " << winBefore << " → " << winAfter << "\n";
    bool ok2 = pm.weightedDist < pb.weightedDist && winAfter > winBefore;
    // 最热的调用边 (P5,P6,104) 在聚簇序里相邻
    std::map<std::string, int> pos;
    for (size_t i = 0; i < pp.order.size(); ++i) pos[pp.order[i]] = static_cast<int>(i);
    bool ok3 = pos.count("P5") && pos.count("P6") && std::abs(pos["P5"] - pos["P6"]) == 1;
    bool ok4 = static_cast<int>(plan.layout.size()) == nBlocks &&
               pp.order.size() == procs.size() && pp.order.front() == "P0";
    std::cout << "  链布局 taken 下降且顺直上升: " << (ok1 ? "yes" : "NO") << "\n";
    std::cout << "  窗口邻近度不降: " << (ok2 ? "yes" : "NO") << "\n";
    std::cout << "  最热调用对 (P5,P6) 相邻: " << (ok3 ? "yes" : "NO") << "\n";
    std::cout << "  布局完备且入口打头: " << (ok4 ? "yes" : "NO") << "\n";
    return (ok1 && ok2 && ok3 && ok4) ? 0 : 1;
}
