# 24 Riesz 表现定理：从泛函到测量的翻译机

**对应严书 §5.2（pp. 115-118）/ 袁上册 §11.2.3（pdf278-284）。
mathlib `Integral/RieszMarkovKakutani/`（Basic/NNReal/Real 三件）
✓——与严书 Daniell-Stone 路线同构。**

---

## 24.1 问题：积分是唯一的"连续账本"吗

第 15 章 Daniell 问过"从积分公理能不能重建测度"，答案是能。
现在换个问法（更几何）：局部紧 Hausdorff 空间 X 上，**C_c(X)
（紧支撑连续函数）上的正线性泛函** I（线性 + f ≥ 0 ⟹
I(f) ≥ 0 + 某种连续性）——它必然是"关于某个测度的积分"吗？
Riesz（1909 年 Hilbert 空间原型）—Markov（1938）—Kakutani
（1941）定理回答：**是**。这台翻译机把"泛函分析的语言"
（线性泛函、范数、对偶）整体译成"测度论的语言"（Radon 测度、
正则性、紧集的质量）——两条大河在此汇流。本书前 23 章造好
了测度，本章反过来：**手里有泛函，测度现造**。

## 24.2 C_c(X) 的字典

C_c(X) = {f ∈ C(X)：supp f = closure{f ≠ 0} 紧}。三件常用
事实（严书 §5.1 后段，Riesz 的零件库）：

1. **磨光引理（Urysohn 型，严书 5.1.20）**：紧 K ⊆ 开 U
   ⟹ ∃f ∈ C_c(X)：0 ≤ f ≤ 1、K 上 f = 1、supp f ⊆ U——
   "指示函数的连续替身"（第 04 章盒逼近的拓扑升级版）；
2. **单位分解（有限版）**：紧 K 被有限开覆盖 {U₁,…,Uₙ} ⟹
   存在 φᵢ ∈ C_c，φᵢ ≤ 1_{Uᵢ}，Σφᵢ 在 K 上 = 1——把"分块
   记账"从集合语言升级到函数语言；
3. **C_c-开集**（严书 5.2.1-5.2.2）：O 称 C_c-开，若
   O = ∪{[f > 0]：f ∈ C_c, supp f ⊆ O}。关键定理：**C_c-开
   = σ-开（可数紧并）**，且其全体生成 B(X)——**这层"函数
   眼中的开集"是 Daniell 造测度的接口**（第 15 章 C 集族的
   拓扑化身）。

## 24.3 定理与证明骨架（严书 5.2.4 = Daniell-Stone 路线）

**Riesz-Markov-Kakutani 定理**：X 为 LCH，I : C_c(X) → ℝ
正线性泛函。则存在 B(X) 上唯一的 **Radon 测度** μ（正则 +
紧集有限质量，定义见第 25 章）使

  I(f) = ∫ f dμ（一切 f ∈ C_c(X)）。

**证明四步**（严书 pp. 116-118，与第 15 章 Daniell 五步的
平行结构——三层楼的又一次攀登）：

1. **Daniell-Stone 造初步测度**：C_c(X) 是向量格且满足
   Stone 条件（f ∧ 1 ∈ C_c——支撑紧保证），第 15 章机器直接
   给出 σ(C_c-开集) 上的测度 μ 与表示 I(f) = ∫f dμ；
2. **接口对齐**：C_c-开集 = σ-开集（24.2 第 3 条）⟹ μ 落在
   B(X) 的生成系上，账目从"函数开集"翻译成"拓扑开集"；
3. **正则性收割**：磨光引理给内正则（μ(K) ≤ I(g) 的下确界
   控制在紧集上）、σ-开性给外正则（开集是紧的穷竭并）——
   μ 自动是 Radon 测度；
4. **唯一性**：两个 Radon 测度在 C_c 上同账 ⟹ 在 C_c-开集
   上同账（磨光逼近）⟹ 由 π-λ 在 B(X) 上同账（第 06 章机器
   收口）。∎

**与第 15 章的接口表**：Daniell 的 H = C_c(X)（向量格 + Stone
✓），I = 正线性泛函（Daniell 连续性由"紧支撑"自动满足——
这是 C_c 比 C_b 好用的根本原因）；Riesz 多付的是**正则性**
（拓扑分离换来的免费午餐）。

## 24.4 三个立即应用

**应用一（Lebesgue 测度的第二次诞生）**：I(f) = ∫f dx
（Riemann 积分！紧支撑连续函数上良定义）→ Riesz 产出
Lebesgue 测度。**Riemann 积分一直就是 Lebesgue 积分在 C_c
上的化身**——第 15 章"Riemann 体内有 Lebesgue"的定理化。

