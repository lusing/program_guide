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

## 22.x Boost.BiMap（2004）：双向 map——键值都可查

std::map 的映射是单向的（key→value）；bimap 让两边都是键。基于 multi_index 实现，`bm.left`/`bm.right` 两个视图各是一个"方向"的 map。

```cpp
boost::bimap<int, std::string> bm;
bm.insert({1, "one"});                  // 两边都必须唯一
bm.left.at(1);                          // → "one"（左视图）
bm.right.at("three");                   // → 3（右视图）
```

**三条与 std::map 的分界**：任一侧重复都会让整个插入**被拒**（两边都是键）；迭代器给的是 `pair<const, const>`——**value 不可原地改**；没有 `operator[]`/`at`（除非某一侧配了 `vector_of`/`list_of` 这类序列集合类型——例程里 `bm3.left[2] = "222"` 就是这么来的）。

**集合类型**是左右两个模板参数：`set_of`（默认，有序唯一）/`multiset_of`/`unordered_set_of`/`unordered_multiset_of`/`list_of`（序列，只能当"值"）/`vector_of`（随机访问，可下标）/`unconstrained_set_of`（无约束）。要双向查找，两侧必须都是"可查找"类型（set 族）；一侧序列化就只剩另一个方向的视图。

运行输出（`bimap.cpp`）：

```text
左查(1) = one 右查(three) = 3
重复右值插入成功? 0（大小仍 3）
  1 ↔ one
  2 ↔ two
multiset 右侧: "a" 映 2 个左键（大小 2）
vector 右侧: bimap
by<id>(2) = peach by<name>(yoshi) = 5
replace 后: [111]=luigi
modify 撞车: 2 → 1（peach 被删，找不到? 1）
投射: 左[111] → 右[luigi]
内建值类型: seven/8
自检通过
```

输出后六行对应四个进阶件：

- **标签**：`bimap<tagged<int, struct id>, tagged<std::string, struct name>>` 之后 `bm.by<id>()`/`by<name>()` 取代含义模糊的 left/right（多个 bimap 不会再混）；
- **替换**：`left.replace_key(pos, 新键)` / `replace_data(pos, 新值)`——std::map 做不到的"改键"（其实是删+插的事务版），失败返回 false；
- **修改**：`left.modify_key(pos, _key = 111)`（`_key`/`_data` 占位符在 `<boost/bimap/support/lambda.hpp>`）——比 replace 快，但**违反唯一约束时元素被静默删除**（不抛异常！例程里 peach 就这么没了）；
- **投射**：`project_right(左迭代器)` 在两个视图间换视角；**内建值类型** `left_value_type`/`right_value_type` 比 `make_pair` 少一次拷贝。


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
11:30(即 11)有空? 1
8 点有空? 1
交集首段 = [15,20]
负载区间数 = 3（含聚合出的 5-9=2 段）
  [0,5) → 1
  [5,9] → 2
  (9,14] → 1
