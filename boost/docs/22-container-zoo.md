# 22 · 容器（下）：数据结构动物园（11 库）

> 对应示例：`examples/22_container_zoo/`（11 个例程）

这一章全是 **std 没有的容器形态**——"毕业后仍有不可替代价值"密度最高的一章。每个库解决一类 std 容器组合起来很别扭的问题。

## 22.1 Boost.MultiIndex（2003）：一个容器，N 套索引

"按 id 查、按名字查、按分数排名"——用 std 得三个容器 + 手工同步；MultiIndex **一份数据多套视图**，还能跨索引修改：

```cpp
using Users = bmi::multi_index_container<User, bmi::indexed_by<
    bmi::ordered_unique<member<User, int, &User::id>>,          // 索引 0：有序
    bmi::hashed_unique<member<User, std::string, &User::name>>, // 索引 1：哈希
    bmi::ranked_non_unique<member<User, int, &User::score>>>>;  // 索引 2：可排名
users.get<1>().find("bob");            // O(1) 名字查
by_id.modify(by_id.find(2), [](User& u){ u.score = 99; });      // 跨索引改
```

运行输出（`multi_index.cpp`）：

```text
按 id: 1ada 2bob 3carol
名字查 bob: id=2 分=75
分数 < 90 的人数 = 2
90 分以上人数 = 1
bob 改分后 = 99
自检通过
```

⭐ std 无对应。数据库式的内存缓存（进程内用户表/订单表）的标准答案。索引种类齐全：有序/哈希/序列（保插入序）/ranked，unique 与 non_unique 任选。

## 22.2 Boost.BiMap（2004）：双向映射

```cpp
boost::bimap<int, std::string> bm;
bm.left.at(1);        // 1 → "one"
bm.right.at("three"); // "three" → 3（反向 O(log)）
bm.insert({9, "one"});   // 右值重复 → 拒绝
```

运行输出（`bimap.cpp`）：

```text
左查(1) = one
右查(three) = 3
重复右值插入成功? 0（大小仍 3）
  1 ↔ one
  2 ↔ two
multiset 右侧: 1 映射 1 个键
自检通过
```

⭐ 双向查找（国家码↔国家名、枚举↔字符串）用 std 得维护两个 map 并保持同步——bimap 一行都不用多写。两侧集合类型可独立配置（set_of/multiset_of/unordered_set_of/...）。

## 22.3 Boost.Intrusive（2005）：节点长在对象里

侵入式容器的两个杀手锏：**零分配**（插拔只改指针）、**一物多器**（同一对象同时在 list 和 set 里）：

```cpp
struct Task : bi::list_base_hook<>, bi::set_base_hook<> { ... };
for (Task& t : tasks) { list.push_back(t); set.insert(t); }   // 不分配！
list.erase(list.iterator_to(tasks[0]));                       // O(1) 拔除
```

运行输出（`intrusive.cpp`）：

```text
list 按插入序: 30 20 10
set 按 id 排序: 10 20 30
拔掉一个后 list: 20 10
自检通过
```

⭐ 高性能系统的底层件（游戏引擎的实体管理、内存池生态）。**代价**：对象析构前必须手动从容器摘除（容器不管生命周期）——这是侵入式的契约。

## 22.4 Boost.Heap（2011）：优先队列超市

| 变体 | 绝活 |
|---|---|
| `priority_queue` | std 同款二叉堆，但**可迭代**（std 版不行） |
| `d_ary_heap<arity<4>>` | 缓存更友好（Dijkstra 常用） |
| `binomial_heap` | **O(log) 合并** merge（多队列归并） |
| `fibonacci_heap` | 句柄式 increase/decrease **摊还 O(1)** |

运行输出（`heap.cpp`）：

```text
二叉堆顶 = 9 可迭代（std 版不行）: 9 7 5 1 3
4 叉堆顶 = 9
合并后堆顶 = 40 大小 = 4
fib 堆初始顶 = 70（最大堆）
increase(50→80) 后顶 = 80
decrease(80→40) 后顶 = 70
自检通过
```

⭐ 注意 boost::heap 全家默认**最大堆**（`decrease` 是远离堆顶）——与算法教材的 min-heap 直觉相反。std::priority_queue 不可迭代、不可合并、无句柄——需要任何一项就换它。

> 实测坑：binomial_heap.hpp 在 MSVC 19.51/c++latest 下有不可达代码告警（C4702，库自身问题），例程用 pragma 定点压制并注明。

## 22.5 Boost.ICL（2010）：区间容器

时间片/号段/IP 段管理的专用武器——**区间运算自动聚合**：

```cpp
interval_set<int> busy;
busy.insert(interval<int>::closed(9, 11));
busy.insert(interval<int>::closed(12, 17));
busy.insert(interval<int>::closed(18, 20));   // 三段自动连成一段
interval_map<int, int> load;                  // 区间带值，重叠自动累加
```

