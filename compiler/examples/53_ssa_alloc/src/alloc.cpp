// file: src/alloc.cpp
// 第 53 章配套：两个局部分配器、SSA 干涉图、MCS/PEO、弦图与 Briggs 着色
// （鲸书 §13.3 + §13.5.2）。
#include "alloc.hpp"

#include <algorithm>
#include <cstdlib>

namespace tip {

// ---------- 局部分配 ----------

namespace {

// 块内 next-use：position i 处名字 v 的下一次使用下标（无则 -1）
std::map<std::pair<int, std::string>, int> nextUseOf(const std::vector<LocalInst> &block) {
    std::map<std::pair<int, std::string>, int> nu;
    std::map<std::string, int> pending;
    for (int i = static_cast<int>(block.size()) - 1; i >= 0; --i) {
        for (const auto &v : block[i].uses)
            nu[{i, v}] = pending.count(v) ? pending[v] : -1;
        if (!block[i].dst.empty()) pending[block[i].dst] = i;
        for (const auto &v : block[i].uses) pending[v] = i;   // 使用点也是"最近定义起点"
    }
    return nu;
}

}  // namespace

LocalReport topDownLocal(const std::vector<LocalInst> &block, int k) {
    LocalReport r;
    // 频率计数：一次定义 + 每次使用各记一票
    std::map<std::string, int> freq;
    for (const auto &inst : block) {
        if (!inst.dst.empty()) ++freq[inst.dst];
        for (const auto &v : inst.uses) ++freq[v];
    }
    std::vector<std::pair<int, std::string>> order;
    for (const auto &[v, c] : freq) order.push_back({c, v});
    std::sort(order.begin(), order.end(),
              [](auto &x, auto &y) { return x.first > y.first || (x.first == y.first && x.second < y.second); });
    std::set<std::string> resident;
    for (size_t i = 0; i < order.size() && static_cast<int>(i) < k; ++i) {
        resident.insert(order[i].second);
        r.resident.push_back(order[i].second);
    }
    // 访存账：内存值的每次使用 1 load、每次定义 1 store
    for (const auto &inst : block) {
        if (!inst.dst.empty() && !resident.count(inst.dst)) ++r.memoryTraffic;
        for (const auto &v : inst.uses)
            if (!resident.count(v)) ++r.memoryTraffic;
    }
    return r;
}

LocalReport bottomUpLocal(const std::vector<LocalInst> &block, int k) {
    LocalReport r;
    auto nu = nextUseOf(block);
    std::map<std::string, int> home;        // 名字 → 寄存器（-1 = 在内存）
    std::map<int, std::string> owner;       // 寄存器 → 名字
    std::map<int, bool> dirty;
    auto evict = [&](int reg) {             // 驱逐：脏则 store
        auto it = owner.find(reg);
        if (it == owner.end()) return;
        if (dirty[reg]) ++r.memoryTraffic;
        home[it->second] = -1;
        owner.erase(it);
        dirty[reg] = false;
    };
    auto ensure = [&](const std::string &v, int at, bool fromMemory) {
        if (home.count(v) && home[v] >= 0) return;
        int reg = -1;
        for (int i = 0; i < k; ++i)
            if (!owner.count(i)) { reg = i; break; }
        if (reg < 0) {
            // 驱逐下次使用最远的驻留者（Belady 同型；无下次使用者最先走）
            int bestReg = 0, bestDist = -2;
            for (const auto &[rg, name] : owner) {
                auto f = nu.find({at, name});
                int dist = (f == nu.end() || f->second < 0) ? 1 << 30 : f->second;
                if (dist > bestDist) { bestDist = dist; bestReg = rg; }
            }
            evict(bestReg);
            reg = bestReg;
        }
        if (fromMemory) ++r.memoryTraffic;  // 内存值装进寄存器才算 1 load；
        home[v] = reg;                      // 定义直接写寄存器，不产生访存
        owner[reg] = v;
        dirty[reg] = false;
    };
    for (int i = 0; i < static_cast<int>(block.size()); ++i) {
        const auto &inst = block[i];
        for (const auto &v : inst.uses) ensure(v, i, true);
        if (!inst.dst.empty()) {
            ensure(inst.dst, i, false);     // 定义占寄存器但不读内存
            dirty[home[inst.dst]] = true;
        }
    }
    for (const auto &[rg, name] : owner) r.resident.push_back(name);
    std::sort(r.resident.begin(), r.resident.end());
    return r;
}

// ---------- SSA 活跃与干涉 ----------

std::vector<std::set<std::string>> ssaLiveness(const std::vector<SsaBlockLite> &blocks) {
    size_t n = blocks.size();
    std::vector<std::set<std::string>> in(n), out(n);
    auto phiArgsFor = [&](int s, int pred) -> std::vector<std::string> {
        std::vector<std::string> args;
        for (const auto &inst : blocks[s].body) {
            if (!inst.isPhi) continue;
            size_t pos = 0;
            for (int p : blocks[s].preds) {
                if (p == pred) break;
                ++pos;
            }
            if (pos < inst.uses.size()) args.push_back(inst.uses[pos]);
        }
        return args;
    };
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            std::set<std::string> o;
            for (int s : blocks[b].succs) {
                o.insert(in[s].begin(), in[s].end());
                for (const auto &a : phiArgsFor(s, static_cast<int>(b))) o.insert(a);
            }
            std::set<std::string> i = o;
            for (auto it = blocks[b].body.rbegin(); it != blocks[b].body.rend(); ++it) {
                if (!it->dst.empty()) i.erase(it->dst);
                for (const auto &v : it->uses) i.insert(v);
            }
            if (i != in[b] || o != out[b]) { in[b] = i; out[b] = o; ch = true; }
        }
    }
    return out;
}