**应用二（分布函数 ↔ 测度的第三通道）**：ℝ 上右连续递增 F
定义 I(f) = Riemann-Stieltjes ∫f dF（第 05 章 §R-S）——
Riesz 产出 L-S 测度 μ_F。第 05 章的 Carathéodory 路线与本章
泛函路线在 ℝ 上汇合（同一 μ_F、两条构造——π-系唯一性背书）。

**应用三（对偶视角的预告）**：C_c 上的正线性泛函 ↔ 正 Radon
测度；一般（符号）线性泛函的 Jordan 分解（第 12 章）把情形
归约到正的——**第 26 章 C₀(X)* = 符号 Radon 测度**的路线图。

## 24.4.5 Stieltjes 泛函的完整账（应用二的技术细节）

F 右连续递增，I(f) = Riemann-Stieltjes ∫f dF（第 05 章
§R-S 定义在 C_c 上良定义）。要引用 RMK 需验证正线性：
线性是 R-S 积分的线性；**正性**：f ≥ 0 ⟹ I(f) ≥ 0（R-S
上和在非负分划上非负）。RMK 产出 Radon 测度 μ_F 使
I(f) = ∫f dμ_F——**与第 05 章 Carathéodory 路线的 μ_F 是
同一个测度**：两条构造都在半环 (a,b] 上给账 μ_F((a,b]) =
F(b)−F(a)，π-系唯一性（第 06 章）收口。这个三方对账
（Carathéodory §1.5 / Daniell §3.6 / Riesz §5.2）是全书
构造论的复验十字路口。

## 24.5.5 mathlib 构造与严书路线的逐步对应表

| 严书 5.2（Daniell 路线） | mathlib RieszMarkovKakutani |
|---|---|
| 正线性泛函 I : C_c → ℝ | `Λ : C_c(X, ℝ≥0) →ₗ ℝ≥0`（NNReal 版）/ RealRMK |
| C_c-开集 = σ-开集（接口） | `rieszContent`：紧集上的 Content（亚可加内容函数） |
| Daniell-Stone 造 μ | Content 的 Carathéodory 延拓（`rieszMeasure`） |
| 磨光引理给正则性 | `rieszMeasure` 的 Regular instance 证明 |
| 唯一性（π-λ） | `rieszMeasure_integralPositiveLinearMap` |
| 主定理 I(f) = ∫f dμ | `RealRMK.integral_rieszMeasure` |

**两行的教学对位**：严书把"内容函数"藏在 Daniell 机器里，
mathlib 把它显式化为 `rieszContent : Content X`（紧集账本，
亚可加）再延拓——**第 04 章"半环预测度 → 外测度 → 测度"
的两步走，在拓扑层换成"紧集内容 → 外测度 → 测度"**。
读者应在脑内把 24.3 的四步与表中右列逐行对齐——两台机器
是同一台设备的两次装箱。

## 24.7.5 习题账单（自检清单）

1. 验证点评价 I(f) = f(x₀) 是正线性泛函，其 Riesz 测度
   是 δ_{x₀}；计算它在紧集 K 上的账（1_{x₀∈K}）；
2. 证明 C_c(X) 满足 Stone 条件（f ∈ C_c ⟹ f∧1 ∈ C_c）
  ——支撑紧的关键性在哪一步用上？
3. X = ℝ，I(f) = ∫f(x)·x² dx：写出 Riesz 测度的密度并
   验证 I(f) = ∫f dμ（μ = x²·λ）；
4. 用磨光引理证明：紧 K ⊆ 开 U ⟹ 存在 g ∈ C_c 使
   1_K ≤ g ≤ 1_U（三明治函数版——第 25 章的零件）；
5. 两个正线性泛函若在 C_c 上同账，何时可断言 Riesz 测度
   相同？（唯一性的条件清单：Radon 性 + LCH。）

## 24.5 Lean：RieszMarkovKakutani 三件套

mathlib 4.33 实测锚点（`Integral/RieszMarkovKakutani/`）：

- **NNReal 版**（Basic + NNReal.lean）：`rieszContent`
 （Content：紧集上的内容函数）→ `rieszMeasure`（延拓成
  测度）——**内容→测度的两步构造与严书 Daniell 路线同构**；
- **Real 版**（Real.lean，命名空间 `RealRMK`）：
  `RealRMK.rieszMeasure`（实线性泛函 Λ 的表现测度）、
  **`RealRMK.integral_rieszMeasure`（主定理：Λ f =
  ∫ f drieszMeasure Λ）**、`rieszMeasure_integralPositive
  LinearMap`（唯一性）。

`Ch24Riesz.lean` 实弹：锚点 #check 全家福 + **ℝ 上的具体
泛函对账**——取 Λ(f) = f(0) 型点评价泛函（正线性 ✓），其
表现测度应为 δ₀：引用主定理陈述并 `#check` 泛函侧的类型
（`C_c(ℝ, ℝ)` 上 eval 的正线性），数值侧由 Julia 对拍。

