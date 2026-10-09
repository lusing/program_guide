# 第 46 章 图灵度与优先法

> 对书：Marker《An Invitation to Mathematical Logic》ch 12。本章通道：C（`examples/46_degrees/ex46_degrees.v`）/ L（`examples/46_degrees/ex46_degrees.lean`）。

| 机器件 | 内容 | 通道 |
|---|---|---|
| `ostep`/`orun` | **oracle 机**：roq 查询指令——相对可计算性的机器面 | C/L |
| `kp_req1_beats`/`kp_req2_beats` | Kleene–Post 显式击败现场：两个 oracle 程序各在对方集合的见证位算错 | C/L |
| `leftmost`/`leftmost_avoid1` | König 引理的左极路径计算器（可计算 2-树） | C/L |
| `fmStep`/`fm_ledger` | Friedberg–Muchnik 有穷损害的阶段账本（见证入账/损害计数） | C/L |

45 章把不可计算分层；这一章问一个更结构化的问题：**「相对不可
计算」本身能组成什么宇宙？** A ≤_T B（A 可由带 B-oracle 的机器
计算）是预序，模掉等价得到**图灵度**——0（可计算）在底，0′=K
（停机集）在其上。Marker ch 12 是全书的「高阶施工课」：度的不
可比性（Kleene–Post）、树构造（König、低基、极小度）、以及
改变领域的**优先法**（Friedberg–Muchnik 解答 Post 问题）。

## 一、oracle 机与跳跃

**A ≤_T B**：存在带 B-oracle 的程序计算 χ_A。**跳跃**：X′ :=
K^X（相对停机集）——X ≤_T X′ 且严格高（相对化的对角）。**Post
定理**（Th 12.24 区）：Δ_{n+1} = {A : A ≤_T 0⁽ⁿ⁾}——45 章的算术
层级与度论在这里接轨：每层 Δ 就是「跳 n 次以内能算」的集合。
机器面给 oracle 机最小实现：新指令 `roq r l1 l2`（问 oracle 在
R_r 处的值并跳转）——`ostep`/`orun` 与 44 章通用机同构，只是
step 多带一个参数。跳跃的阶段枚举是 45 章 K_s 的相对化，账本
同型。

## 二、Kleene–Post：不可比较度的有限延伸施工

**定理**（Th 12.24 区）：存在 A, B 使 A ≰_T B 且 B ≰_T A
（A,B ≤_T 0′）。

施工是「逐步发牌」：需求 R_{2e}（A ≠ φ_e^B）与 R_{2e+1}（B ≠
φ_e^A）轮流；轮到 R_{2e} 时用 0′-oracle 问「φ_e^B 会在某个新鲜
点 x 停吗？」——会则把 A(x) 定义成**与输出相反**（击败），不会
则随便定义（φ_e^B 根本不算 A）。每次只延伸有限多位，两套集合
同时长成，谁也算不出谁。

机器面把配方压到两个需求的**显式击败**：A、B 各 16 位手工延伸
的特征串；两个 oracle 程序——`PcopyB`（问 B(x) 并复制）与
`PnegA`（问 A(1) 并取反）——分别在见证位 0、1 上被算错：

```coq
Example kp_req1_beats :
  andb (match orun oB PcopyB (mkc 0 [0;0;0] []) 20 with
        | Some c => Nat.eqb (nthd 0 (regs c) 0) 0 | None => false end)
       (andb (negb (oB 0)) (oA 0)) = true.
```

A(0)=true ≠ 0 = PcopyB^B(0)；B(1)=false ≠ 1 = PnegA^A(1)。
**机制即全部**：有限延伸+对角见证+oracle 判停——完整归纳（对
需求列表）与「≤_T 0′」的核算记文档线。

## 三、König 引理与树构造

**König 引理**（Prop 12.25）：无限 2-树必有路径。证明=**左极
下降**：在每层优先选「子树仍无限」的左枝。这条朴素的构造是
度论树方法的心脏：**低基定理**（Jockusch–Soare：每个无限可计
算树有一条「低」路径——L ≤_T 0′ 却 L′=0′）与**极小度**（Spector）
都在它上面生长；书 §12.3 明说这两条施工分别是 Cohen forcing
与 Sacks forcing 的前身——逻辑与集合论在此握手。

机器面实现 `leftmost`（截断版无限性=每层有延伸）：在「排除全 1
分枝」的树上走出全 0 路径（`leftmost_avoid1`）——左极下降+子树
无限性检查的直译。

## 四、Friedberg–Muchnik：优先法登台

**Post 问题**（1944）：有没有 CE 度严格介于 0 与 0′？45 章 Post
定理给出 Δ₂ 的中间集，但**CE** 的中间度需要新武器——**有穷损害
优先法**（Friedberg–Muchnik 1957，Th 12.31）：造 CE 集 A,B 使
A ≰_T B、B ≰_T A。与 Kleene–Post 的差别：没有 0′-oracle 发牌，
只能**枚举**式施工——放见证入 A 可能**损害**先前为 B 立好的
需求（对方的计算引用了被改的位）；核心引理「每需求只被损害有
限次」由「小需求使用小见证」的优先序保证。

机器面给阶段账本（`fmStep`/`fmRun`/`fm_ledger`）：A/B 两列见
证、损害计数器、12 个阶段的演化 trace——每列 6 枚见证、损害
6 次、随阶段线性有界。「每需求只被抢有限次」的完整归纳与最小
对（Th 12.33）记文档线。

## 小结

度论把「不可计算」从二值变成偏序宇宙：跳跃爬塔（Post 定理连
回层级）、有限延伸发牌（KP 不可比）、树构造（König/低基/极小
度——forcing 的源头）、优先法（FM 的有穷损害——此后 60 年可
计算性理论的通用引擎）。机器件各留一个可跑的工作样板：oracle
机、击败现场、左极下降、阶段账本。下一章回到算术本身：Gödel
不完备定理的层级化路线与原始证明——wild 叙事的正片。

---

上一章：[45 可枚举集与算术层级：Kolmogorov 随机性](docs/45-hierarchy.md) · 下一章：[47 复杂度：P 与 NP](docs/47-complexity.md)
