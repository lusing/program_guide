# 00 · 导引：泛函分析与机器证明

> 人的心智抗拒抽象，除非先看到抽象的必要。数学史从特殊走向一般，
> 而非相反。——John B. Conway，本书前言（意译）

## 0.1 这本教程讲什么

泛函分析研究的是**带拓扑的线性空间，以及其上的线性算子**。这句话里的
三个词各自展开：

- **线性空间**——线性代数的主角：向量、加法、数乘。泛函分析把它从
  有限维解放到无限维。ℓ²（平方可和数列）、L²（平方可积函数）、
  解析函数空间，都是无限维线性空间。
- **拓扑**——"无限维"之后第一件事就是弄清楚"两个向量有多近"，
  以及"序列什么时候收敛"。范数、度量、更一般的局部凸拓扑由此而来。
- **算子**——空间之间的线性映射：微分算子、积分算子、傅里叶变换。
  谱理论（无限维的特征值理论）是它们的深层解剖学。

Conway 的原书前言里有一个精准的观察：两位都自称泛函分析家的数学家可能
互相看不懂对方的工作——共同点只有"一个带一两个（或更多）拓扑的线性
空间"，分歧在于拓扑怎么定义、研究空间的几何还是其上的算子。本书采取
"沿共同线索走"的路线：先 Hilbert 空间（几何最像有限维欧氏空间的
无限维空间），再 Banach 空间，再局部凸与弱拓扑，最后汇入算子谱理论
的深水区（Banach 代数、C* 代数、谱定理、无界算子、Fredholm 理论）。

本教程完整覆盖原书十一个章节与三个附录，但不是原书的翻译：每个定理
我们给完整证明或完整讲解，自包含；Conway 的编号（如 I.3.4）只作为
溯源注记，你不需要原书也能读下去。

## 0.2 为什么配上机器

这本教程的独特之处：每个重要定理都有三种化身。

**化身一：机器证明。** Lean 4 + mathlib4 是主证明通道——定理被形式化为
类型，证明被 kernel 检查，不存在"我觉得这步显然"。Isabelle/HOL 是第二
证明通道：对核心定理做双系统"对拍"，并展示 Isar 风格的证明叙事（人怎么
向机器讲解一个证明）。两套系统各自独立地确认同一条数学，这就像双栏
对账。

**化身二：精确离散模型。** Prolog 通道把定理的有限维影子做成可查询的
程序。勾股定理、投影公式在整数向量与自制分数算术下**逐位精确**成立
——不是浮点近似，而是可执行的正验与反例检测。

**化身三：数值实验。** Julia 与 Python/scipy 两个计算通道做浮点实验：
CBS 不等式的等号条件、Bergman 范数的精确积分对照、交替投影的收敛。
数值实验回答"这个定理在计算上意味着什么"，也暴露"浮点世界里哪些
断言会失真"。

三化身不是噱头。它们对应三种理解：**逻辑的**（证明为什么成立）、
**结构的**（定理在有限维的影子长什么样）、**计算的**（定理如何变成
算法）。读这本书时，建议每个定理都问三个问题：机器能证吗？有限维
影子是什么？数值上表现如何？本教程的章节结构就按这三问组织。

也有机器（目前）证不了的：分布空间（IV.5）、无界算子的 Stone 定理
（X.5）、Fredholm 指标（XI.3）、正规算子重数理论（IX.10）在 mathlib 与
HOL-Analysis 中尚无现成形式化，完整形式化的成本也远超教程规模。对
这些内容，正文给出完整的数学讲解，数值/离散通道给出可计算的部分，
并明确告诉你"机器还证不了什么、为什么"。这本身就是有趣的元知识：
**泛函分析的公理化程度与机器形式化的现状之间的差距图**。

## 0.3 五条通道一览

| 通道 | 工具 | 角色 | 判定协议 |
|---|---|---|---|
| Lean 4 | Lean 4.33.1 + mathlib4 v4.33.1（钉版） | 主证明 | `lake build` 退出码 0、无 error/warning |
| Isabelle | Isabelle2025-2 (HOL-Analysis) | 对拍 + Isar 叙事 | 每章一会话 `isabelle build`，无 failed |
| Julia | 1.13 | 数值一 | 断言全过 + START/END 标记 |
| Python | 3.13 + numpy/scipy | 数值二 | 同上 |
| Prolog | SWI-Prolog（GNU Prolog 抽查） | 精确离散模型 | 同上，输出纯 ASCII |

全部由仓库根目录的 `build.ps1` 对账：

```powershell
pwsh -NoProfile -Command '& ./build.ps1 -All'
```

它会输出 章 × 通道 的矩阵报告，任一预期单元失败即退出码非 0。

## 0.4 机器已经知道哪些泛函分析

