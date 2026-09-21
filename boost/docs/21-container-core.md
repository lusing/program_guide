# 21 · 容器（上）：container 家族 + circular_buffer + pool + assign

> 对应示例：`examples/21_container_core/`（4 个例程）

Boost.Container 是"std 容器的平行宇宙"：它把标准容器全部重实现（更宽松的移动语义、可配置分配器、C++03 支持），并持续孵化 std 的下一代容器——`flat_map`（C++23 毕业）、`static_vector`（C++26 `std::inplace_vector` 毕业）都出自这里。

## 21.1 五个 std 没有的容器形态

```cpp
boost::container::flat_map<std::string, int> fm;         // 底层连续的有序 map
boost::container::small_vector<int, 8> sv;               // 栈上 8 个，超了上堆
boost::container::static_vector<int, 4> fixed;           // 定容永不上堆
boost::container::stable_vector<int> stv;                // 地址永远稳定的 vector
boost::container::devector<int> dv;                      // 两端高效 + 连续内存
```

运行输出（`container.cpp`）：

```text
flat_map: 1 2（有序遍历首键 = apple）
small_vector: 前 8 个在栈上, 共 10 个
static_vector: 满 4/4
stable_vector: 5 10 20 30（插入后旧元素地址不变）
devector: 123（首插不搬移）
std::map 大小 = 1（对照用）
自检通过
```

**选型表**（这是本章的干货）：

| 场景 | 用什么 | 为什么 |
|---|---|---|
| 读多写少的配置表/查找表 | `flat_map` | 连续内存二分，比红黑树 `std::map` 快 3-10 倍且省内存 |
| 函数内小数组（大小不定但通常 ≤N） | `small_vector<int, N>` | 免堆分配；`std::vector` 永远上堆 |
| 大小上限已知、禁止分配 | `static_vector` | 实时系统/嵌入式；C++26 `std::inplace_vector` 直系 |
| 需要元素地址稳定 + 随机访问 | `stable_vector` | 节点式 vector；`std::deque` 首插会搬移、`std::list` 无随机访问 |
| 双端操作为主 | `devector` | `std::deque` 是分段的（跳缓存），devector 中段连续 |

**关于 hive 的更正**：`std::hive`（提案中）的参考实现（Matt Bentley）**尚未收录 Boost 1.92**——之前章节导览表里的指向已在成文时更正。std::hive 落地前想要"元素地址稳定的桶笼容器"，用 `stable_vector` 或独立 hive 库。

## 21.2 Boost.CircularBuffer：环形缓冲

```cpp
boost::circular_buffer<int> cb(3);
cb.push_back(4);   // 满了：顶掉最老的 1
cb.back();         // 最新
cb.front();        // 最老
```

运行输出（`circular_buffer.cpp`）：

```text
内容:  3 4 5（size=3 capacity=3）
最新 = 5 最老 = 3
  窗口均值 = 10
  窗口均值 = 15
  窗口均值 = 20
  窗口均值 = 30
  窗口均值 = 40
std 无对应（deque 不是环形语义）
自检通过
```

**环形语义**是它存在的全部理由：最新 N 条日志、滑动窗口统计、速率限制器的固定成本。`std::deque` 双端但无容量语义，`std::vector` 会无限增长——**滑动窗口/环形日志就该用它**。⭐ std 无对应。

## 21.3 Boost.Pool（2000）：同型小块的批发商

```cpp
boost::object_pool<Particle> pool;
Particle* p = pool.construct(1);      // 槽位分配 + 构造
pool.destroy(p);                      // 析构 + 归池（下次 construct 复用）
std::list<int, boost::pool_allocator<int>> pooled;     // 容器直接换池化分配器
```

运行输出（`pool.cpp`）：

```text
p1 = (0,0,0) id=1
p2 id = 2
p3 复用槽位 id=3
池化 list: 0 100 200 300 400
fast 池化 list 大小 = 2
std 无对应（allocator 没有池化的标准件）
自检通过
```

**什么时候还用它**：百万级 16-64 字节小对象高频生灭（粒子系统、AST 节点、网络会话）。日常场景已被 `make_shared`（单次分配）和 `pmr` 内存资源（C++17，那才是池化的标准答案）覆盖大半。⭐ 剩余生态位明确。

> 实测坑：`object_pool::construct` 的构造参数透传**有参数个数上限**（4 个就编不过）——复杂初始化用单参构造 + 成员赋值最稳。

## 21.4 Boost.Assign（2003）：被语言特性吞掉的库

```cpp
std::vector<int> v = boost::assign::list_of(1)(2)(3);   // 2003 年的容器字面量
std::vector<int> w;  w += 10, 20, 30;                    // 追加语法糖
auto m = boost::assign::map_list_of("ada", 36)("grace", 85);
```

运行输出（`assign.cpp`）：

```text
list_of: 1 2 3
map_list_of: ada=36 grace=85
+= 语法: 10 20 30
insert: x=1 y=2
现代写法: 3 元, 2 对
自检通过
```

C++11 初始化列表（`{1, 2, 3}`、`{{"ada", 36}}`）覆盖了它 95% 的用途——**已毕业（平行进化型）**，老代码里认识即可。

---


> 上一章：[20 · 解析器族谱](20-parsers.md) ｜ 下一章：[22 · 容器（下）](22-container-zoo.md) ｜ 返回：[README](../README.md)
