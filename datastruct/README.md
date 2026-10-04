# 数据结构教程（C++23）

手搓 28 章：从顺序表到分支限界，每个数据结构与算法设计策略都有**可运行、可自检、可复现**的实现与讲解。以三本书为纲，全部代码符合 C++23，三通道构建零告警。

## 三书导读

| 书 | 定位 | 在本教程中的角色 |
|---|---|---|
| Sahni《数据结构算法与应用 - C++ 语言描述》 | 经典英文教材中译本，ADT 合同、复杂度证明、竞赛树/左高树/分支限界等中高级结构讲得最系统 | 骨架教材：章节顺序、ADT 合同写法、复杂度推导口径主要沿用它的体系（13–17 章算法设计直接对应其第 13–17 章） |
| 《用 C++ 实现数据结构程序设计》 | 国内程序设计视角，代码逐行讲解，线性/查找/排序章节实操性强 | 代码教材：04–09 线性结构、21–22 排序的实现细节与程序设计技巧参考它（第 3、11 章） |
| 《新编数据结构案例教程（C/C++ 语言）-微课版》 | 国内案例教学教材，每章带案例与习题，末章为 ACM 经典案例 | 案例与大纲教材：各章应用案例取材于它，28 章综合案例与其"考研大纲考点"对照表收尾 |

三书组合的逻辑：Sahni 给**体系**，程序设计书给**落地**，案例教程给**应用与考点**。任何一章都能在三本书里找到对应出处，正文各章"素材来源"不再逐一标注。

## 环境要求

- 编译器（任二即可全绿）：
  - MSVC（VS 18，`cl /std:c++latest /EHsc /utf-8 /permissive- /Zc:__cplusplus /W4`）——vcvars64 路径在 `build.ps1` 中配置；
  - clang++ 23（`-std=c++23 -Wall -Wextra`）；
  - gcc 15.2：本机 MinGW 的 `<print>` 链接损坏，探针自动门控跳过（Linux/gcc 15+ 环境可直接启用）。
- PowerShell 7（`pwsh`）；Windows 11。
- 依赖仅标准库，无第三方包。

## 构建

```powershell
pwsh ./build.ps1 -All           # 全部示例 × 2 通道（MSVC + clang），比对输出逐字节一致
pwsh ./build.ps1 -Example 13_heap   # 单个示例
```

判定六条：退出码 0、stderr 为空、stdout 非空且无杂散控制符、末行为"自检通过"、编译零告警、两通道输出逐字节一致。随机只使用固定种子 `std::mt19937 rng{5489}`，全部输出确定性可复现。

## 28 章导航

