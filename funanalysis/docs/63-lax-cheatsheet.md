# 63 · Lax 增补篇收官：CHEATSheet 与两书路线总对照

> 第二卷的地图：Lax 的 38 章如何折叠进本教程的 48–62 章，
> 两本书在哪些路口会师，哪些内容各自独有。

## 63.1 章节对照总表

| Lax 原书 | 本教程 | 承载方式 | 会师点 |
|---|---|---|---|
| 1 线性空间 / 2 线性映射（代数指标） | 01, 45 | 第一卷已有 | 代数指标 → Fredholm 指标 |
| 3 Hahn-Banach | 15 | 第一卷已有 | — |
| 4 HB 应用（Banach 极限/不变测度） | **49** | 本卷 | Agnew-Morse ↔ 51 章 Cesàro |
| 5 赋范空间（Sobolev 嵌入、Mazur-Ulam） | 14, 48 | 部分第一卷 | H₀¹ 完备化 → 48 章 |
| 6 Hilbert 空间（Lax-Milgram） | 02–04, **48** | 两卷互补 | Riesz ↔ Lax-Milgram |
| 7 Hilbert 应用（Radon-Nikodym/Dirichlet） | **48** | 本卷 | 三路线表 |
| 8 对偶（支撑函数） | 17 | 第一卷已有 | 零化子判据 ↔ 50 章 |
| 9 对偶应用（Müntz/Runge/变分） | **50** | 本卷 | Blaschke ↔ 62 章 |
| 10 弱收敛（Helly/PUB） | 23, 51 | 两卷互补 | 推论 1′ 受害者机制 |
| 11 弱收敛应用（Toeplitz/发散/Galerkin） | **51** | 本卷 | δ 判据 ↔ 49 章不变平均 |
| 12 弱拓扑（Alaoglu） | 23 | 第一卷已有 | — |
| 13 局部凸/Krein-Milman/Choquet | 20–21, 25 | 第一卷已有 | 完全单调 ↔ 44 矩问题 |
| 14 凸集极端点（Bochner/Hamburger） | 25, 44 | 第一卷已有 | **58 章算子论会师** |
| 15 有界算子（开映射/闭图像） | 18–19 | 第一卷已有 | — |
| 16 有界算子例（Riesz 凸性/Hilbert 变换） | **52** | 本卷 | Hankel 常数 π ↔ 55 章 |
| 17–19 Banach 代数/Gelfand/B* | 29–34 | 第一卷已有 | 19.6 → **53 章** |
| 20 算子谱例（移位/Volterra） | 06, 46 | 第一卷已有 | — |
| 21–23 紧算子/Fredholm/正紧 | 10–13, 28, 45 | 第一卷已有 | 24 → **54 章** |
| 24 Fredholm 行列式 | **54** | 本卷 | 迹公式 → **56 章** |
| 25 不变子空间 | 40 | 第一卷已有 | — |
| 26 半直线调和（Phragmén-Lindelöf） | （概览） | 61 章提及 | 渐近展开 |
| 27 指标论（Noether/Toeplitz/Hankel） | 45, **55** | 两卷互补 | 绕数 = 拓扑进入算子 |
| 28–29 紧对称/其例（Courant-Fischer） | 12–13, 28 | 第一卷已有 | 变分原理 ↔ 48 章 |
| 30 迹类/迹公式/Lidskii/Mercer | **56** | 本卷 | Hilbert 矩阵反例 ↔ 52 |
| 31 对称/正规/酉谱论 | 36–37 | 第一卷已有 | — |
| 32 自伴谱论（Herglotz 路线） | 42, **57** | 两卷姊妹篇 | Cayley ↔ Cauchy 变换 |
| 33 自伴算子例（Friedrichs/Rellich/矩问题） | 42, 44, **58** | 两卷互补 | **44 ↔ 58 会师** |
| 34 半群（Hille-Yosida/Lax 等价/Trotter） | **59** | 本卷 | 数值 PDE 元定理 |
| 35 酉群（Stone/遍历/Koopman/Weyl） | 43, 44, **60–61** | 两卷互补 | Stone ↔ **60 章** |
| 36 半群例（Lax-Phillips 半群） | （概览） | 61 章提及 | — |
| 37 散射理论 | **61** | 本卷 | LP 理论概览 |
| 38 Beurling 定理 | **62** | 本卷 | Blaschke 回归 |
| 附录 B 分布 | 22 | 第一卷已有 | — |

## 63.2 第二卷的十个大定理（一页速查）

1. **Lax-Milgram**（48）：强制双线性形式的表示存在唯一；
   ‖A⁻¹‖ ≤ 1/b。
2. **Agnew-Morse 不变 HB**（49）：交换算子群下不变的延拓存在
   ——凸组合磨光 + Cesàro 几何级数。
