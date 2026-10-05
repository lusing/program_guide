// file: src/dom.cpp
// 第 40 章配套：支配者实现。
#include "dom.hpp"

#include <functional>

namespace tip {

std::vector<std::set<int>> predsOf(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    std::vector<std::set<int>> preds(n);
    for (size_t q = 0; q < n; ++q)
        for (int s : adj[q]) preds[s].insert(static_cast<int>(q));
    return preds;
}

DomInfo dominators(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    DomInfo di;
    // 初值：入口只含自己，其余从全集出发（“人人可能支配”，逐步证伪）。
    std::set<int> all;
    for (size_t k = 0; k < n; ++k) all.insert(static_cast<int>(k));
    di.dom.assign(n, all);
    if (n > 0) di.dom[0] = {0};
    auto preds = predsOf(adj);
    bool changed = true;
    while (changed) {
        changed = false;
        ++di.sweeps;
        for (size_t b = 1; b < n; ++b) {
            std::set<int> acc = all;
            bool hasPred = false;
            for (int p : preds[b]) {
                std::set<int> keep;
                for (int x : acc)
                    if (di.dom[p].count(x)) keep.insert(x);
                acc = keep;
                hasPred = true;
            }
            acc.insert(static_cast<int>(b));
            if (!hasPred) acc = {static_cast<int>(b)};   // 不可达块：只支配自己
            if (acc != di.dom[b]) {
                di.dom[b] = acc;
                changed = true;
            }
        }
    }
    // idom：b 的严格支配者中，支配集最大（最靠近 b）的那个。
    di.idom.assign(n, -1);
    for (size_t b = 1; b < n; ++b) {
        int best = -1;
        size_t bestSize = 0;
        for (int d : di.dom[b]) {
            if (d == static_cast<int>(b)) continue;
            if (di.dom[d].size() >= bestSize) {
                bestSize = di.dom[d].size();
                best = d;
            }
        }
        di.idom[b] = best;
    }
    // 支配树
    di.children.assign(n, {});
    for (size_t b = 1; b < n; ++b)
        if (di.idom[b] >= 0) di.children[di.idom[b]].push_back(static_cast<int>(b));
    return di;
}

bool domTreeCheck(const DomInfo &di) {
    size_t n = di.dom.size();
    // 由树推导支配集：dom'(b) = 路径上祖先 ∪ {b}
    std::vector<std::set<int>> fromTree(n);
    for (size_t b = 0; b < n; ++b) {
        std::set<int> s = {static_cast<int>(b)};
        int cur = di.idom[b];
        while (cur >= 0) {
            s.insert(cur);
            cur = di.idom[cur];
        }
        fromTree[b] = s;
    }
    for (size_t b = 0; b < n; ++b)
        if (fromTree[b] != di.dom[b]) return false;
    return true;
}

// ---------- 稀疏集（鲸书附录 B.2.3） ----------

SparseSet::SparseSet(int universe) : sparse_(universe, 0), dense_(universe, 0) {}

void SparseSet::clear() { next_ = 0; }   // O(1)：数组不碰，旧数据靠互指校验失效

bool SparseSet::insert(int i) {
    if (contains(i)) return false;
    sparse_[i] = next_;
    dense_[next_++] = i;
    return true;
}

bool SparseSet::contains(int i) const {
    return i >= 0 && i < static_cast<int>(sparse_.size()) &&
           sparse_[i] >= 0 && sparse_[i] < next_ && dense_[sparse_[i]] == i;
}

std::vector<int> SparseSet::items() const {
    return std::vector<int>(dense_.begin(), dense_.begin() + next_);
}

// ---------- CHK 快支配（鲸书 §9.5.2） ----------

FastDomResult fastDominators(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    FastDomResult fr;
    if (n == 0) return fr;
    // 1) RPO：DFS 后序的逆（visited 用稀疏集——clear 后可整批复用）
    SparseSet visited(static_cast<int>(n));
    std::vector<int> postorder;
    std::function<void(int)> dfs = [&](int u) {
        visited.insert(u);
        for (int s : adj[u])
            if (!visited.contains(s)) dfs(s);
        postorder.push_back(u);
    };
    dfs(0);
    std::vector<int> rpo(postorder.rbegin(), postorder.rend());
    std::vector<int> rpoNo(n, -1);
    for (size_t i = 0; i < rpo.size(); ++i) rpoNo[rpo[i]] = static_cast<int>(i);
    // 2) idom 迭代：交 = 沿 idom 链上行到 RPO 号相等的公共节点
    auto preds = predsOf(adj);
    std::vector<int> idom(n, -1);
    idom[0] = 0;
    auto intersect = [&](int b1, int b2) {
        int f1 = b1, f2 = b2;
        while (f1 != f2) {
            while (rpoNo[f1] > rpoNo[f2]) f1 = idom[f1];
            while (rpoNo[f2] > rpoNo[f1]) f2 = idom[f2];
        }
        return f1;
    };
    int passes = 0;
    for (bool changed = true; changed;) {
        changed = false;
        ++passes;
        for (int b : rpo) {
            if (b == 0) continue;
            int newIdom = -1;
            for (int p : preds[b]) {
                if (idom[p] < 0) continue;   // 前驱未编号（不可达/未处理）
                newIdom = (newIdom < 0) ? p : intersect(p, newIdom);
            }
            if (newIdom >= 0 && idom[b] != newIdom) {
                idom[b] = newIdom;
                changed = true;
            }
        }
    }
    // 3) 组装 DomInfo：支配集由 idom 链读出（树到集合）
    DomInfo &di = fr.di;
    di.idom = idom;
    di.sweeps = passes;
    di.dom.assign(n, {});
    for (size_t b = 0; b < n; ++b) {
        if (idom[b] < 0) {   // 入口或不可达：只支配自己
            di.dom[b] = {static_cast<int>(b)};
            continue;
        }
        std::set<int> s = {static_cast<int>(b)};
        int cur = idom[b];
        while (cur >= 0 && cur != static_cast<int>(b)) {
            s.insert(cur);
            cur = (cur == 0) ? -1 : idom[cur];
        }
        di.dom[b] = s;
    }
    di.children.assign(n, {});
    for (size_t b = 1; b < n; ++b)
        if (idom[b] > 0) di.children[idom[b]].push_back(static_cast<int>(b));
        else if (idom[b] == 0 && b != 0) di.children[0].push_back(static_cast<int>(b));
    fr.passes = passes;
    return fr;
}

}  // namespace tip
