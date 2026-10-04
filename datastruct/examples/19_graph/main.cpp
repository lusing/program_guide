#include <array>
#include <cassert>
#include <print>
#include <string_view>
#include <utility>
#include <vector>

#include "adj_list.hpp"
#include "adj_matrix.hpp"
#include "topo.hpp"
#include "traversal.hpp"

// 19 图：固定无向图的表示与遍历、DAG 拓扑排序、有环图检测

namespace {

// 固定 7 顶点无向图（9 条边）：
// 0-1, 0-2, 0-6, 1-3, 2-3, 2-5, 3-4, 4-5, 5-6
constexpr std::array<std::pair<int, int>, 9> kEdges{{
    {0, 1}, {0, 2}, {0, 6}, {1, 3}, {2, 3},
    {2, 5}, {3, 4}, {4, 5}, {5, 6},
}};

void print_seq(std::string_view tag, const std::vector<int>& seq) {
    std::print("{}：", tag);
    for (size_t i = 0; i < seq.size(); ++i) {
        std::print("{}{}", seq[i], i + 1 == seq.size() ? '\n' : ' ');
    }
}

}  // namespace

int main() {
    // ═══ 两种表示装同一张图：边数一致、逐边 has_edge 一致 ═══
    ds::AdjMatrix gm(7, false);
    ds::AdjList gl(7, false);
    for (auto [u, v] : kEdges) {
        gm.add_edge(u, v);
        gl.add_edge(u, v);
    }
    assert(gm.edge_count() == 9);
    assert(gl.edge_count() == 9);
    for (int u = 0; u < 7; ++u) {
        for (int v = 0; v < 7; ++v) {
            assert(gm.has_edge(u, v) == gl.has_edge(u, v));
        }
    }
    std::println("固定图：7 顶点、9 边；邻接矩阵与邻接表的边集完全一致");

    // ═══ BFS / DFS：两种表示给出相同顺序 ═══
    const std::vector<int> bfs_m = ds::bfs(gm, 0);
    const std::vector<int> bfs_l = ds::bfs(gl, 0);
    const std::vector<int> dfs_m = ds::dfs(gm, 0);
    const std::vector<int> dfs_l = ds::dfs(gl, 0);
    const std::vector<int> expected_bfs{0, 1, 2, 6, 3, 5, 4};
    const std::vector<int> expected_dfs{0, 1, 3, 2, 5, 4, 6};
    assert(bfs_m == expected_bfs);
    assert(bfs_l == expected_bfs);
    assert(dfs_m == expected_dfs);
    assert(dfs_l == expected_dfs);
    print_seq("BFS(0)", bfs_m);
    print_seq("DFS(0)", dfs_m);

    // ═══ DAG 拓扑排序：最小零入度优先，唯一解 ═══
    ds::AdjList dag(7, true);
    for (auto [u, v] : std::to_array<std::pair<int, int>>({
             {0, 1}, {0, 2}, {1, 3}, {2, 3},
             {2, 4}, {3, 5}, {4, 5}, {5, 6},
         })) {
        dag.add_edge(u, v);
    }
    const auto topo = ds::topo_sort(dag);
    assert(topo.has_value());
    const std::vector<int> expected_topo{0, 1, 2, 3, 4, 5, 6};
    assert(*topo == expected_topo);
    print_seq("拓扑排序", *topo);

    // ═══ 有环图（顶点 3 孤立）：拓扑排序返回 nullopt ═══
    ds::AdjList cyclic(4, true);
    cyclic.add_edge(0, 1);
    cyclic.add_edge(1, 2);
    cyclic.add_edge(2, 0);
    assert(!ds::topo_sort(cyclic).has_value());
    std::println("有环图：拓扑排序返回 nullopt（检测到环）");

    std::println("自检通过");
}