| 篇 | 章 | 文档 | 示例 | 核心 ADT / 主题 |
|---|---|---|---|---|
| 基础 | 01 | [01-intro.md](docs/01-intro.md) | [01_intro](examples/01_intro/) | 线性表顺序存储 vs 链接存储 |
| | 02 | [02-performance.md](docs/02-performance.md) | [02_performance](examples/02_performance/) | 复杂度、操作计数、公式 vs 循环 |
| | 03 | [03-recursion.md](docs/03-recursion.md) | [03_recursion](examples/03_recursion/) | 递归三问、汉诺塔、备忘录 |
| 线性结构 | 04 | [04-arraylist.md](docs/04-arraylist.md) | [04_arraylist](examples/04_arraylist/) | 顺序表（未初始化存储 + placement new） |
| | 05 | [05-linkedlist.md](docs/05-linkedlist.md) | [05_linkedlist](examples/05_linkedlist/) | 单/双/循环链表 |
| | 06 | [06-listvariants.md](docs/06-listvariants.md) | [06_listvariants](examples/06_listvariants/) | 静态链表、间接表、并查集、多项式 |
| | 07 | [07-stack.md](docs/07-stack.md) | [07_stack](examples/07_stack/) | 栈、调度场、迷宫 |
| | 08 | [08-queue.md](docs/08-queue.md) | [08_queue](examples/08_queue/) | 循环队列、银行模拟、约瑟夫环 |
| | 09 | [09-string.md](docs/09-string.md) | [09_string](examples/09_string/) | 朴素/KMP 串匹配、全文索引 |
| 多维与树形 | 10 | [10-matrix.md](docs/10-matrix.md) | [10_matrix](examples/10_matrix/) | 对称阵、稀疏阵、十字链表、广义表 |
| | 11 | [11-binarytree.md](docs/11-binarytree.md) | [11_binarytree](examples/11_binarytree/) | 二叉树五遍历、前中序重建 |
| | 12 | [12-treeforest.md](docs/12-treeforest.md) | [12_treeforest](examples/12_treeforest/) | 长子-兄弟、森林↔二叉树、并查集按秩 |
| | 13 | [13-heap.md](docs/13-heap.md) | [13_heap](examples/13_heap/) | 二叉堆、heapify、堆排序 |
| | 14 | [14-leftisttree.md](docs/14-leftisttree.md) | [14_leftisttree](examples/14_leftisttree/) | 左高树 meld、赢者树 k 路归并 |
| | 15 | [15-huffman-lzw.md](docs/15-huffman-lzw.md) | [15_huffman_lzw](examples/15_huffman_lzw/) | 哈夫曼编码、LZW 压缩 |
| 查找 | 16 | [16-dict.md](docs/16-dict.md) | [16_dict](examples/16_dict/) | 跳表、链地址/开放定址哈希 |
| | 17 | [17-searchtree.md](docs/17-searchtree.md) | [17_searchtree](examples/17_searchtree/) | BST、AVL 四型旋转、红黑树 |
| | 18 | [18-btree.md](docs/18-btree.md) | [18_btree](examples/18_btree/) | B 树、B+ 树区间查询、倒排索引 |
| 图 | 19 | [19-graph.md](docs/19-graph.md) | [19_graph](examples/19_graph/) | 邻接矩阵/表、BFS/DFS、拓扑排序 |
| | 20 | [20-graphalgo.md](docs/20-graphalgo.md) | [20_graphalgo](examples/20_graphalgo/) | Dijkstra/Floyd、Prim/Kruskal、AOE 关键路径 |
| 排序 | 21 | [21-sort1.md](docs/21-sort1.md) | [21_sort1](examples/21_sort1/) | 插入/折半/冒泡/选择/快排 |
| | 22 | [22-sort2.md](docs/22-sort2.md) | [22_sort2](examples/22_sort2/) | 希尔/堆/归并/基数/桶、外部排序模拟 |
| 算法设计 | 23 | [23-greedy.md](docs/23-greedy.md) | [23_greedy](examples/23_greedy/) | 装载、部分背包、任务调度 |
| | 24 | [24-divideconquer.md](docs/24-divideconquer.md) | [24_divideconquer](examples/24_divideconquer/) | 残缺棋盘、min-max、快速选择 |
| | 25 | [25-dp.md](docs/25-dp.md) | [25_dp](examples/25_dp/) | 0/1 背包、矩阵链、最优 BST |
| | 26 | [26-backtrack.md](docs/26-backtrack.md) | [26_backtrack](examples/26_backtrack/) | n 皇后、图着色、子集和 |
| | 27 | [27-branchbound.md](docs/27-branchbound.md) | [27_branchbound](examples/27_branchbound/) | 背包分支限界、TSP |
| 收官 | 28 | [28-cases.md](docs/28-cases.md) | [28_cases](examples/28_cases/) | 文件归并、数岛、关键路径、计算器；考研大纲对照 |

## 验证状态

全部 28 个示例 × MSVC / clang 两条通道 = **56 项全绿**，两通道输出逐字节一致（gcc 通道在本机构建环境探针失败、按门控跳过；详见 `build.ps1` 探针说明）。速查卡见 [CHEATSheet.md](CHEATSheet.md)。
