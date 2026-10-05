// file: src/ra.cpp
// 第 52 章配套：活跃、干涉图、着色实现。
#include "ra.hpp"

#include <cctype>

namespace tip {

namespace {
bool isNumR(const std::string &s) {
    return !s.empty() && (isdigit(s[0]) || (s[0] == '-' && s.size() > 1));
}
bool isVarR(const std::string &s) { return !s.empty() && !isNumR(s); }
bool pureDefR(const Quad &q) {
    switch (q.op) {
    case TOp::Copy: case TOp::Add: case TOp::Sub: case TOp::Mul:
    case TOp::Div: case TOp::Gt: case TOp::Eq: case TOp::Input:
        return !q.dst.empty();
    default:
        return false;
    }
}
}  // namespace

LiveInfo liveness(const std::vector<Quad> &code, const std::vector<Block> &blocks) {
    size_t n = blocks.size();
    LiveInfo lv;
    lv.in.assign(n, {});
    lv.out.assign(n, {});
    auto adjOf = [&](size_t b) {
        std::vector<size_t> out;
        for (int s : blocks[b].succs)
            for (size_t k = 0; k < n; ++k)
                if (blocks[k].begin == s) out.push_back(k);
        return out;
    };
    for (bool ch = true; ch;) {
        ch = false;
        for (size_t b = n; b-- > 0;) {
            // in = use ∪ (out − def)；逐条后向扫块内
            std::set<std::string> s = lv.out[b];
            for (int i = blocks[b].end - 1; i >= blocks[b].begin; --i) {
                const Quad &q = code[i];
                if (pureDefR(q) && isVarR(q.dst)) s.erase(q.dst);
                if (isVarR(q.a)) s.insert(q.a);
                if (isVarR(q.b)) s.insert(q.b);
            }
            std::set<std::string> o;
            for (auto s2 : adjOf(b)) o.insert(lv.in[s2].begin(), lv.in[s2].end());
            if (s != lv.in[b] || o != lv.out[b]) {
                lv.in[b] = s;
                lv.out[b] = o;
                ch = true;
            }
        }
    }
    return lv;
}

InterfGraph buildInterf(const std::vector<Quad> &code, const std::vector<Block> &blocks,
                        const LiveInfo &lv) {
    InterfGraph g;
    auto addEdge = [&](const std::string &x, const std::string &y) {
        if (x == y || x.empty() || y.empty()) return;
        g.adj[x].insert(y);
        g.adj[y].insert(x);
        g.edges.insert({std::min(x, y), std::max(x, y)});
    };
    size_t n = blocks.size();
    for (size_t b = 0; b < n; ++b) {
        // 块内逐指令活跃（从 liveOut 倒推）
        std::set<std::string> live = lv.out[b];
        for (int i = blocks[b].end - 1; i >= blocks[b].begin; --i) {
            const Quad &q = code[i];
            // 定义 d 与“定义后仍活跃”的每个变量互相干涉；
            // Copy 的源例外（它们可以共寄存器——coalescing 的候选）
            if (pureDefR(q) && isVarR(q.dst)) {
                for (const auto &v : live) {
                    if (q.op == TOp::Copy && q.a == v) {
                        g.moveEdges.push_back({q.dst, v});
                        continue;
                    }
                    addEdge(q.dst, v);
                }
                live.erase(q.dst);
            }
            if (isVarR(q.a)) live.insert(q.a);
            if (isVarR(q.b)) live.insert(q.b);
        }
    }
    return g;
}

ColorResult colorGraph(const InterfGraph &g, int k) {
    ColorResult r;
    r.ok = false;
    std::set<std::string> nodes;
    for (const auto &kv : g.adj) nodes.insert(kv.first);

    // ---------- Briggs 安全合并（虎书 §11.2）----------
    // move 边 (a,b) 合并条件：合并后 a 的邻居中度 < k 的个数
    // 不少于 a、b 两邻居集（去掉对方）中度 < k 的个数——
    // 保证合并后的图仍可被 simplify 化简（保守不伤着色性）。
    std::map<std::string, std::set<std::string>> adj = g.adj;
    // deg 用 find 不用 operator[]——后者会给已删除的节点“复活”出空邻接表！
    auto deg = [&](const std::string &v) {
        auto it = adj.find(v);
        return it == adj.end() ? 0 : static_cast<int>(it->second.size());
    };
    for (int round = 0; round < 10; ++round) {   // 合并到不动点（上限保险）
        bool merged = false;
        for (const auto &pr : g.moveEdges) {
            const std::string &a = pr.first, &b = pr.second;
            if (deg(a) == 0 || deg(b) == 0) continue;
            if (!adj.count(a) || !adj.count(b)) continue;
            if (adj[a].count(b)) continue;   // 已干涉，不可合并
            // Briggs 准则
            std::set<std::string> unionN;
            unionN.insert(adj[a].begin(), adj[a].end());
            unionN.insert(adj[b].begin(), adj[b].end());
            unionN.erase(a);
            unionN.erase(b);
            int significant = 0;
            for (const auto &n : unionN)
                if (deg(n) >= k) ++significant;
            if (significant >= k) continue;   // 合并会产生度 ≥ k 的显著邻居过多
            // 执行合并：b 并入 a
            for (const auto &n : adj[b]) {
                if (n == a) continue;
                adj[n].erase(b);
                adj[n].insert(a);
                adj[a].insert(n);
            }
            adj.erase(b);
            ++r.coalesced;
            merged = true;
            break;   // 一轮一合并（教学清晰；工作表版整轮扫）
        }
        if (!merged) break;
    }

    fprintf(stderr, "[coalesce done] keys:");
    for (const auto &kv : adj) fprintf(stderr, " %s", kv.first.c_str());
    fprintf(stderr, "\n");
    // simplify：反复把度 < k 的点压栈（从图上摘下）；
    // 摘不掉且还有点 → 记溢出候选（度最大者）并继续。
    std::map<std::string, std::set<std::string>> adjMerge = adj;   // select 用合并图
    std::set<std::string> remaining;
    for (const auto &kv : adj) remaining.insert(kv.first);
    while (!remaining.empty()) {
        bool progressed = false;
        for (const auto &v : remaining) {
            if (static_cast<int>(adj[v].size()) < k) {
                r.stackOrder.push_back(v);
                for (const auto &u : adj[v]) adj[u].erase(v);
                adj.erase(v);
                remaining.erase(v);
                progressed = true;
                break;   // 一次摘一个，重扫（教学清晰优先）
            }
        }
        if (progressed) continue;
        // 无低度点：挑度最大者作溢出候选，强行摘除
        std::string best;
        int bestDeg = -1;
        for (const auto &v : remaining)
            if (static_cast<int>(adj[v].size()) > bestDeg) {
                bestDeg = static_cast<int>(adj[v].size());
                best = v;
            }
        r.spilled.push_back(best);
        for (const auto &u : adj[best]) adj[u].erase(best);
        adj.erase(best);
        remaining.erase(best);
    }
    // select：按栈序（后进先出）归还节点，挑邻居未占色
    for (auto it = r.stackOrder.rbegin(); it != r.stackOrder.rend(); ++it) {
        const std::string &v = *it;
        std::set<int> used;
        for (const auto &u : adjMerge.at(v)) {
            auto cit = r.color.find(u);
            if (cit != r.color.end()) used.insert(cit->second);
        }
        int c = 0;
        while (c < k && used.count(c)) ++c;
        if (c >= k) return r;   // 理论上 simplify 保证不会走到（除非溢出摘点后仍拥挤）
        r.color[v] = c;
    }
    for (const auto &s : r.spilled) r.color.erase(s);
    r.ok = r.spilled.empty();
    return r;
}

bool colorValid(const InterfGraph &g, const std::map<std::string, int> &color, int k) {
    // 已着色子图上相邻必异色；端点被溢出（无色）的边免责——溢出正是绕行它的手段。
    for (const auto &e : g.edges) {
        auto a = color.find(e.first), b = color.find(e.second);
        if (a == color.end() || b == color.end()) continue;
        if (a->second == b->second) return false;
    }
    for (const auto &kv : color)
        if (kv.second < 0 || kv.second >= k) return false;
    return true;
}

}  // namespace tip