自检通过
```

> 实测坑（跨平台/跨版本）：ICL 区间的**打印形式会随版本变**。同一个 `interval_map`，Boost 1.92（MSVC）打 `[0,4) → 1 / [10,14] → 1`，Boost 1.88（clang）打 `[0,5) → 1 / (9,14] → 1`——段数与值都一样，只有界符不同。断言要比**段数和值**，别比界符字符串。

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

## 22.x Boost.DynamicBitset（2001）：任意长位集

std::bitset<N> 编译期定长；运行期才知道长度（哈希指纹、布隆过滤、集合运算）用 dynamic_bitset。它**不是容器**（没有迭代器），是"可以按位下标访问的动态长 bit 数组"，按 Block（默认 unsigned long）分块存储。

```cpp
boost::dynamic_bitset<> a(10, BOOST_BINARY(10101));  // 长度 10，初值
boost::dynamic_bitset<> b(std::string("0100"));      // 只认 std::string
a.set(1); a.reset(3); a.flip();                      // 逐位三件套
auto u = s1 | s2;                                    // 位运算 = 集合运算
sub.is_subset_of(s1);                                // 子集有专门函数
```

运行输出（`dynamic_bitset.cpp`）：

```text
构造: 0000010101 0100 0000000000000000010101（第 0 位在**最右边**，stream 输出高位在左）
块大小: 1 块 × 32 位（22 位只需 1 块）
位运算: 并|10111 交&10000 差-00101 异或^00111
子集: {101} ⊆ {10101}? 1 真子集? 1
访问: test(0)=1 count=3 any=1 none=0
清零+翻位后: 01000 count=1
push_back 后: 101001 值=41
append 后长度 = 38（+block_size 而不是 +3 位）
to_ulong = 10
38 位但高位全 0 → to_ulong = 361
有效位超宽抛 overflow_error? 1（保险走 to_string）
to_string 长度 = 38
位 1 位置: first=0 next=4（找不到给 npos）
50 以内质数(17 个): 2 3 5 7 11 13 17 19 23 29 31 37 41 43 47
自检通过
```

四个容易踩的合同细节（都有输出对照）：**第 0 位在最右**（stream 打印高位在左，读输出别读反）；`append(block)` 加的是**一整块**的宽度（本机 block 32 位，加 3 位的值也吃掉 32 位）；`to_ulong()` 看的是**有效位**（非零最高位）而不是总长度——高位全 0 的 38 位照样能转，有效位第 35 位才抛 `overflow_error`（保险走 `to_string`）；`find_first()/find_next(pos)` 返回下标不是迭代器。

最后的筛法质数是书的综合例：`find_next` 链式跳位 + "划掉倍数"就是一遍位图筛——运行期定长（用户输入 n）正是 std::bitset 给不了的。

> 实测坑：`BOOST_BINARY` 单组最长 8 位——写 10 位一组直接 C1009"宏嵌套太深"；空格分组（`BOOST_BINARY(00100100 01)`）即可。


## 22.x Boost.MultiArray（2002）：N 维数组容器

vector&lt;vector&lt;T&gt;&gt; 拼多维的正规替代：一次分配、连续内存、运行期定形。拥有数据这点使它与 C++23 `std::mdspan`（纯视图）分工不同。

```cpp
boost::multi_array<int, 2> mat(boost::extents[3][4]);   // extents 生成器
mat[2][3] = 11;                                         // 裸下标
auto row1 = mat[boost::indices[1][range()]];           // 切片：降一维
auto view = mat[boost::indices[range(0,2)][range(0,4,2)]];  // 子视图+步长
```

运行输出（`multi_array.cpp`）：

```text
形状 = 3×4 维数 = 2 元素 = 12
mat[2][3] = 11 == mat(iv)? 1
子视图(2×2, 列步长2): [0 2 ] [4 6 ]
切片(第 1 行降维): 4 5 6 7
reshape 后 = 4×3 [2][2]=8（原 [3][1] 的值）
resize 后 = 2×9 元素 = 18（新元素零初始化）
索引基数: [1][0][-2] = 10 基 = 1/-2
reindex(1) 后首元素在 [1][1][1]? 1
ref 改写原内存: raw[5] = 99 只读视图 [2][1] = 99
立方体角点 = 42 data 连续? 1
自检通过
```

按输出顺序的六个要点：**两种下标**——`mat[i][j]` 或打包一组索引走 `mat(index_array)`；**子视图**用 `indices[range(起,止)[/步长]]...` 圈一块（每维独立），给某维**整数**而非区间就是**切片降维**；**reshape** 改形状不改数据（元素总数必须不变，`[2][2]` 处正是原 `[3][1]` 的值顺移），**resize** 真改大小（新元素零初始化）；**索引基数**——`extent_range(1,5)` 让第一维从 1 数起、甚至可以从 -2 数起（数学惯用的下标界），`reindex(1)` 事后整体平移；**multi_array_ref/const_multi_array_ref** 把既有一段连续内存适配成多维视图（可写/只读两版）；`data()`/`origin()` 拿连续内存基址。

> 实测坑（1.92/MSVC）：`multi_array_ref` 的构造函数**只吃维度序列**（`boost::array`/`std::vector`），不认 `extents[2][3]` 表达式——与 multi_array 正相反；`reshape` 同样只吃序列。extents 表达式只在 multi_array 的构造/resize 里通用。


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
