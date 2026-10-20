# 40 解析集：投影下的可测性存亡

**对应严书 §7.6（pp. 163-167）。mathlib `Constructions/Polish/
Basic.lean`：`AnalyticSet` + Lusin 分离 + Choquet 容度链 ✓
（B7 实测翻案：原判"无基础设施"作废）。**

---

## 40.1 问题：连续投影会把 Borel 集变成什么

ℝ² 的 Borel 集投影到 ℝ——结果还是 Borel 吗？**不一定**
（ Souslin 1917 的发现，终结了 Lebesgue 的一个错误
证明）：投影 = 存在量词的集合运算（x ∈ proj A ⟺
∃y (x,y) ∈ A），而 σ-代数只对**可数**运算封闭，对投影
（本质不可数的 ∃）不封闭。**解析集（analytic set）**就是
这个投影闭包的居民：Borel 世界的"一遍投影后的稳定层"。

**两种等价定义**：

1. **投影版**：A ⊆ X 解析 ⟺ A 是某 Polish 空间 Z 经
   连续映射 f : Z → X 的像（mathlib `AnalyticSet` 的
   定义；等价地 X×ℕ^ℕ 的 Borel 集的投影——"带 Polish
   证件的连续像"）；
2. **Souslin 运算版（严书 7.6.1）**：对集类 𝓕 的
   **Souslin 运算**

   A(𝓕) = {∪_{σ∈ℕ^ℕ} ∩ₙ F_{σ|n}}（F_s ∈ 𝓕，s 取遍
   有限序列——"沿无限分支的树的交之并"）——解析集 =
   A(B(X))（Borel 集的 Souslin 壳）。

树语言读法：把 ℕ^ℕ 的每个无限序列 σ 看作一条路径，
∩ₙF_{σ|n} 收割路径的"楔形交集"，再对一切路径并起来
——**Souslin 运算是"可数并交"的非可数松绑**，恰好
捕获投影的复杂度。两条路线的等价（树编码 + 紧化）是
描述集合论的第一课。

## 40.2 基本封闭性与 Borel 的位置

**封闭性清单（严书 7.6.2 引理 + mathlib `AnalyticSet` 族）**：

1. Borel ⊆ 解析（Borel 集是恒等映射的连续像——mathlib
   `MeasurableSet.analyticSet`）；
2. 解析集的**连续像**解析（复合连续——`image_of_
   continuous`）；
3. **可数并/交**封闭（树运算的重组）；
4. **Borel 补的弱化**：解析集的补**未必解析**（真解析
   集存在——Cohen 力迫式的独立性现象在 ZFC 内可证
   "存在非解析的余解析集"）；

**层级图**：Borel ⊊ 解析 ∩ 余解析（**双解析 = Borel**，
Suslin 定理——40.3 的分离定理推论）⊊ 解析 ⊊ 投影 σ-代数。
解析层是"可测性存亡"的边界层：**Lebesgue 可测性在此
边界上被 Choquet 容度拯救（40.4），可测函数的原像正
则性在此延伸**。

## 40.3 Lusin 分离定理：不可分的代价

**Lusin 分离定理（严书 7.6.4-7.6.5 一族 / mathlib
`AnalyticSet.measurablySeparable`）**：两个**不交**解析
集 A, B 可被一个 Borel 集分离：存在 Borel 的 C 使
A ⊆ C 且 C ∩ B = ∅。

**证明骨架（mathlib 的路线与经典同构）**：

1. **树切割**：A、B 各由树表示（Souslin 运算的表示）；
   不交性 ⟹ 两树无公共无限路径；
2. **归纳分层**：定义 R(s) = "s 子树内两表示可分"的
   归纳谓词；根节点可分（整树分离）由不交性 + König
   型引理（无公共路径 ⟹ 某有限层已分离）；
3. **Borel 组装**：分离集 = 分层谓词的 Borel 组合
  （可数树的 Borel 复杂度可控）。∎

**推论三连**：

- **Suslin 定理**：A 与 Aᶜ 都解析 ⟹ A Borel（用 A 分离
  Aᶜ 的补——分离集就是 A 自己）——**双解析 = Borel**，
  "解析世界的自守性"；