void Graph::addEdge(const std::string &x, const std::string &y) {
    if (x == y || x.empty() || y.empty()) return;
    nodes.insert(x);
    nodes.insert(y);
    edges.insert({std::min(x, y), std::max(x, y)});
    adj[x].insert(y);
    adj[y].insert(x);
}

Graph buildInterference(const std::vector<SsaBlockLite> &blocks) {
    Graph g;
    auto out = ssaLiveness(blocks);
    for (size_t b = 0; b < blocks.size(); ++b) {
        // 块内逐点活跃：从 liveOut 倒推
        std::set<std::string> live = out[b];
        for (auto it = blocks[b].body.rbegin(); it != blocks[b].body.rend(); ++it) {
            // def 与"定义点之后仍活跃"者连边；φ 目的不与自己的实参连边
            if (!it->dst.empty()) {
                for (const auto &v : live) {
                    if (it->isPhi) {
                        bool isArg = false;
                        for (const auto &a : it->uses) if (a == v) isArg = true;
                        if (isArg) continue;   // φ 与实参可共寄存器
                    }
                    g.addEdge(it->dst, v);
                }
                live.erase(it->dst);
            }
            for (const auto &v : it->uses) live.insert(v);
        }
    }
    for (const auto &b : blocks)
        for (const auto &inst : b.body) {
            if (!inst.dst.empty()) g.nodes.insert(inst.dst);
            for (const auto &v : inst.uses) g.nodes.insert(v);
        }
    return g;
}

// ---------- MCS / PEO / 着色 ----------

std::vector<std::string> mcsOrder(const Graph &g) {
    // 最大势搜索：反复取"与已编号集相邻最多"的节点编号；逆序为 PEO。
    std::map<std::string, int> weight;
    std::set<std::string> numbered;
    std::vector<std::string> order;
    for (size_t n = 0; n < g.nodes.size(); ++n) {
        std::string best;
        int bestW = -1;
        for (const auto &v : g.nodes) {
            if (numbered.count(v)) continue;
            if (weight[v] > bestW || (weight[v] == bestW && (best.empty() || v < best))) {
                bestW = weight[v];
                best = v;
            }
        }
        numbered.insert(best);
        order.push_back(best);
        for (const auto &u : g.adj.at(best)) ++weight[u];
    }
    return order;   // order 的逆序是 PEO
}

bool isPerfectElimination(const Graph &g, const std::vector<std::string> &order) {
    // order 即消除序：每个点的"靠后邻居"必须成团
    std::map<std::string, int> pos;
    for (size_t i = 0; i < order.size(); ++i) pos[order[i]] = static_cast<int>(i);
    for (size_t i = 0; i < order.size(); ++i) {
        std::vector<std::string> later;
        for (const auto &u : g.adj.at(order[i]))
            if (pos[u] > static_cast<int>(i)) later.push_back(u);
        for (size_t x = 0; x < later.size(); ++x)
            for (size_t y = x + 1; y < later.size(); ++y)
                if (!g.adj.at(later[x]).count(later[y])) return false;
    }
    return true;
}

std::map<std::string, int> chordalColor(const Graph &g, const std::vector<std::string> &peo) {
    std::map<std::string, int> color;
    for (const auto &v : peo) {
        std::set<int> used;
        for (const auto &u : g.adj.at(v)) {
            auto it = color.find(u);
            if (it != color.end()) used.insert(it->second);
        }
        int c = 0;
        while (used.count(c)) ++c;
        color[v] = c;
    }
    return color;
}

int peoCliqueNumber(const Graph &g, const std::vector<std::string> &peo) {
    std::map<std::string, int> pos;
    for (size_t i = 0; i < peo.size(); ++i) pos[peo[i]] = static_cast<int>(i);
    int omega = 1;
    for (size_t i = 0; i < peo.size(); ++i) {
        int later = 0;
        for (const auto &u : g.adj.at(peo[i]))
            if (pos[u] > static_cast<int>(i)) ++later;
        omega = std::max(omega, later + 1);
    }
    return omega;
}

std::map<std::string, int> briggsColor(const Graph &g, int k) {
    std::map<std::string, std::set<std::string>> adj;
    for (const auto &v : g.nodes) adj[v] = g.adj.count(v) ? g.adj.at(v) : std::set<std::string>{};
    std::vector<std::string> stack;
    std::set<std::string> remaining = g.nodes;
    while (!remaining.empty()) {
        std::string pick;
        for (const auto &v : remaining)
            if (static_cast<int>(adj[v].size()) < k) { pick = v; break; }
        if (pick.empty()) return {};   // 需要溢出：本示例不接受
        for (const auto &u : adj[pick]) adj[u].erase(pick);
        adj.erase(pick);
        stack.push_back(pick);
        remaining.erase(pick);
    }
    std::map<std::string, int> color;
    for (auto it = stack.rbegin(); it != stack.rend(); ++it) {
        std::set<int> used;
        for (const auto &u : g.adj.at(*it)) {
            auto cit = color.find(u);
            if (cit != color.end()) used.insert(cit->second);
        }
        int c = 0;
        while (c < k && used.count(c)) ++c;
        if (c >= k) return {};
        color[*it] = c;
    }
    return color;
}

bool coloringValid(const Graph &g, const std::map<std::string, int> &color, int k) {
    for (const auto &v : g.nodes) {
        auto it = color.find(v);
        if (it == color.end() || it->second < 0 || it->second >= k) return false;
    }
    for (const auto &e : g.edges) {
        auto a = color.find(e.first), b = color.find(e.second);
        if (a == color.end() || b == color.end() || a->second == b->second) return false;
    }
    return true;
}

}  // namespace tip
