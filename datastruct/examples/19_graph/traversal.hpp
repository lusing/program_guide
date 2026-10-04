#ifndef DS_TRAVERSAL_HPP
#define DS_TRAVERSAL_HPP

#include <cstddef>
#include <queue>
#include <vector>

namespace ds {

// 广度优先搜索：从 s 出发，按"先近后远"逐层访问，返回访问次序。
// Graph 可以是 AdjMatrix 或 AdjList：两者都提供 n() 与按邻点升序的
// neighbors(v)（矩阵返回 vector<pair>，表返回 span<const Edge>），
// 结构化绑定统一处理。
template <class Graph>
std::vector<int> bfs(const Graph& g, int s) {
    const int n = g.n();
    std::vector<char> visited(static_cast<size_t>(n), false);
    std::vector<int> order;
    order.reserve(n);
    std::queue<int> q;
    visited[static_cast<size_t>(s)] = true;
    q.push(s);
    while (!q.empty()) {
        const int v = q.front();
        q.pop();
        order.push_back(v);
        for (const auto& [u, w] : g.neighbors(v)) {
            (void)w;
            if (!visited[static_cast<size_t>(u)]) {
                visited[static_cast<size_t>(u)] = true;
                q.push(u);
            }
        }
    }
    return order;
}

// 深度优先搜索：沿一条路走到底再回退。递归实现，访问次序与"调用
// 首次到达顶点"的时刻一致；邻点升序由表示层保证。
template <class Graph>
std::vector<int> dfs(const Graph& g, int s) {
    std::vector<char> visited(static_cast<size_t>(g.n()), false);
    std::vector<int> order;
    auto visit = [&](auto&& self, int v) -> void {
        visited[static_cast<size_t>(v)] = true;
        order.push_back(v);
        for (const auto& [u, w] : g.neighbors(v)) {
            (void)w;
            if (!visited[static_cast<size_t>(u)]) {
                self(self, u);
            }
        }
    };
    visit(visit, s);
    return order;
}

}  // namespace ds

#endif  // DS_TRAVERSAL_HPP
