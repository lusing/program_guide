# 03 · 正交性与投影定理

> Hilbert 空间最伟大的优势，是它内建的正交概念。——Conway §I.2 开篇（意译）

第 02 章把范数建立在内积上；本章反过来看：内积给出的**几何**——垂直、
投影、直角分解——是 Hilbert 空间区别于一般 Banach 空间的全部天赋。
覆盖 Conway §I.2 全部内容：勾股定理、平行四边形恒等式、闭凸集最近点
定理（Hilbert 投影定理）、正交投影算子、M⊥⊥ = M 与闭线性张成。

## 3.1 正交、勾股与平行四边形

**定义（Conway 2.1）**。ℋ 中 f ⊥ g 当且仅当 ⟨f, g⟩ = 0。A ⊥ B 当且仅当
A 中每个向量垂直于 B 中每个向量。对 A ⊆ ℋ，A⊥ = {f : ∀g ∈ A, ⟨f, g⟩ = 0}。

A⊥ 是**闭**线性子空间（内积连续性的直接推论——第 02 章的极化恒等式
保证内积对范数连续）。

**定理（勾股，Conway 2.2）**。f₁, …, fₙ 两两正交，则

‖f₁ + ⋯ + fₙ‖² = ‖f₁‖² + ⋯ + ‖fₙ‖²。

**证明**。n = 2 时由极化恒等式 ‖f+g‖² = ‖f‖² + 2Re⟨f,g⟩ + ‖g‖² 与
⟨f,g⟩ = 0 即得；对 n 归纳。∎

注意：若 f ⊥ g，则 ‖f - g‖² = ‖f‖² + ‖g‖² 同样成立（把 g 换成 -g）。
这个"减法版"马上要用。

**定理（平行四边形恒等式，Conway 2.3）**。对任意 f, g（不需要正交！）：

‖f + g‖² + ‖f - g‖² = 2(‖f‖² + ‖g‖²)。

**证明**。两条极化恒等式（加、减）相加，交叉项 ±2Re⟨f,g⟩ 相消。∎

平行四边形恒等式是**内积范数的指纹**：第 00 章的数值实验已经展示 ℓ¹
范数破坏它（对抗样本 x = (1,1), y = (1,-1) 上比值恰为 1/2）；第 14 章
将证明逆命题——满足它的范数必来自某个内积（Jordan-von Neumann 定理）。
机器通道里，Lean 的 `parallelogram_law_with_norm` 与 Isabelle 的
`fa_parallelogram` 都只有三行，因为它的证明真的只是两条恒等式相加。

## 3.2 闭凸集上的最近点：Hilbert 投影定理

**定义（Conway 2.4）**。A 凸：∀x, y ∈ A, 0 ≤ t ≤ 1, tx + (1-t)y ∈ A。

线性子空间、单点集、开球闭球都凸；凸集之交凸。凸性是"取平均"的
封闭性——下面的证明唯一用到它的地方，是对两个最近点候选取中点。

**定理（Conway 2.5）**。ℋ Hilbert，K ⊆ ℋ 非空闭凸，h ∈ ℋ。则存在唯一
k₀ ∈ K 使 ‖h - k₀‖ = dist(h, K) := inf{‖h - k‖ : k ∈ K}。

**证明**（平移后设 h = 0）。取极小化序列 ‖kₙ‖ → d := dist(0, K)。
对 kₙ, kₘ 用平行四边形恒等式（减法版，作用于 kₙ + kₘ 与 kₙ - kₘ，
注意 (kₙ+kₘ)/2 ∈ K 由凸性）：

‖kₙ - kₘ‖² = 2‖kₙ‖² + 2‖kₘ‖² - ‖kₙ + kₘ‖² ≤ 2‖kₙ‖² + 2‖kₘ‖² - 4d²。

右端 → 0，故 (kₙ) 柯西；完备性给出极限 k₀ ∈ K（闭），且 ‖k₀‖ = d。

