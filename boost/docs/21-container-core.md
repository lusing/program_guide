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
内容: 3 4 5（size=3 capacity=3）
最新 = 5 最老 = 3
  窗口均值 = 10
  窗口均值 = 15
  窗口均值 = 20
  窗口均值 = 30
  窗口均值 = 40
满容: full? 1 size==capacity? 1
线性化后连续访问: mem[0]=1 mem[3]=4 已线性? 1
rotate(+2) 后: 3 4 5 1 2
space_optimized: size=4 capacity=10（满额才用满 10 块）
std 无对应（deque 不是环形语义）
自检通过
```

环形结构的三件专用操作：**`full()`** 问是否满容（`size()==capacity()` 的快路）；**`linearize()`** 把"逻辑环"整理成首尾连续的内存块（喂给要连续内存的 C API/算法），`is_linearized()` 问当前是否已连续；**`rotate(it)`** 以某位置为新开头整体旋转——`{1,2,3,4,5}` 转 2 步变 `{3,4,5,1,2}`，只改"哪里算开头"不动元素。注意**迭代器不环形**：只在 begin..end 内有效，越界即失效断言。`circular_buffer_space_optimized` 是"按需占内存"的适配版（元素少时少占，满额才占满）。


**环形语义**是它存在的全部理由：最新 N 条日志、滑动窗口统计、速率限制器的固定成本。`std::deque` 双端但无容量语义，`std::vector` 会无限增长——**滑动窗口/环形日志就该用它**。⭐ std 无对应。

## 21.3 Boost.Pool（2000）：同型小块的批发商

pool 库基于"简单分隔存储"思想：向系统**批发**一大块内存，切成等大的小块**零售**给同型对象。它是四个组件的家族，分工先立住：

- `pool<>` —— 最原始的池：只给内存不给构造（POD 专用），接口就是 malloc/free 的池化版；
- `object_pool<T>` —— 类实例的池：`construct()` 分配 + 构造、`destroy()` 析构 + 归池；
- `singleton_pool<Tag, Size>` —— 全局单件池：静态接口、无需实例、生命周期到程序结束；
- `pool_allocator` / `fast_pool_allocator` —— 给 STL 容器换上的池化分配器（一行升级）。

`pool<>` 的构造参数是**每块的大小而不是池的总大小**——池会按需自动扩容，析构时全部归还。分配失败**返回空指针而不抛异常**，用前要判空；`is_from(p)` 可以问"这块内存是不是从我这里出去的"；`ordered_malloc` 一族在分配的同时顺带合并空闲链（大量零散 free 之后用它整理一次）。

`object_pool` 的 `malloc()` 与 `construct()` 是两个层次：前者只给原始内存（值未定义，别读），后者分配 + 调构造函数——**优先用 construct**。`singleton_pool` 的 `Tag` 是个空类，纯粹用于在编译期区分不同的池（可以内联声明 `singleton_pool<struct pool_tag, sizeof(int)>`）；它不随作用域析构，想主动还内存要调 `release_memory()`（只还空闲块）或 `purge_memory()`（强制全还）。

```cpp
boost::pool<> pl(sizeof(int));
int* p1 = static_cast<int*>(pl.malloc());     // 失败返回 nullptr（不抛）

boost::object_pool<Particle> pool;
Particle* q = pool.construct(1);              // 分配 + 构造
pool.destroy(q);                              // 析构 + 归池（复用槽位）

using particle_pool = boost::singleton_pool<particle_tag, sizeof(Particle)>;
Particle* s = static_cast<Particle*>(particle_pool::malloc());   // 静态接口

std::list<int, boost::pool_allocator<int>> pooled;               // 容器换池
```

运行输出（`pool.cpp`）：

```text
pool<>: *p1=42 *p2=7 is_from(p1)? 1
ordered_malloc 非空? 1 失败约定 = 返回 nullptr（不抛异常）
object_pool: q1 id=1 q2 id=2
复用槽位: q3 id=3 地址复用? 1
malloc 原始内存 is_from? 1（值未定义，不读）
自由函数 4 参构造: 1234
singleton_pool: s1 id=99 is_from? 1
singleton 释放后仍可再分配? 1
池化 list: 0 100 200 300 400
fast 池化 list 大小 = 2
自检通过
```

**什么时候还用它**：百万级 16-64 字节小对象高频生灭（粒子系统、AST 节点、网络会话）。日常场景已被 `make_shared`（单次分配）和 `pmr` 内存资源（C++17，那才是池化的标准答案）覆盖大半。⭐ 剩余生态位明确。

> 实测坑：`object_pool::construct` 的构造参数透传**有参数个数上限**——本机 1.92/MSVC 实测 4 参即编译错误（预生成档位只到 3 参；历史上靠 m4 宏生成更多，1.92 仍是旧机制）。第 5 版书给的解法至今仍是最优解：写一个可变参数模板的自由函数 `construct(pool, args...)`，内部 `pool.malloc()` + **placement new** 完美转发——参数个数无上限，任何 pool 类型通用（`pool.cpp` 里有完整实现；注意 placement new 出来的对象要手动调析构再归还）。

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
push_back 链: 1 2 3 4 5
混用语法 6..10? 1
repeat(3,2) 结果 = 1
repeat_fun = 1
range 搬运 = 1
stack 顶 = 4（4 在顶）
queue 首尾 = c/swift
ref_list_of = 1
自检通过
```

C++11 初始化列表（`{1, 2, 3}`、`{{"ada", 36}}`）覆盖了它 95% 的用途——**已毕业（平行进化型）**，老代码里认识即可。

认识老代码需要认得它的三件结构：

- **`+=` 只对标准容器重载**（vector/set/map...），机制是 `operator+=` 返回 `list_inserter`（内部包着 push_back/insert 的函数对象，重载 `,` 和 `()` 串联插值）；其他容器走 `push_back(v)(1)(2)` / `push_front` / `insert(m)(k, v)` 工厂——括号式还能多参（map 免 `make_pair`）、括号逗号可混用、空括号 `()` 插值初始化的默认元素；
- **`list_of` 族产 `generic_list`**（可隐式转任意容器）：`list_of` 造序列、`map_list_of`/`pair_list_of` 造键值对、`tuple_list_of` 造元组序列、`ref_list_of<N>(a)(b)(c)` 造**引用**序列（内部不拷贝，更省）；
- **`repeat(sz, value)` / `repeat_fun(sz, f)` / `range(first, last)`** 是初始化列表至今没有的能力：重复元素、按函数现造、搬运既有序列；
- 容器**适配器**（stack/queue/priority_queue 没有 push_back）用 `list_of(...).to_adapter()` 落地、`push(q)(x)` 插值。

---


> 上一章：[20 · 解析器族谱](20-parsers.md) ｜ 下一章：[22 · 容器（下）](22-container-zoo.md) ｜ 返回：[README](../README.md)
