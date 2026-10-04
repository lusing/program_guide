# algorithm —— C++23 算法教程（以《算法导论》CLRS 第三版为纲）

以《Introduction to Algorithms, Third Edition》（CLRS，MIT Press，2009；本地 PDF：
`F:\book\计算机\算法\算法导论 第三版英文版 有索引.pdf`，1313 页，有完整文本层）的
35 章结构为骨架，用 **C++23** 重讲一遍算法的**原理、证明与实现**。

## 这是什么 / 不是什么

- **是教程，不是代码集**：每章正文自足——动机、定义、定理与证明思路（循环不变式、
  势能函数、期望分析）、伪代码到 C++23 的分片段讲解、复杂度推导、与 STL 的对照。
  不看 `examples/` 里的完整例程也能学会；例程只是把正文片段汇流成可运行的自测。
- **与 [datastruct](../datastruct) 的分工**：datastruct 是 Sahni 教材的**实现线**
  （28 章，覆盖各类结构的手写实现，另含左高树/跳表/LZW 等 CLRS 没有的内容）；
  本教程是 CLRS 的**分析线**——正确性证明、渐近分析工具（主定理/势能法）、随机化
  与概率分析、摊还分析、NP 完全性、近似算法保证。堆/BST/红黑树/B 树/图基础等重叠
  章节的讲法完全不同：这里以证明严格性 + C++23 现代写法为主。已读过 datastruct 的
  读者可以把第 06–24 章当作 CLRS 深化版快速过；没读过的直接按本教程顺序学。

## 章节导航（37 章 ↔ CLRS 35 章 + 附录）

**第一部分 基础（CLRS Part I）**

| 章 | 文档 | CLRS | 主题 |
|---|---|---|---|
| 01 | [docs/01-role-and-toolchain.md](docs/01-role-and-toolchain.md) | ch.1 | 算法的角色、C++23 工具链与本教程验证体系 |
| 02 | [docs/02-getting-started.md](docs/02-getting-started.md) | ch.2 | 插入排序、循环不变式、算法分析、归并排序 |
| 03 | [docs/03-growth-of-functions.md](docs/03-growth-of-functions.md) | ch.3 | 渐近记号 O/Ω/Θ/o/ω、常用函数 |
| 04 | [docs/04-divide-and-conquer.md](docs/04-divide-and-conquer.md) | ch.4 | 分治、最大子数组、Strassen、主定理 |
| 05 | （待交付） | ch.5 | 概率分析、指示器随机变量、随机化算法 |

**第二部分 排序与顺序统计量（CLRS Part II）**

| 章 | 文档 | CLRS | 主题 |
|---|---|---|---|
| 06 | （待交付） | ch.6 | 堆、堆排序、优先队列 |
| 07 | （待交付） | ch.7 | 快速排序与期望分析 |
| 08 | （待交付） | ch.8 | 决策树下界、计数/基数/桶排序 |
| 09 | （待交付） | ch.9 | 顺序统计量、中位数的中位数选择 |

**第三部分 数据结构（CLRS Part III）**

| 章 | 文档 | CLRS | 主题 |
|---|---|---|---|
| 10 | （待交付） | ch.10 | 栈/队列/链表/有根树的对象与指针表示 |
| 11 | （待交付） | ch.11 | 散列表：链址、开地址、全域散列 |
| 12 | （待交付） | ch.12 | 二叉搜索树 |
| 13 | （待交付） | ch.13 | 红黑树 |
| 14 | （待交付） | ch.14 | 数据结构扩张：顺序统计树、区间树 |

**第四部分 高级设计与分析技术（CLRS Part IV）**

| 章 | 文档 | CLRS | 主题 |
|---|---|---|---|
| 15 | （待交付） | ch.15.1–15.3 | 动态规划（上）：钢条切割、矩阵链、方法论 |
| 16 | （待交付） | ch.15.4–15.5 | 动态规划（下）：LCS、最优 BST |
| 17 | （待交付） | ch.16 | 贪心算法、Huffman、拟阵 |
| 18 | （待交付） | ch.17 | 摊还分析：聚合/记账/势能三法 |

**第五部分 高级数据结构（CLRS Part V）**