唯一性：若 ‖u‖ = ‖v‖ = d，则 (u+v)/2 ∈ K 给 ‖(u+v)/2‖ ≥ d，即
‖u+v‖ ≥ 2d，代入平行四边形恒等式：‖u - v‖² ≤ 2d² + 2d² - 4d² = 0。∎

这个证明是"平行四边形 + 凸性 + 完备性"的三重奏——三者缺一不可：
凸性破缺（如去掉一个点的闭球）则中点不在 K 中；完备性破缺则柯西列
无极限（习题给出具体反例）；没有平行四边形（一般 Banach 空间）则
最近点可能不存在（第 14 章的标准反例：c₀ 中对超平面的距离不可达）。

### 机器化：Lean 的唯一性证明

`examples/lean/Funanalysis/Ch03Projection.lean` 把唯一性完整复现
（存在性引用 mathlib 的 `exists_norm_eq_iInf_of_complete_convex`，
合起来就是 Conway 2.5 全文）：

```lean
theorem fa_minimizer_unique {K : Set F} (hconv : Convex ℝ K) {d : ℝ} {u v : F}
    (huK : u ∈ K) (hvK : v ∈ K)
    (hmin : ∀ w ∈ K, d ≤ ‖w‖) (humin : ‖u‖ = d) (hvmin : ‖v‖ = d) : u = v := by
  -- 中点属于 K（凸性）
  have hm : (2 : ℝ) ⁻¹ • (u + v) ∈ K := by
    have hc := hconv huK hvK (by norm_num : (1 / 2 : ℝ) ∈ Set.Icc 0 1)
    convert hc using 1
    rw [one_sub_one_div_two]
    module
  -- 中点范数 ≥ d ⟹ ‖u + v‖ ≥ 2d
  have hnorm : d ≤ ‖(2 : ℝ) ⁻¹ • (u + v)‖ := hmin _ hm
  have hsmul : ‖(2 : ℝ) ⁻¹ • (u + v)‖ = (2 : ℝ) ⁻¹ * ‖u + v‖ := by
    rw [norm_smul]; simp
  have h2 : 2 * d ≤ ‖u + v‖ := by
    rw [hsmul] at hnorm
    nlinarith [hnorm, two_pos (α := ℝ)]
  -- 平行四边形收尾
  have hpara : ‖u + v‖ ^ 2 + ‖u - v‖ ^ 2 = 2 * (‖u‖ ^ 2 + ‖v‖ ^ 2) :=
    fa_parallelogram_manual u v
  have hle : ‖u - v‖ ^ 2 ≤ 0 := by nlinarith [h2, hpara, humin, hvmin]
  have hzero : ‖u - v‖ = 0 := by
    have := le_antisymm hle (sq_nonneg _)
    exact pow_eq_zero_iff (two_ne_zero) |>.mp this
  exact sub_eq_zero.mp (norm_eq_zero.mp hzero)
```

三个新招数：`module`（新近进入 mathlib 的"模等式自动证明"，把
`(1/2)•u + (1-1/2)•v` 化成 `(2⁻¹)•(u+v)` 这步外包给机器）；
`nlinarith`（从 h2 ≥、hpara 等式、两个范数等式中线性拼出平方差 ≤ 0
——它就是"代入消元"的自动版）；`pow_eq_zero_iff`（非负数的平方为零
则数为零）。整段证明的骨架与纸笔逐句对应。

## 3.3 投影定理与正交投影算子

**定理（Conway 2.6）**。ℳ ≤ ℋ（闭线性子空间），h ∈ ℋ，f₀ 是 ℳ 中离 h
最近的点。则 h - f₀ ∈ ℳ⊥。反之，若 f₀ ∈ ℳ 且 h - f₀ ∈ ℳ⊥，则 f₀ 是
最近点。