- **单值化引踪（Luzin-Novikov）**：解析集上的"多值
  关系"可数片单值化（Borel 片分层）——**可测选择的
  引擎**（第 37 章条件分布的深层零件：图的 Borel 片
  结构使"选版本"合法化）；
- **Borel 同构的刚性**：Borel 空间之间的双射 Borel ⟹
  逆 Borel（图的解析性 + 分离——Kuratowski 定理的
  证明引擎）。

## 40.4 Choquet 容度与可容度性

**容度（choquet capacity）**：集函数 c : 𝓟(X) → [0,∞]
满足：单调、不交递增列上连续（c(∪Aₙ) = lim c(Aₙ)、
Aₙ 递增）、紧集上的内连续——**测度的"非可加版"**（容许
超越 σ-可加性的序结构）。

**Choquet 容度定理（严书 7.6.7 型）**：解析集对**一切**
Choquet 容度可容度（capacitable）：

  c(A) = sup{c(K) : K ⊆ A 紧}——解析集的容度可从内部
  用紧集逼近（正则性的解析版！第 25 章三明治在解析层
  的延伸）。

**证明骨架（对角化）**：树表示的有限层截断给下降的
紧逼近列 K_s；容度的连续性沿树递归传递；König 引理
收无限路径成紧集 K ⊆ A 且 c(K) ≥ c(A) − ε。∎

**应用：解析集的 Lebesgue 可测性**——Lebesgue 外测度
（限制到解析集上）是 Choquet 容度 ⟹ 解析集可容度 ⟹
解析集 Lebesgue 可测（内紧正则）——**投影不毁 Lebesgue
可测性**（虽然毁 Borel 性）。这回答了本章开篇问题的
最终版：Borel → 投影 → 解析（可能非 Borel）但仍在
Lebesgue 世界内。**配套定理**：解析集上的测度正则性、
解析集的截口结构（可数 Borel 片）——随机过程理论的
"存在性安全带"（第 43 章可分修饰与第 37 章条件分布的
最终地基）。

## 40.5 与本书结构的接口

解析集理论是**第五幕的地基工程**：① 条件分布（37 章）
的存在性证明在一般空间上需要 Luzin-Novikov 的选择引理
（标准 Borel 的减免条款是 Polish 牌照的红利）；② 随机
过程（43 章）的轨道可测性（本质 sup 的可测化）走解析
集的截口定理；③ 弱收敛（31-34 章）的可度量化在解析
子集上的稳定性。**教学定位**：本章是"测度论的防御性
深度"——为后文的构造性操作（选择、投影、逐点极值）
发放安全许可证。mathlib 的形式化（`AnalyticSet` 三件
+ 容度链）比原计划预想的完整——B7 实测翻案后，本章
Lean 通道从"分工"升级为正户。

## 40.6 Lean：AnalyticSet 三件套

`Ch40AnalyticSets.lean` 实弹：

1. **锚点 #check**：`MeasureTheory.AnalyticSet`（定义：
   Polish 连续像）、`AnalyticSet.image_of_continuous`
  （封闭性）、`MeasurableSet.analyticSet`（Borel ⊆
   解析）；
2. **分离定理引用**：`AnalyticSet.measurablySeparable`
  （Lusin 分离的机器版）与 `MeasurablySeparable` 谓词
   的正名；
3. **实弹**：ℝ 上 Borel 集的解析户口（`MeasurableSet.
   analyticSet` 的 instance 化调用）+ 区间/cantor 型
   集合的登记账。

## 40.6.5 实验断言清单（数值通道验收单）

1. **Souslin 有限版**：深度 d ≤ 6 的二叉树、𝓕 = 基础
   区间族——A(𝓕) 的显式集合账（路径 2^d 条的交之并）
   与 Borel 闭包（有限模型的补/并饱和）的对照：小模型
   取等（退化注记）；
2. **投影**：网格多边形 E ⊆ [0,1]² 的 x-投影 = 区间并
  （数值投影与解析对照误差 < 网格宽）；