| 章 | 文档 | CLRS | 主题 |
|---|---|---|---|
| 19 | （待交付） | ch.18 | B 树 |
| 20 | （待交付） | ch.19 | 斐波那契堆 |
| 21 | （待交付） | ch.20 | van Emde Boas 树 |
| 22 | （待交付） | ch.21 | 不相交集（并查集） |

**第六部分 图算法（CLRS Part VI）**

| 章 | 文档 | CLRS | 主题 |
|---|---|---|---|
| 23 | （待交付） | ch.22 | 图表示、BFS、DFS、拓扑排序、强连通分量 |
| 24 | （待交付） | ch.23 | 最小生成树：Kruskal/Prim |
| 25 | （待交付） | ch.24 | 单源最短路：Bellman-Ford/Dijkstra |
| 26 | （待交付） | ch.25 | 全源最短路：Floyd-Warshall/Johnson |
| 27 | （待交付） | ch.26 | 最大流：Ford-Fulkerson/推送-重贴标签 |

**第七部分 专题选讲（CLRS Part VII）**

| 章 | 文档 | CLRS | 主题 |
|---|---|---|---|
| 28 | （待交付） | ch.27 | 多线程算法 → C++23 jthread/async 适配 |
| 29 | （待交付） | ch.28 | 矩阵运算：LUP 分解、求逆 |
| 30 | （待交付） | ch.29 | 线性规划与单纯形法 |
| 31 | （待交付） | ch.30 | 多项式与 FFT |
| 32 | （待交付） | ch.31 | 数论算法：模运算、RSA、Miller-Rabin |
| 33 | （待交付） | ch.32 | 字符串匹配：Rabin-Karp/KMP |
| 34 | （待交付） | ch.33 | 计算几何：凸包、最近点对 |
| 35 | （待交付） | ch.34 | NP 完全性 |
| 36 | （待交付） | ch.35 | 近似算法 |

**收束**

| 章 | 文档 | CLRS | 主题 |
|---|---|---|---|
| 37 | （待交付） | 附录 A–D | 数学背景速览、全书收束 |

## 快速开始

```powershell
pwsh ./build.ps1 -All            # 全量：编译 + 运行 + 自检 + 文档五关
pwsh ./build.ps1 -Example 02_getting_started    # 单示例
pwsh ./build.ps1 -Docs           # 只跑文档五关
```

判定六条（每个示例 × 每条通道，缺一不可）：退出码 0；stderr 为空（编译期告警也算
失败）；stdout 非空；无多余控制字符；含结束标记 `自检通过`；编译日志零告警。
另有跨通道逐字节对账与 [tools/check_docs.py](tools/check_docs.py) 文档五关。

## 验证状态

- 工具链（本机 Windows 11）：**MSVC VS 18（主线，/std:c++23）**；scoop clang++ 23.1.2
  （x86_64-pc-windows-msvc，共享 MSVC STL、独立前端，交叉核对通道）；scoop MinGW
  g++ 15.2（独立 libstdc++，机会型通道——其 `<print>` 链接缺终端符号，探针会自动
  降级到 `-DALGO_NO_PRINT` 垫片，见 build.ps1 两级探针）。
- 交付进度：**批次一（工程骨架）+ 批次二（01–04 章：角色与工具链 / 插入归并
  排序与循环不变式 / 渐近记号 / 分治与主定理）已全绿，共 4 示例 × 3 通道。**

## 写作约定

- **章号 = 示例编号**：`docs/NN-slug.md` ↔ `examples/NN_slug/`（严格 1:1）。
- **围栏纪律**：` ```clrs ` 伪代码；` ```cpp ` 讲解片段；裸 ` ``` ` ASCII 图与表格；
  ` ```text ` **只**用于真实运行输出（check_docs 按子序列对账）。
- **确定性输出**：不打印地址/时间/裸浮点；性能对比用操作计数器；随机数固定种子
  `std::mt19937{5489}`，且**不用** `uniform_int_distribution`（跨实现序列不同），
  一律自写 `rand_below`；不遍历打印 unordered 容器（哈希序跨实现不同）。
- **C++23 边界**：只进三通道都过的特性（`std::print`/`std::expected`/ranges C++23/
  deducing this/`std::generator`（探针确认））；不用 mdspan/flat_map/stacktrace/
  `std::execution` 并行算法/modules。