**证明**。设 ‖h - f₀‖ = dist(h, ℳ)。对任意 f ∈ ℳ 与 t > 0：
‖h - f₀‖² ≤ ‖h - (f₀ + t f)‖² = ‖h - f₀‖² - 2t·Re⟨h - f₀, f⟩ + t²‖f‖²，
故 2Re⟨h - f₀, f⟩ ≤ t‖f‖² 对一切 t > 0，令 t → 0 得 Re⟨h - f₀, f⟩ ≤ 0；
把 f 换成相位旋转后的 e^{iθ}f 再取 θ 消相位，得 ⟨h - f₀, f⟩ = 0。
反方向是勾股定理：h - f ∈ (h - f₀) + (f₀ - f) 两项正交，
‖h - f‖² = ‖h - f₀‖² + ‖f₀ - f‖² ≥ ‖h - f₀‖²。∎

**定理（Conway 2.7）**。定义 P : ℋ → ℳ，Ph := f₀（h 的最近点）。则：

- (a) P 线性；
- (b) ‖Ph‖ ≤ ‖h‖；
- (c) P² = P（幂等）；
- (d) ker P = ℳ⊥，ran P = ℳ。

**定义（Conway 2.8）**。P 称为 ℋ 到 ℳ 的**正交投影**，记 Pℳ。
（Conway 顺带引入记号 ℳ ≤ ℋ 表示闭线性子空间；"线性流形"指不一定
闭的子空间。）

**推论（Conway 2.9）**。(ℳ⊥)⊥ = ℳ。

**证明**。I - Pℳ 是到 ℳ⊥ 的正交投影（习题），故 (ℳ⊥)⊥ = ker(I - Pℳ) =
ran Pℳ = ℳ。∎

**推论（Conway 2.10-2.11）**。A⊥ 是 A 的闭线性张成 ∨A；线性流形 ℳ
稠密 ⟺ ℳ⊥ = {0}。

——这就是"正交补"的完备字典：取两次补回到闭包。

## 3.4 机器化：mathlib 的投影 API

mathlib 把这一节做成了 `Submodule` 上的投影族。对照表：

| Conway | mathlib | 说明 |
|---|---|---|
| 2.5 存在 | `exists_norm_eq_iInf_of_complete_convex` | 完备凸集最近点 |
| 2.6 | `K.starProjection_inner_eq_zero` | `⟪v - K.starProjection v, w⟫ = 0` |
| 2.6 iff | `K.norm_eq_iInf_iff_inner_eq_zero` | 距离达界 ⟺ 误差正交 |
| 2.7 (c) | `eq_starProjection_of_mem_of_inner_eq_zero` | 唯一性刻画（幂等随之） |
| 2.7 (b) | 勾股分解 `‖v‖² = ‖Pv‖² + ‖v-Pv‖²` | 我们手工证 |
| 2.9 | `K.orthogonal_orthogonal` | Kᗮᗮ = K（需完备性类） |

Lean 文件里的幂等性一行的证明值得细读——它用的是**唯一性刻画**而非
计算：Pv ∈ K 且 Pv - Pv = 0 ⊥ K，故 P(Pv) = Pv：

```lean
example [K.HasOrthogonalProjection] (v : E) :
    K.starProjection (K.starProjection v) = K.starProjection v :=
  K.eq_starProjection_of_mem_of_inner_eq_zero (K.starProjection_apply_mem v)
    (fun _ _ => by rw [sub_self, inner_zero_left])
```

这正是 Conway 2.6 的"反之"部分在起作用：**刻画定理比计算定理更好用**。
范数压缩 ‖Pv‖ ≤ ‖v‖ 我们也手工做了一遍——分解 v = Pv + (v - Pv) 正交，
勾股定理给出 ‖v‖² = ‖Pv‖² + ‖v - Pv‖²，丢掉非负项：

