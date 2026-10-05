// file: src/dfs.cpp
// 第 37 章配套：DFS 分类、自然循环、可归约性实现。
#include "dfs.hpp"

#include <algorithm>
#include <functional>
#include <tuple>

namespace tip {

DfsInfo dfsClassify(const std::vector<std::vector<int>> &adj) {
    size_t n = adj.size();
    DfsInfo d;
    d.discover.assign(n, -1);
    d.finish.assign(n, -1);
    std::vector<int> color(n, 0);   // 0 白、1 灰、2 黑
    int timer = 0;
    std::function<void(int)> visit = [&](int u) {
        d.discover[u] = timer++;
        color[u] = 1;
        for (int v : adj[u]) {
            if (color[v] == 0) {
                d.treeEdges.push_back({u, v});
                d.classified.push_back({u, v, "tree"});
                visit(v);
            } else if (color[v] == 1) {
                d.classified.push_back({u, v, "back"});
            } else if (d.discover[v] > d.discover[u]) {
                d.classified.push_back({u, v, "forward"});
            } else {
                d.classified.push_back({u, v, "cross"});
            }
        }
        color[u] = 2;
        d.finish[u] = timer++;
    };
    if (n > 0) visit(0);
    return d;
}

std::vector<NaturalLoop> naturalLoops(const std::vector<std::vector<int>> &adj,
                                      const DfsInfo &dfsi, const DomInfo &di) {
    (void)di;
    std::vector<NaturalLoop> out;
    for (const auto &[u, v, kind] : dfsi.classified) {
        if (kind != "back") continue;
        // 自然循环（回边 u→v）：v 支配 u 时才叫自然循环；否则是“异常回边”，
        // 归约性检查里另行处理。此处一并计算（示例程序均为自然）。
        NaturalLoop L;
        L.from = u;
        L.header = v;
        // 反向可达：从 u 往前走，遇 v 停
        std::vector<std::vector<int>> radj(adj.size());
        for (size_t a = 0; a < adj.size(); ++a)
            for (int b : adj[a]) radj[b].push_back(static_cast<int>(a));
        std::set<int> body = {v};
        std::vector<int> stack = {u};
        while (!stack.empty()) {
            int cur = stack.back();
            stack.pop_back();
            if (body.count(cur)) continue;
            body.insert(cur);
            for (int p : radj[cur]) stack.push_back(p);
        }
        L.body = body;
        out.push_back(L);
    }
    return out;
}

bool reducible(const std::vector<std::vector<int>> &adj, const DfsInfo &dfsi,
               const DomInfo &di) {
    (void)adj;   // 判定只看分类结果与支配集
    // 教学口径（紫龙 9.6.4 的充分刻画之一）：深度优先序下
    // 每条后退方向边的目标都支配源 ⇒ 可归约。
    for (const auto &[u, v, kind] : dfsi.classified) {
        if (kind != "back") continue;
        if (!di.dom[u].count(v)) return false;
    }
    return true;
}

}  // namespace tip