本教程后面 47 章的主角，机器现在就知道多少？Lean 通道的
`examples/lean/Funanalysis/Ch00Intro.lean` 用一组 `#check` 给出了
"知识地图"——每一条都是机器对陈述的确认：

```lean
-- Conway I.4.1 的 Cauchy-Schwarz 不等式（CBS）
#check @InnerProductSpace.inner_mul_inner_self_le

-- Conway I.2.5 的闭凸集最近点存在性
#check @exists_norm_eq_iInf_of_complete_convex

-- Conway I.2.6 的投影正交刻画
#check @Submodule.norm_eq_iInf_iff_inner_eq_zero

-- Conway I.3.4 的 Riesz 表示定理
#check @InnerProductSpace.toDual
```

这四行分别对应：CBS 不等式、Hilbert 投影定理（闭凸集最近点存在）、
投影的正交刻画、Riesz 表示定理。注意第三行的完整陈述是

```
Submodule.norm_eq_iInf_iff_inner_eq_zero :
  v ∈ K → (‖u - v‖ = ⨅ w ↦ ‖u - w‖ ↔ ∀ w ∈ K, ⟪u - v, w⟫ = 0)
```

——距离在 v 处取到下确界，当且仅当误差向量与子空间正交。这正是
Conway I.2.6 的原文（Theorem 2.6），一字不差。机器不仅"知道"它，
第 03 章我们会把书上的证明逐行翻译过去。

除了定理，机器还知道**具体的空间是 Hilbert 空间**。`Ch00Intro.lean`
末尾有两个实例搜索：

```lean
example : CompleteSpace ℂ := by infer_instance

example {n : ℕ} : CompleteSpace (EuclideanSpace ℝ (Fin n)) := by infer_instance
```

第一行说 ℂ 自身是一维复 Hilbert 空间（完备）；第二行说任意有限维
欧氏空间完备。`infer_instance` 是 Lean 的实例搜索：数学家说"显然"的
地方，机器给出可检查的"是的，这条实例路径存在"。

Isabelle 通道的对应文件 `examples/isabelle/FA00/T00_Overview.thy` 做了
两件事：用 `thm` 命令确认 `Cauchy_Schwarz_ineq2`（CBS 的绝对值形式）
与 `power2_norm_eq_inner`（极化恒等式）在 HOL-Analysis 中的形态；然后
在 ℝ² 上做一个**具体到数字**的验证——取 x = (3,4)、y = (1,1)，
手算内积与范数，检查 CBS 两边：

```isabelle
lemma cbs_concrete:
  fixes x y :: "real^2"
  defines "x \<equiv> (\<chi> i. if i = 0 then 3 else 4)"
    and "y \<equiv> (\<chi> i. if i = 0 then 1 else 1)"
  shows "(inner x y)\<^sup>2 \<le> (norm x)\<^sup>2 * (norm y)\<^sup>2"
proof -
  have "inner x y = 7"
    unfolding x_def y_def by (simp add: inner_vec_def)
  moreover have "norm x = 5"
    unfolding x_def by (simp add: norm_vec_def L2_set_def)
  moreover have "norm y = sqrt 2"
    unfolding y_def by (simp add: norm_vec_def L2_set_def)
  ultimately show ?thesis by simp
qed
```

内积 7、范数 5 与 √2，于是 49 ≤ 25·2 = 50。这个证明琐碎，但它确立
了一个重要事实：**Isabelle 的 `inner` 与 `norm` 在具体向量上能算出
数字**——后面的数值实验（浮点）与机器证明（符号）之间没有神秘鸿沟。

## 0.5 数值热身：两条通道各自确认基础不等式

第 02 章的主角 CBS 不等式，数值上长什么样？Julia 通道的
`examples/julia/00_intro.jl` 用一千次随机试验检查：

```julia
function cbs_check(x::Vector{Float64}, y::Vector{Float64})
    lhs = abs(dot(x, y))^2
    rhs = dot(x, x) * dot(y, y)
    return lhs <= rhs + eps(rhs) * 8   # 容差：几个 ulp
end
```

注意容差的写法：`eps(rhs) * 8` 是几个"最后位单位"（ulp）。CBS 在精确
算术下恒真，但浮点求值两边各有舍入，等号附近的比较必须留容差。这是
数值通道的第一课：**每个 `@assert` 都要问一句"浮点误差多大"**。

Python 通道的 `examples/python/00_intro.py` 是同一实验的另一套实现
（`numpy` 的 `@` 内积与 `np.linalg.norm`），结论一致。两套实现互为
镜像的意义在于：数值结论不依赖单一库的实现细节。

热身里最有味道的实验是"平行四边形比值"。定义

```julia
function para_ratio(normf::Function, x, y)
    a = normf(x + y)^2 + normf(x - y)^2
    b = 2 * (normf(x)^2 + normf(y)^2)
    return a / b   # 内积范数应恒等于 1
end
```