```lean
example [K.HasOrthogonalProjection] (v : E) : ‖K.starProjection v‖ ≤ ‖v‖ := by
  have horth : ⟪K.starProjection v, v - K.starProjection v⟫_ℝ = 0 :=
    real_inner_comm _ _ ▸ K.starProjection_inner_eq_zero v _
      (K.starProjection_apply_mem v)
  have hsplit : v = K.starProjection v + (v - K.starProjection v) := by abel
  have hpy : ‖v‖ ^ 2 = ‖K.starProjection v‖ ^ 2 + ‖v - K.starProjection v‖ ^ 2 := by
    rw [hsplit]
    exact norm_add_sq_eq_norm_sq_add_norm_sq_of_inner_eq_zero _ _ horth
  have hnn : 0 ≤ ‖v - K.starProjection v‖ ^ 2 := sq_nonneg _
  nlinarith
```

注意 `HasOrthogonalProjection` 这个类型类：它编码"这个子空间上投影
存在"，完备子空间自动获得实例——mathlib 用类系统追踪 Conway 定理的
**适用条件**，错误的用法在类型检查时就报错。

## 3.5 机器化：Isabelle 的直线投影 + 机器抓出的一个数学错误

`examples/isabelle/FA03/T03_Projection.thy` 在 real^2 上把投影算到底：
`proj_line_orthogonal`（系数 ⟨v,w⟩/⟨w,w⟩ 给出正交投影）、
`proj_line_unique`（唯一性）、`proj_line_pythagoras`（勾股分解）。

这里发生了一个值得记录的故事。`proj_line_unique` 最初的陈述是
"任何满足正交性 orthogonal (t•w) (v - t•w) 的 t 都等于投影系数"——
直觉上这是 2.6 的唯一性。**但它是错的**：t = 0 平凡满足
orthogonal 0 v（零向量与任何向量正交），而当 v 与 w 不正交时投影系数
非零。机器在构建时的行为立刻暴露了这一点——证明无法完成，检查假设
发现 t = 0 是"平凡解"。修正后的陈述补上 t ≠ 0：

```isabelle
lemma proj_line_unique:
  fixes v w :: "real^2"
  assumes "w \<noteq> 0" and "t \<noteq> 0"
    and "orthogonal (t *\<^sub>R w) (v - t *\<^sub>R w)"
  shows "t *\<^sub>R w = (inner v w / inner w w) *\<^sub>R w"
```

这个插曲是形式化的典型收益：**陈述本身的漏洞先于证明失败暴露**。
 Conway 原书 2.5 的唯一性走平行四边形路线而非"正交性刻画"，正是因为
正交性方程 t(⟨w,v⟩ - t⟨w,w⟩) = 0 有 t = 0 这个"寄生根"——二次函数
q(t) = ‖v - tw‖² 的临界点方程 q'(t) = 0 才是单根的。数学文献里这种
"陈述需要打磨"的地方，机器是一面诚实的镜子。

勾股分解引理则展示了 Isar 的中点仪式：

```isabelle
lemma proj_line_pythagoras:
  fixes v w :: "real^2"
  assumes "w \<noteq> 0"
  defines "p \<equiv> (inner v w / inner w w) *\<^sub>R w"
  shows "(norm v)\<^sup>2 = (norm p)\<^sup>2 + (norm (v - p))\<^sup>2"
```

（证明 = 正交性传递 + `fa_pythagoras`，见源文件。）

## 3.6 数值实验：交替投影与 Gram-Schmidt

三个实验（`examples/julia/03_projection.jl`、`examples/python/03_projection.py`）：

**实验 1：交替投影。** 对两个子空间 M1 = {x₁+x₂+x₃ = 0} 与
M2 = {x₃ = 0}，交替作用 P_{M2}∘P_{M1} 收敛到 P_{M1∩M2}。数值上 200
步后与直接投影的差 < 1e-8。这是 von Neumann 交替投影定理的一维
缩影（第 28 章弱紧算子处还会遇到它的抽象形式）。超平面投影公式
`x - (⟨a,x⟩-b)/‖a‖² · a` 是一切的基础——它就是 2.6 的"落体"方向。

