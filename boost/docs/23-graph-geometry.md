# 23 · 图与几何：graph / property_map / geometry / polygon

> 对应示例：`examples/23_graph_geometry/`（4 个例程）

Boost 在"关系与空间"两个维度各有一个巨库：BGL（图，2000）与 Geometry（几何，2009），配一个抽象关节（PropertyMap）和一个领域特化（Polygon，曼哈顿几何）。

## 23.1 Boost.Graph（BGL，2000）：图算法的泛型圣经

BGL 的核心设计——**算法与表示分离**——比 C++20 concepts 早了二十年：算法写成对"顶点/边迭代器 + 属性映射"的模板，图怎么存（邻接表/邻接矩阵/压缩稀疏）由用户选。

```cpp
adjacency_list<listS, vecS, undirectedS,
               property<vertex_name_t, std::string>,
               property<edge_weight_t, int>> g;
dijkstra_shortest_paths(g, a, distance_map(dist.data()));   // 最短路全家
depth_first_search(g, visitor(Recorder(&visits)));          // 访问者钩子
connected_components(g, comp.data());
```

运行输出（`graph.cpp`）：

```text
从 A 出发:
  到 A 距离 = 0
  到 B 距离 = 1
  到 C 距离 = 3
  到 D 距离 = 6
DFS 访问顶点数 = 4
连通分量数 = 1（全连通）
自检通过
```

Dijkstra 正确绕开了 A→C 的 5 权直达边（A→B→C = 3）。算法库阵容是教科书级：最短路（dijkstra/bellman_ford/astar）、生成树（prim/kruskal）、拓扑排序、流（push_relabel）、匹配、团、平面性测试……⭐ C++ 图算法唯一成熟标准件。

> 实测坑两个：**访问者里的本地类不能有成员模板**（定义到函数外）；**visitor 按值传入算法**——在访问者里数数要经指针共享状态，成员计数白加（DFS 数出 0 的现场）。

## 23.2 Boost.PropertyMap（2000）：属性的泛型接口

BGL 的关节，独立也有用——"key→value"的四種存储方式统一成 `get(pm, k)`/`put(pm, k, v)`：

| 类型 | 长相 | 用途 |
|---|---|---|
| associative | `associative_property_map<map>` | 属性住 std::map |
| iterator | `iterator_property_map<vec, index>` | 属性住 vector（BGL 主流） |
| function | `function_property_map(f)` | 属性是**算出来的**（惰性派生） |
| identity | `identity_property_map` | 键即值（占位） |

运行输出（`property_map.cpp`）：

```text
ada = 36 jean = 74
顶点 1 的分 = 4
函数属性 f(7) = 49
恒等 f(42) = 42
自检通过
```

⭐ std 无对应。写泛型算法时"属性怎么存让调用方决定"的抽象。

## 23.3 Boost.Geometry（2009）：计算几何通用件

点/线/多边形/多面体的全套算法，坐标类型与坐标系都是模板参数：

```cpp
bg::distance(p1, p2);  bg::area(city);  bg::within(pt, city);
bg::intersection(city, other, out);      // 布尔运算
bg::simplify(track, simplified, 0.1);    // Douglas-Peucker 轨迹压缩
```

运行输出（`geometry.cpp`）：

```text
欧氏距离 = 5
城市面积 = 16 周长 = 16
(2,2) 在城内? 1
(5,5) 在城内? 0
两城相交? 1
交集面积 = 12
道路穿过城市? 1
道路长度 = 11
轨迹 11 点 → 简化 2 点
自检通过
```

支持投影坐标系与球面/大地测量（`cs::geographic`——算经纬度距离直接用 WGS84）。⭐ GIS、路径规划、空间索引（配 `geometry::index::rtree`）的 C++ 事实标准。

> 实测坑：多边形顶点**顺时针绕行面积为负**（本例第一次跑出 -16）——WKT 要写逆时针，或统一 `bg::correct()`。

## 23.4 Boost.Polygon（2009）：曼哈顿几何特化

只处理 90° 直角形状（矩形/直角多边形），换来看家本领：**扫描线布尔运算**（VLSI 版图、芯片布局、GUI 矩形管理的领域需求）：

```cpp
Rect a = gtl::construct<Rect>(0, 0, 10, 10);
Rect inter = a;  gtl::intersect(inter, b);        // 原地裁出交集
gtl::assign(uni, c + d);                          // 并集（可能多块）
gtl::manhattan_distance(p1, p2);                  // 曼哈顿度量
```

运行输出（`polygon.cpp`）：

```text
a 面积 = 100
交集 = 25（5,5)-(10,10) = 25）
a 包含 (3,3)? 1
b 包含 (3,3)? 0
并集矩形块数 = 1 总面积 = 28
(1,1) 与 (4,4) 曼哈顿距离 = 6
自检通过
```

**与 Geometry 的分界**：任意角度/球面用 Geometry；全是直角且要极致快的布尔运算用 Polygon。VLSI 布局工具（EDA 行业）在用。

> 实测坑：矩形布尔表达式的结果是**视图类型**，不能直接赋给 `rectangle_data`——要么 `gtl::assign` 落地到 set 容器，要么用 `gtl::intersect(目标, 参数)` 原地裁剪。

---

下一章：[24 · 数值计算](24-numeric.md)——math / multiprecision / rational / units / qvm / crc / safe_numerics / numeric::conversion。