## 24.5.6 局部紧的"局部"用量清单

RMK 各步骤对 LCH 的依赖是分层的，逐条清点（哪些空间还能
用哪部分定理）：

| 步骤 | 需要什么 | 弱化空间的后果 |
|---|---|---|
| C_c 向量格 + Stone | LCH（磨光存在） | 正则空间：Urysohn 函数仍可用 |
| Daniell-Stone 造 μ | 纯代数（无需拓扑！） | 任意拓扑下都有"Ba 型"测度 |
| C_c-开 = σ-开 | σ-紧或可数型 | 一般空间：只在 Baire 层对账 |
| 正则性收割 | 磨光 + σ-开 | 非正则空间：μ 可能不正则 |
| 唯一性 | π-λ（抽象） | 唯一性最顽强，几乎总能保住 |

教学结论：**Riesz 定理的可移植性分层**——核心（泛函→
Baire 测度）几乎无条件，装修（正则性→Borel 全层）按拓扑
付款。这解释了为什么不同教材的 RMK 陈述五花八门：各家
按自己的拓扑预算签不同档的合同。

## 24.6 数值实验：泛函→测度的有限版翻译机

**Julia（`24_riesz.jl`）**：X = {0,1,2}（离散拓扑，一切函数
连续且紧支撑）：

- **进料**：权向量 w = (3,5,2)，泛函 I(f) = Σw·f——正线性
  泛函的有限原文；
- **翻译机**：Riesz 说 I = ∫·dμ_w，μ_w({i}) = wᵢ——数值
  验证 I(f) = Σ wᵢf(i) 对随机 500 个 f 逐个成立（平凡的
  恒等式，但流水线就是定理的有限版）；
- **唯一性**：另一权向量 w' 若在一切 f 上同账 ⟹ w' = w
  （取 f = 指示函数即分离）——有限版唯一性证词；
- **点评价**：I(f) = f(1) ⟹ μ = δ₁（w = (0,1,0)）——
  "Dirac 泛函 ↔ Dirac 测度"的翻译条目。

**Python（`24_riesz.py`）**：Fraction 精确版同账 + **区间
版 Riemann 对拍**：X = [0,1]，I(f) = Riemann∫f（中点法
1e-6 精度）对 f = x²、eˣ、多项式——Riesz 产出 Lebesgue：
∫f dλ 的闭式（1/3、e−1、…）与 Riemann 账一致到数值精度——
应用一的机器版。

## 24.6.5 实验断言清单（数值通道验收单）

三通道各出可判定断言（全部 assert 化）：

1. **有限版翻译机**：I(f) = Σwᵢf(i) 与随机 500 个 f 的
   双向账（Julia 浮点 1e-12 / Python Fraction 零误差）；
2. **唯一性有限版**：同账权相等（分离指示函数）；
3. **点评价**：I(f) = f(1) ⟹ 权 = (0,1,0,0,0)；
4. **Riemann 透视**：I = Riemann 积分（中点法 1e-6）对
   f ∈ {x², e^x, sin x + 1}（闭式 1/3、e−1、1+cos1? 核对
   [0,1]：∫sin = 1−cos1）的四个闭式账；
5. **Stieltjes 透视**：F(x) = 1_{[0,∞)}(x)（Heaviside）的
   R-S 账 I(f) = f(0)——δ₀ 的 Riemann-Stieltjes 原文。

## 24.7 要点回顾

1. RMK：C_c(X) 上正线性泛函 ⟺ 正 Radon 测度；证明走
   Daniell-Stone（C_c-开集 = σ-开集是接口）+ 磨光引理
  （正则性免费）+ π-λ（唯一性）。
2. 三条生产线汇流：Carathéodory（第 04/05 章）、Daniell
  （第 15 章）、Riesz（本章）——同一批测度、三套构造。
3. 应用：Riemann 积分透视出 Lebesgue；F 的 R-S 积分透视出
   L-S 测度；符号泛函的 Jordan 分解预告第 26 章。
4. 机器侧：mathlib `rieszContent → rieszMeasure` 两步构造
   与严书同构 + `RealRMK.integral_rieszMeasure` 主定理；
   数值通道把"泛函↔测度"的有限版翻译机跑通。

*对应示例：`examples/lean/Measuretheory/Ch24Riesz.lean`、
`examples/julia/24_riesz.jl`、`examples/python/24_riesz.py`。*

---

上一章：[23 拓扑空间与 Borel σ-代数：测度论安家拓扑](23-topology-borel.md) · 下一章：[25 正则测度与 Radon 测度：内外逼近的银行制度](25-regular-measures.md)