**实验 2：Gram-Schmidt。** 线性无关组逐列减去已生成子空间上的投影
（Conway I.4.6 的算法化身，第 05 章的主角）：Q'Q = I 精确到 1e-10，
且新旧列空间逐列相同。

**实验 3：凸集上的最近点对照。** Python 侧用 SLSQP 数值求解
"min ‖x - z‖ s.t. z ∈ 闭球"与解析公式（径向收缩）对照，误差 1e-8；
同时演示**非闭**凸集（开立方 (0,1)³）上距离下确界不可达——每个内点
到角落点 (1,1,1) 的距离严格正，但下确界 0 拿不到。"闭"字在 2.5 里
不是装饰。

## 3.7 精确离散模型：Prolog 的整数几何

`examples/prolog/03_orthogonality.pl` 把本章定理放进整数向量的世界。
自制的分数算术（q(N,D) 带约简）保证**没有浮点误差**：

```prolog
pythagoras_holds(X, Y) :-
    orthogonal(X, Y),
    vec_add(X, Y, S),
    normsq(X, A), normsq(Y, B), normsq(S, C),
    C =:= A + B.
```

对整数向量对 [3,4,0] 与 [4,-3,1]（内积恰为 0）：勾股成立、平行四边形
成立；投影 v = [1,2,3] 到 w = [1,0,1]：系数 4/2 约简为 2/1，
⟨v - 2w, w⟩ = 0 **精确**验证（分数 0/1）。负例同样精确：[1,2,3] 与
[1,1,1]（内积 6 ≠ 0）的"勾股"正确地失败。运行输出：

```
dot([3,4,0],[4,-3,1]) = 0
pythagoras: holds
parallelogram: holds
proj coeff <v,w>/<w,w> = 2/1
projection orthogonality: verified exactly
non-orthogonal pythagoras: correctly fails
```

## 3.8 章末对照表

| Conway | 内容 | Lean | Isabelle | Julia/Python | Prolog |
|---|---|---|---|---|---|
| 2.2 | 勾股 | ✓ 手工+库 | ✓ Isar | ✓ | ✓ 精确 |
| 2.3 | 平行四边形 | ✓ 手工+库 | ✓ Isar | ✓（00 章 L1 反例） | ✓ 精确 |
| 2.5 | 最近点定理 | ✓ 唯一性手工 | — | ✓ 球投影 | — |
| 2.6 | 正交刻画 | ✓ 库 API | ✓ 直线版 | ✓ | ✓ 分数版 |
| 2.7 | 投影算子 | ✓ 幂等+压缩 | — | ✓ QR | — |
| 2.9-2.11 | 双正交补 | ✓ `orthogonal_orthogonal` | — | — | — |

## 3.9 习题

1. **（纸笔）** 证明 A⊥ 是闭子空间；（A∪B)⊥ = A⊥ ∩ B⊥。
2. **（纸笔）** Conway 2.9 的细节：I - Pℳ 是到 ℳ⊥ 的投影。
3. **（纸笔）** 习题：ℋ = 不完备内积空间时给出闭凸集使最近点不存在的
   具体例子（提示：取 ℋ = c₀₀（有限支撑列）完备化前，构造对角线
   逼近序列）。
4. **（机器）** 在 Lean 里证明 (A + B)⊥ ⊇ A⊥ + B⊥ 何时取等？把不等号
   方向的包含证出来（`Submodule.orthogonal_...` 族）。
5. **（数值）** 三子空间交替投影不一定收敛到三交投影（存在反例）。
   数值构造一个三维情形观察震荡或收敛到循环。
6. **（离散）** Prolog：把 `proj_coefficient` 推广到二维子空间
   （Gram-Schmidt 两个生成向量后两次投影），对具体整数矩阵跑通。

---

上一章：[02 inner-product](docs/02-inner-product.md) · 下一章：[04 riesz](docs/04-riesz.md)