运行输出（`icl.cpp`）：

```text
忙碌时段段数 = 1（相邻自动合并）
10 点有空? 1
8 点有空? 1
交集首段 = [15,20]
负载区间数 = 3（含聚合出的 5-9=2 段）
  [0,4) → 1
  [5,9] → 2
  [10,14] → 1
自检通过
```

[9,20] 一段、交集 [15,20]、重叠区负载自动聚合为 2——全是容器自己算的。⭐ std 无对应。

## 22.6 Boost.Flyweight（2004）：享元模式库化

```cpp
flyweight<std::string> a(std::string("橡树"));
flyweight<std::string> b(std::string("橡树"));
&a.get() == &b.get();     // true：共享同一底层实例
```

运行输出（`flyweight.cpp`）：

```text
同串共享底层? 1
set 大小 = 5（真正分配的字符串只有 5 个）
两棵树共享树种名? 1
透明取用 = 松树
自检通过
```

海量重复不可变值（一百万个对象里的几十种字符串/颜色/棋子）的内存压缩器，用起来像普通值类型。⭐

## 22.7 Boost.DynamicBitset（2001）与 22.8 Boost.Bloom（1.89 新库）

```cpp
boost::dynamic_bitset<> flags(8);       // 运行期长度（std::bitset 是编译期）
flags.set(1); flags & mask; flags.find_first();

boost::bloom::filter<std::string, 1024> bf;   // 概率集合
bf.insert("apple");
bf.may_contain("durian");              // false = 一定不在；true = 可能在
```

运行输出（`dynamic_bitset.cpp` / `bloom.cpp`）：

```text
位集 = 00101010（高位在左）
AND = 00001010 count = 2
NOT = 11010101
左移 2 = 10101000
字符串来 = 10110010 个数 = 4
flags 第一个 1 在 1
---
apple 一定在或可能在? 1
durian 一定不在（如果答否）? 0
6 个词命中 6 个（3 个真成员 + 误判）
自检通过
```

bloom 实测诚实呈现了概率语义：1024 位的小过滤器上 6 个词**全命中**（3 真成员 + 3 误判）——误判率随装载率上升，生产用要按目标误判率配位数。API 名是 `may_contain`（名字即语义）。⭐ 缓存穿透防护、爬虫去重。

## 22.9 Boost.MultiArray（2002）：拥有数据的多维数组

```cpp
boost::multi_array<int, 2> mat(boost::extents[3][4]);
mat[2][3] = 23;
auto row1 = mat[1];              // 行视图
mat.reshape(dims{4, 3});          // 重定形（对照：mdspan 是纯视图，做不到）
```

运行输出（`multi_array.cpp`）：

```text
形状 = 3×4
mat[2][3] = 23 mat[1][1] = 11
第 1 行: 10 11 12 13
重定形后 = 4×3 元素总数不变 = 12
立方体角点 = 42
自检通过
```

与 `std::mdspan` 的分工（17 章）：**拥有数据且可重定形用 multi_array；跨接口传视图用 mdspan**——string/string_view 的关系。

## 22.10 Boost.PolyCollection（2017）：多态遍历的缓存杀器

`vector<unique_ptr<Base>>` 遍历时指针满天飞（缓存三连跳）；poly_collection **按实际类型分段连续存放**：

```cpp
boost::base_collection<Sprite> army;
army.insert(Warrior{}); army.insert(Mage{});
std::for_each(army.begin(), army.end(), [](const Sprite& s){ s.render(); });
for (auto it = army.begin<Archer>(), e = army.end<Archer>(); it != e; ++it) ...
```

运行输出（`poly_collection.cpp`）：

```text
只看弓手: 弓弓
全军: 兵兵兵法弓弓
总成本 = 10（3 兵 + 2 弓 + 1 法 = 3+4+3）
传统版成本 = 4（语义同，布局差）
自检通过
```

段顺序 = 注册顺序（兵兵兵法弓弓），段内连续 → 虚调用可被内联。官方基准比 `vector<unique_ptr>` 快 2-20 倍。⭐ ECS/渲染系统的多态容器答案。

> 实测坑：段迭代器是 begin/end 一对不是 range（range-for 直接写 `army.begin<Archer>()` 编不过）；聚合遍历用 `std::for_each` 而非成员 `for_each`。

## 22.11 Boost.PtrContainer（2004）：unique_ptr 时代前的遗产

`ptr_vector<T>` 装多态对象、`operator[]` 直接给 `T&`、析构自动 delete。今天默认答案是 `std::vector<std::unique_ptr<T>>`；ptr 容器的残余价值是**接口顺手**（不用解引用）和**克隆语义**（deep-copy 容器）。老代码认得即可。

---


> 上一章：[21 · 容器（上）](21-container-core.md) ｜ 下一章：[23 · 图与几何](23-graph-geometry.md) ｜ 返回：[README](../README.md)