3. **分离**：不交"解析"对的分离集构造（有限模型中
   一步到位——与无限内容的对照注记）；
4. **容度**：c = 计数容度（有限模型）的可容度性穷举
  （sup_{紧⊆A} c(K) = c(A) 的有限验证）；
5. **树统计**：路径数、节点数、复杂度的对照表（描述
   集合论的"规模直觉"数字化）。

## 40.7 数值实验：Souslin 运算的有限模型

**Julia（`40_analytic_sets.jl`）**：

- **Souslin 运算的有限版**：有限字母 {0,1} 的有限深度
  树（深度 d ≤ 6），集类 𝓕 = 二元区间族——实现
  A(𝓕) = ∪_{路径} ∩_{层} F_{σ|n} 的显式计算（路径
  有限：2^d 条），验证：Borel（有限并交闭包）⊆ A(𝓕)
  且小模型上取等（有限世界的 Souslin 退化）；
- **投影实验**：ℝ² 网格 Borel 集（多边形）投影到 x
  轴的数值投影 + 投影像与 Borel 候选的对照（网格上
  一切集合"Borel"——有限世界的塌缩，如实记录）；
- **分离的演示**：两个不交"解析"集（有限模型 = 任意
  集）的 Borel 分离集构造（有限世界平凡成立——与
  Lusin 定理的无限内容对照注记）。

**Python（`40_analytic_sets.py`）**：Fraction/整数版——
树运算的精确实现（深度 ≤ 8 的路径枚举与交集账）、
Souslin 壳 vs Borel 闭包的有限对照表、容度可容度性的
有限演示（c(K) 逼近 c(A) 的紧穷举）。

**Prolog（`40_analytic_sets.pl`）**：符号版——树谓词
`path/2`（无限路径的有限影子）、`souslin/2`（沿路径交
之并）、封闭性检查器。

## 40.7.5 历史注记与描述集合论的入口

Souslin（1917，24 岁）发现 Borel 投影的漏洞并创立解析
集理论，次年早逝——Luzin 学派（Moscow）的系统化由
Luzin-Novikov-Keldysh 完成。"Analytic set"与实分析中
的"analytic"（全纯）毫无关系——**描述集合论**（可定义
性的层级研究）由此发端：Borel 层级（23 章 23.4.6）→
投影层级（解析 = Σ¹₁、余解析 = Π¹₁、Σ¹₂ …）→ 确定性
公理的大漠（Martin、Woodin）。本书止步于 Σ¹₁ 层——
恰好是"概率论安全使用投影"的执照边界。mathlib 的
`AnalyticSet` 形式化（2020s，Källén 等人）沿 Lusin 的
经典路线：树表示 + König 引理 + 分离定理——本章 Lean
锚点直接承接这条百年管线。

## 40.8 要点回顾

1. 解析集 = Polish 连续像 = Borel 的 Souslin 壳；投影
  （∃ 量词）不保 Borel 但落进解析层。
2. 封闭性：连续像/可数并交；补不一定解析——层级
   Borel ⊊ 双解析（= Borel，Suslin）⊊ 解析。
3. Lusin 分离：不交解析集可 Borel 分离——树切割 +
   归纳分层的证明；推论：Suslin 定理、Luzin-Novikov
   单值化、Borel 同构刚性。
4. Choquet 容度定理：解析集可容度（紧内逼近）——解析
   集 Lebesgue 可测；投影不毁可测性的最终答案。
5. 机器侧：mathlib AnalyticSet 三件套 + 分离定理
  （B7 翻案）；数值通道有限树的 Souslin 运算。

*对应示例：`examples/lean/Measuretheory/Ch40AnalyticSets.lean`、
`examples/julia/40_analytic_sets.jl`、`examples/python/40_analytic_sets.py`、
`examples/prolog/40_analytic_sets.pl`。*

---

上一章：[39 本性上确界：忽略零测的最大值](39-esssup.md) · 下一章：[41 鞅与 Doob 不等式：公平游戏的纪律](41-martingale-inequalities.md)
