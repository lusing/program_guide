// file: src/place.cpp
// 第 69 章配套：热路径链构造、链布局、过程贪心聚簇的实现
// （鲸书 §8.6.2 Figure 8.16/8.17 + §8.7.2）。
#include "place.hpp"

#include <algorithm>
#include <map>

namespace tip {

ChainPlan buildHotChains(int nBlocks, const std::vector<CfgEdge> &edges) {
    ChainPlan plan;
    // 链用独立记录（块 → 链下标），绝不让"链内容"与"重定向"互相踩——
    // 教训：引用式 chainOfBlock 在重定向时会覆盖待拼接的尾链，自食其尾。
    struct Chain {
        std::vector<int> blocks;
        int prio;
        bool alive = true;
    };
    std::vector<Chain> chains;
    std::vector<int> idxOf(nBlocks, -1);
    for (int b = 0; b < nBlocks; ++b) {
        chains.push_back({{b}, static_cast<int>(edges.size())});
        idxOf[b] = static_cast<int>(chains.size()) - 1;
    }
    // 边按频度降序（平局按 (from,to) 字典序）扫描
    std::vector<CfgEdge> sorted = edges;
    std::sort(sorted.begin(), sorted.end(), [](const CfgEdge &a, const CfgEdge &b) {
        if (a.freq != b.freq) return a.freq > b.freq;
        if (a.from != b.from) return a.from < b.from;
        return a.to < b.to;
    });
    int P = 0;
    for (const auto &e : sorted) {
        int ia = idxOf[e.from], ib = idxOf[e.to];
        if (ia == ib) continue;
        // x 必是所在链的尾、y 必是所在链的头，才可拼接（鲸书 Figure 8.16）
        if (chains[ia].blocks.back() != e.from || chains[ib].blocks.front() != e.to) continue;
        // 合并：b 链整段接到 a 链尾；成员重指向 a
        chains[ia].blocks.insert(chains[ia].blocks.end(),
                                 chains[ib].blocks.begin(), chains[ib].blocks.end());
        for (int blk : chains[ib].blocks) idxOf[blk] = ia;
        chains[ib].blocks.clear();
        chains[ib].alive = false;
        int newPrio = std::min({chains[ia].prio, chains[ib].prio, P++});
        chains[ia].prio = newPrio;
        plan.steps.push_back("边 B" + std::to_string(e.from) + "→B" + std::to_string(e.to) +
                             "（频度 " + std::to_string(e.freq) + "）：合并成链，优先级 " +
                             std::to_string(newPrio));
    }
    // 收链（活链，代表 = 首块）
    for (const auto &c : chains) {
        if (!c.alive || c.blocks.empty()) continue;
        plan.chains.push_back(c.blocks);
        plan.priority.push_back(c.prio);
    }
    // 布局（鲸书 Figure 8.17）：入口链起步，放完一条链把其出边目标所在链
    // 按优先级（小 = 热）入工作表；循环到空。
    std::vector<bool> placed(nBlocks, false);
    std::vector<std::pair<int, int>> work;   // (优先级, 链下标)
    std::vector<bool> queued(chains.size(), false);
    auto pushChain = [&](int ci) {
        if (queued[ci]) return;
        queued[ci] = true;
        work.push_back({chains[ci].prio, ci});
    };
    pushChain(idxOf[0]);
    while (!work.empty()) {
        std::sort(work.begin(), work.end());
        int ci = work.front().second;
        work.erase(work.begin());
        for (int blk : chains[ci].blocks) {
            if (placed[blk]) continue;
            placed[blk] = true;
            plan.layout.push_back(blk);
        }
        for (int blk : chains[ci].blocks)
            for (const auto &e : edges)
                if (e.from == blk && !placed[e.to]) pushChain(idxOf[e.to]);
    }
    for (int b = 0; b < nBlocks; ++b)
        if (!placed[b]) plan.layout.push_back(b);   // 保险：孤立块收尾
    return plan;
}

LayoutMetric measure(const std::vector<int> &layout, const std::vector<CfgEdge> &edges) {
    std::map<int, int> pos;
    for (size_t i = 0; i < layout.size(); ++i) pos[layout[i]] = static_cast<int>(i);
    LayoutMetric m;
    for (const auto &e : edges) {
        if (pos[e.to] == pos[e.from] + 1) m.fallFreq += e.freq;
        else m.takenFreq += e.freq;
    }
    return m;
}

ProcPlan placeProcedures(const std::vector<std::string> &procs,
                         std::vector<CallEdge> edges) {
    ProcPlan plan;
    // 每个连通分量的代表与有序表
    std::map<std::string, std::string> repOf;
    std::map<std::string, std::vector<std::string>> list;
    for (const auto &p : procs) {
        repOf[p] = p;
        list[p] = {p};
    }
    auto key = [](const CallEdge &e) { return e.from + "\x01" + e.to; };
    for (bool progress = true; progress;) {
        progress = false;
        // 取最大权边（平局字典序）
        auto best = edges.end();
        for (auto it = edges.begin(); it != edges.end(); ++it) {
            if (it->from == it->to) continue;   // 自环不影响放置
            if (best == edges.end() || it->weight > best->weight ||
                (it->weight == best->weight && key(*it) < key(*best)))
                best = it;
        }
        if (best == edges.end()) break;
        std::string x = best->from, y = best->to;
        int w = best->weight;
        edges.erase(best);
        // list(y) 接到 list(x)
        std::string rx = repOf[x], ry = repOf[y];
        if (rx == ry) continue;
        for (const auto &p : list[ry]) repOf[p] = rx;
        list[rx].insert(list[rx].end(), list[ry].begin(), list[ry].end());
        list.erase(ry);
        plan.steps.push_back("边 " + x + "→" + y + "（权 " + std::to_string(w) +
                             "）：list(" + ry + ") 并入 list(" + rx + ")");
        progress = true;
        // ReSource：y 的出边改从 x 出发（同目标并权）
        for (auto it = edges.begin(); it != edges.end();) {
            if (it->from == ry) {
                CallEdge ne{rx, it->to, it->weight};
                auto f = std::find_if(edges.begin(), edges.end(),
                                      [&](const CallEdge &c) { return c.from == ne.from && c.to == ne.to; });
                if (f != edges.end()) {
                    f->weight += ne.weight;
                    it = edges.erase(it);
                } else {
                    *it = ne;
                    ++it;
                }
            } else {
                ++it;
            }
        }
        // ReTarget：指向 y 的边改指 x（同源并权）
        for (auto it = edges.begin(); it != edges.end();) {
            if (it->to == ry) {
                CallEdge ne{it->from, rx, it->weight};
                auto f = std::find_if(edges.begin(), edges.end(),
                                      [&](const CallEdge &c) { return c.from == ne.from && c.to == ne.to; });
                if (f != edges.end()) {
                    f->weight += ne.weight;
                    it = edges.erase(it);
                } else {
                    *it = ne;
                    ++it;
                }
            } else {
                ++it;
            }
        }
    }
    // 汇总：按代表出现序展平各链
    for (const auto &p : procs)
        if (list.count(repOf[p])) {
            for (const auto &q : list[repOf[p]]) plan.order.push_back(q);
            list.erase(repOf[p]);
        }
    return plan;
}

ProcMetric measureProcs(const std::vector<std::string> &order,
                        const std::vector<CallEdge> &edges) {
    std::map<std::string, int> pos;
    for (size_t i = 0; i < order.size(); ++i) pos[order[i]] = static_cast<int>(i);
    ProcMetric m;
    for (const auto &e : edges) {
        int d = std::abs(pos[e.from] - pos[e.to]);
        m.weightedDist += static_cast<long>(d) * e.weight;
        if (d == 1) m.adjacentWeight += e.weight;
    }
    return m;
}

}  // namespace tip