对欧氏范数，比值恒为 1（平行四边形恒等式，第 03 章定理）。对 ℓ¹
范数 `sum(abs, v)`，比值明显偏离 1——本教程实测一次随机向量对得到
约 0.86（每次随机不同，但 `@assert abs(r1 - 1.0) > 0.1` 稳定成立）。
这预告了一个深刻的定理（第 14 章展开）：**一个范数来自某个内积，
当且仅当它满足平行四边形恒等式**。数值反例先行，定理在后——这就是
本教程"三化身"方法论的运行方式。

## 0.6 全书地图：一张可查询的知识图

Prolog 通道的 `examples/prolog/00_intro.pl` 把整本书的定理依赖关系做成
知识库。基本谓词是 `depends_on(定理, 工具)`，例如：

```prolog
depends_on(open_mapping, baire).                   % III.12
depends_on(uniform_bounded, baire).                % III.14
depends_on(hahn_banach,  zorn).                    % III.6
depends_on(alaoglu,      tychonoff).               % V.3
depends_on(krein_milman, alaoglu).                 % V.7
depends_on(spectral_theorem, spectral_measure).    % IX.2
```

传递闭包只需两行子句：

```prolog
depends_trans(T, D) :- depends_on(T, D).
depends_trans(T, D) :- depends_on(T, M), depends_trans(M, D).
```

然后"哪些定理最终站在 Baire 纲定理上"变成一个查询：

```prolog
baire_descendants(Ds) :-
    findall(T, depends_trans(T, baire), Ds0),
    sort(Ds0, Ds).
```

实际运行输出：

```
theorems ultimately on baire: [closed_graph,open_mapping,uniform_bounded]
theorems ultimately on choice: [alaoglu,banach_limit,banach_stone,
  gelfand_duality,hahn_banach,krein_milman,max_ideal_space,separation,
  stone_weierstrass,tychonoff,zorn]
```

读法：三大原理（开映射、闭图像、一致有界）都是 Baire 纲的后裔——
完备性是它们共同的引擎；而 Hahn-Banach、Banach-Alaoglu、Krein-Milman
这条凸性主线站在选择公理（经 Zorn 或 Tychonoff）上。**泛函分析的
两大公理支柱——完备性与选择公理——各自的势力范围在这张图上清晰
可见**。扇出统计（`tool_fanout/2`，定理名的传递后裔个数）显示
completeness 养活 12 条定理、choice 养活 11 条，谱定理链
`spectral_theorem → spectral_measure → riesz → orthogonal_projection →
closest_point → completeness` 提醒我们：第 IX 章的宏伟建筑最终踩在
第 I 章的投影定理上。这张图会随教程推进不断加边。

## 0.7 记号与约定（重要！）

本教程正文采用 Conway 的约定：**内积对第一变元线性**：

⟨αx + βy, z⟩ = α⟨x, z⟩ + β⟨y, z⟩，  ⟨x, y⟩ = ⟨y, x⟩‾。

而两大证明系统采用了相反的约定——mathlib 的 `inner 𝕜 x y`（记号
`⟪x, y⟫_𝕜`）对**第一变元共轭线性**；Isabelle 的 `real_inner` 类在实
数域上无此分歧（实内积双线性且对称）。因此：

- 实数域 𝔽 = ℝ 上，三方约定完全一致，本教程前几章基本在 ℝ 上做
  机器化，避开这个坑；
- 复数域上，Lean 的 `⟪x, y⟫` 对应本教程正文的 `⟨y, x⟩`——第 07 章
  进入算子理论（必须用 ℂ）时我们会再次强调并给出换算表；
- Isabelle 的复内积（`Complex_Inner`）也有自己的约定，用到时再对照。

这类"约定地雷"是机器化数学的第一课：**形式系统强迫你把口语数学里
默认的每个细节说清楚**——变元在哪个域、线性在哪一边、范数取的是
哪个根。看似繁琐，实则正是形式化的价值所在。

其余记号：𝔽 ∈ {ℝ, ℂ}；Hilbert 空间记作 ℋ；正交补 M⊥；B(x; r) 开球。
距离 dist(h, K) = inf{‖h - k‖ : k ∈ K}。

## 0.8 如何使用本教程

1. **只读 docs/ 也能学**：正文自包含，代码段都嵌在讲解里；
   `examples/` 是同内容的可运行副本，行号以仓库当前版为准。
2. **跑起来**：每章的实验都可以单独运行（如
   `python -I examples/python/02_inner.py`），全量验证用 build.ps1。
3. **对照原书**：Conway 编号贯穿全文，但没有它你不会迷路。
4. **做习题**：每章末的习题分三档（纸笔 / 机器 / 数值），对应三化身。

---

上一章：（本书起点） · 下一章：[01 prelim](docs/01-prelim.md)
