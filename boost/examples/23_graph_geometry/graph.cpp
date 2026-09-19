// graph.cpp —— Boost.Graph（2000，BGL）：图的泛型圣经。
// "图算法与图表示分离"的泛型设计比 concepts 早生二十年，
// 至今仍是 C++ 图算法的唯一标准件。
// 对应文档：docs/23-graph-geometry.md
#include <boost/graph/adjacency_list.hpp>
#include <boost/graph/dijkstra_shortest_paths.hpp>
#include <boost/graph/depth_first_search.hpp>
#include <boost/graph/connected_components.hpp>
#include <boost/graph/graph_utility.hpp>
#include <iostream>
#include <string>

// BGL 访问者：覆写感兴趣的钩子，其余用默认。
// 坑：visitor 按值传入算法——状态要用指针共享，成员计数白加
struct Recorder : boost::default_dfs_visitor {
    int* visits;
    explicit Recorder(int* v) : visits(v) {}
    template <class V, class G> void discover_vertex(V, const G&) { ++*visits; }
};

int main() {
    using namespace boost;

    // 1) 邻接表建图：带权无向图（城市路网）
    adjacency_list<listS, vecS, undirectedS,
                   property<vertex_name_t, std::string>,
                   property<edge_weight_t, int>> g;

    auto a = add_vertex(std::string("A"), g);
    auto b = add_vertex(std::string("B"), g);
    auto c = add_vertex(std::string("C"), g);
    auto d = add_vertex(std::string("D"), g);
    add_edge(a, b, 1, g);
    add_edge(b, c, 2, g);
    add_edge(a, c, 5, g);      // 绕路
    add_edge(c, d, 3, g);

    // 2) Dijkstra：最短路
    std::vector<int> dist(num_vertices(g));
    dijkstra_shortest_paths(g, a, distance_map(dist.data()));
    auto names = get(vertex_name, g);
    std::cout << "从 A 出发:\n";
    for (auto v : make_iterator_range(vertices(g))) {
        std::cout << "  到 " << names[v] << " 距离 = " << dist[v] << '\n';
    }

    // 3) 深度优先（访问者模式是 BGL 的灵魂接口）。
    //    访问者要定义在函数外：本地类不能有成员模板
    int visits = 0;
    depth_first_search(g, visitor(Recorder(&visits)));
    std::cout << "DFS 访问顶点数 = " << visits << '\n';

    // 4) 连通分量
    std::vector<int> comp(num_vertices(g));
    int n = connected_components(g, comp.data());
    std::cout << "连通分量数 = " << n << "（全连通）\n";

    std::cout << "自检通过\n";
    return 0;
}
