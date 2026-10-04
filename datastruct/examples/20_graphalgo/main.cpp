#include <cassert>
#include <cmath>
#include <cstddef>
#include <print>
#include <utility>
#include <vector>

#include "critical_path.hpp"
#include "mst.hpp"
#include "shortest_path.hpp"

// 20 图算法：Dijkstra / Floyd / Prim / Kruskal / AOE 关键路径

namespace {

bool close(double a, double b) {
    return std::abs(a - b) < 1.0e-9;
}

}  // namespace

int main() {
    // ═══ 固定无向加权图（5 顶点，6 条边）═══════════════════════
    ds::AdjMatrix gm(5, false);
    ds::AdjList gl(5, false);
    const std::pair<std::pair<int, int>, int> edges[] = {
        {{0, 1}, 4}, {{0, 2}, 1}, {{2, 1}, 2},
        {{1, 3}, 1}, {{2, 3}, 5}, {{3, 4}, 3},
    };
    for (const auto& [uv, w] : edges) {
        gm.add_edge(uv.first, uv.second, w);
        gl.add_edge(uv.first, uv.second, w);
    }

    // ═══ Dijkstra 单源最短路 ═══
    const std::vector<double> dv = ds::dijkstra(gl, 0);
    const double expected_dv[] = {0, 3, 1, 4, 7};
    for (size_t i = 0; i < dv.size(); ++i) {
        assert(close(dv[i], expected_dv[i]));
    }
    std::println("Dijkstra(0) 距离：{} {} {} {} {}",
                 dv[0], dv[1], dv[2], dv[3], dv[4]);

    // ═══ Floyd 全源最短路（不可达打印 -1）═══
    const ds::DistMatrix fm = ds::floyd(gm);
    const int expected_fm[][5] = {
        {0, 3, 1, 4, 7},
        {3, 0, 2, 1, 4},
        {1, 2, 0, 3, 6},
        {4, 1, 3, 0, 3},
        {7, 4, 6, 3, 0},
    };
    std::println("Floyd 全源距离矩阵（不可达打印 -1）：");
    for (int i = 0; i < 5; ++i) {
        for (int j = 0; j < 5; ++j) {
            assert(close(fm.at(i, j), expected_fm[i][j]));
            const int v = (fm.at(i, j) >= ds::kNoEdge / 2.0)
                              ? -1
                              : static_cast<int>(std::round(fm.at(i, j)));
            std::print("{:4}", v);
        }
        std::println("");
    }
    // 合同要点：对角线必为 0；第 0 行与 Dijkstra 一致
    for (int i = 0; i < 5; ++i) {
        assert(close(fm.at(i, i), 0.0));
        assert(close(fm.at(0, i), dv[static_cast<size_t>(i)]));
    }

    // ═══ Prim 与 Kruskal：同一张图，总权与边集都必须一致 ═══
    const ds::MstResult mp = ds::prim(gm, 0);
    const ds::MstResult mk = ds::kruskal(gm);
    assert(close(mp.total, 7.0));
    assert(close(mk.total, 7.0));
    assert(mp.edges == mk.edges);
    const std::pair<int, int> expected_mst[] = {
        {0, 2}, {1, 2}, {1, 3}, {3, 4},
    };
    for (size_t i = 0; i < mp.edges.size(); ++i) {
        assert(mp.edges[i] == expected_mst[i]);
    }
    std::println("Prim 最小生成树（总权 {}）：", mp.total);
    for (const auto& [u, v] : mp.edges) {
        std::println("  {} ── {}", u, v);
    }
    std::println("Kruskal 最小生成树（总权 {}）：边集与 Prim 完全相同", mk.total);

    // ═══ AOE 关键路径 ═══
    ds::AdjList aoe(4, true);
    aoe.add_edge(0, 1, 3);
    aoe.add_edge(0, 2, 2);
    aoe.add_edge(1, 3, 1);
    aoe.add_edge(2, 3, 3);
    const std::optional<ds::CritResult> cr = ds::critical_path(aoe);
    assert(cr.has_value());
    assert(cr->length == 5);
    const std::pair<int, int> expected_crit[] = {{0, 2}, {2, 3}};
    assert(cr->activities.size() == 2);
    for (size_t i = 0; i < cr->activities.size(); ++i) {
        assert(cr->activities[i] == expected_crit[i]);
    }
    std::println("AOE 总工期 {}；关键活动：", cr->length);
    for (const auto& [u, v] : cr->activities) {
        std::println("  {} → {}", u, v);
    }

    // ═══ 异常路径：有环 AOE 返回 nullopt；Dijkstra 遇负边抛异常 ═══
    ds::AdjList cyclic(2, true);
    cyclic.add_edge(0, 1, 1);
    cyclic.add_edge(1, 0, 1);
    assert(!ds::critical_path(cyclic).has_value());
    std::println("有环 AOE：不返回关键路径");

    ds::AdjList negative(2, true);
    negative.add_edge(0, 1, -1);
    bool threw = false;
    try {
        (void)ds::dijkstra(negative, 0);
    } catch (const std::invalid_argument&) {
        threw = true;
    }
    assert(threw);
    std::println("Dijkstra 遇负权边：抛异常");

    std::println("自检通过");
}