3. **Müntz**（50）：{t^{λⱼ}} 张成 ⟺ Σ1/λⱼ = ∞（Blaschke 证明）。
4. **Riesz-Thorin**（52）：两端有界 ⟹ 中间有界且范数对数凸
   （三线定理 + 解析族）。
5. **Wiener Tauberian**（53）：ᶠ ≠ 0 ⟺ 平移张成（e − h + f*f^c）。
6. **Fredholm 迹公式**（54/56）：D(λ) = Π(1−λλⱼ)，∫K 对角 = Σλⱼ。
7. **Toeplitz 指标**（55）：ind T_s = −W(s)；W = 0 时 Wiener-Hopf
   反演 u = s₊⁻¹P₊(s₋⁻¹f)。
8. **Lidskii**（56）：迹类的 tr T = Σλⱼ（Weyl 不等式 + 整函数）。
9. **Hille-Yosida + Lax 等价**（59）：(20) ⟺ 压缩半群；相容+稳定
   ⟺ 收敛。
10. **Beurling**（62）：H⁺ 的闭不变子空间 = pH⁺（Halmos：M 一维，
    |m|² 纯直流）。

## 63.3 两书的风格差异（读法建议）

| | Conway（第一卷底本） | Lax（第二卷底本） |
|---|---|---|
| 组织 | 单线上升（Hilbert→Banach→代数→谱） | 理论章+应用章交错 |
| 证明 | 算子代数化、抽象化 | 构造性、分析性（常从计算入手） |
| 独有 | vN 代数、Calkin、本质谱、自伴扩张分类 | Banach 极限、Fredholm 行列式、迹类、半群、遍历、散射、Beurling |
| 气质 | 教科书的完备 | 讲座的灵感（"astonishing proof"） |

**读法**：第一卷 42 章（Cayley 路线）与 57 章（Herglotz 路线）
对照读；44 章（矩问题数值）与 58 章（算子论证明）对照读；
54–56 章一条 Fredholm 行列式 → 迹类的长线；59–62 是 Conway 完全
不覆盖的领域。

## 63.4 第二卷通道速查

| 章 | Lean | Isabelle | Julia | Python | Prolog |
|---|---|---|---|---|---|
| 48 | ✓ LaxMilgram 官方+手写 | ✓ FA48 | ✓ | ✓ | — |
| 49 | ✓ limsup | — | ✓ | ✓ | ✓ |
| 50–52 | — | — | ✓ | ✓ | — |
| 53 | — | — | ✓ | ✓ | — |
| 54 | — | ✓ FA54 | ✓ | ✓ | — |
| 55 | — | — | ✓ | ✓ | — |
| 56 | ✓ trace 锚点 | — | ✓ | ✓ | — |
| 57–59 | — | — | ✓ | ✓ | — |
| 60 | ✓ MeanErgodic | — | ✓ | ✓ | — |
| 61–62 | — | — | ✓ | ✓ | — |

## 63.5 第二卷实测坑总账（工程侧）

1. Isabelle 假语法错误（类型重建失败伪装 Malformed，须 ∀(f::real²)）
2. Isabelle real^2 索引 1 基（χ i j 用 i=1∧j=1）
3. Julia `x ∈ (a,b)` 是元组成员资格
4. Golub-Welsch βᵢ 分子有 i；权重 = 特征向量首分量平方
5. Julia Dict 迭代无序（对照表用有序对）
6. eigen 列随 reverse(values) 同步 reverse
7. min 核网格 (j−0.5)/n 对齐
8. Wiener-Hopf 因子顺序（s₊⁻¹P₊s₋⁻¹f 不可换）
9. Nevanlinna 收敛常数 = 二阶矩；y 须远离谱支撑
10. 谱投影 (R(z)u,u) 须平方权重配对
11. 打靶散射条件数爆炸 → 格点色散匹配
12. 中心差分丢减号（ΔA 随 σ 线性）
13. svd 瘦分解不含零方向（矩形须 full=true）
14. Poisson 矩阵乘须乘 dθ（行和 = 1/dθ）
15. 隐式迎风 C=0.5 在 Nyquist 奇异（放大因子分母零点）
16. 倍增映射格点 2-1 非置换但逐迭代均值恒定
17. Volterra 是"HS 非迹类"的正确标本（e^{−|x−y|} 其实迹类）
18. 本树 mathlib 有 LaxMilgram/MeanErgodic（初判"无"是错的）

## 63.6 总收官

第一卷（01–46）+ CHEATSheet（47）：Conway 全书。
第二卷（48–62）+ 本表（63）：Lax 全书主干。
五通道：Lean 6 个官方定理锚点 + 4 章手写；Isabelle 2 个会话；
Julia/Python 32 个实验文件；Prolog 2 个推理器。

**全部 48 + 16 = 64 章的定理骨架、证明思想、数值化身与实测坑账
都在你手上。合卷。**

---

上一章：[62 Beurling 定理与 Hardy 空间](docs/62-beurling-hardy.md) · [返回目录](README.md)
