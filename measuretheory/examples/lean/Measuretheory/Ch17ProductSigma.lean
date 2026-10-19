import Mathlib.MeasureTheory.Measure.Prod

/-!
# 第 17 章 乘积可测空间（Lean）

严书 §4.1 / 袁上册 §10.1。mathlib 锚点：`MeasurableSpace.prod`
（乘积 σ-代数——使投影可测的最小 σ-代数）、投影可测
（`measurable_fst`/`measurable_snd`）、配对判据的一半
`Measurable.prodMk`、矩形可测 `MeasurableSet.prod`，以及任意族
版本 `measurable_pi_apply`。

实弹：配对函数的可测性、对角线式预像的显式账（x ↦ (x,−x) 命中
单位方块恰在 x = 0）、柱坐标泛函的可测性。
-/

open MeasureTheory

/-! ## 锚点正名 -/

#check @MeasurableSpace.prod
#check @measurable_fst
#check @measurable_snd
#check @Measurable.prodMk
#check @MeasurableSet.prod
#check @measurable_pi_iff
#check @measurable_pi_apply

/-! ## 投影可测与配对判据 -/

/-- 投影本身可测：fst/snd 是乘积 σ-代数的定义性成员（最小性的
"≥"方向）。 -/
example : Measurable (Prod.fst : ℝ × ℝ → ℝ) := measurable_fst

example : Measurable (Prod.snd : ℝ × ℝ → ℝ) := measurable_snd

/-- 配对判据的一半：分量可测 ⟹ 配对可测。 -/
example (f g : ℝ → ℝ) (hf : Measurable f) (hg : Measurable g) :
    Measurable fun x => (f x, g x) := hf.prodMk hg

/-- 分量可测性的现场：p ↦ (p.1 * p.2, p.2 − p.1)。`measurable_fst`
与 `measurable_snd` 先把投影剥离成两个一元目标，四则运算由
`Measurable.mul`/`Measurable.sub` 收割。 -/
example : Measurable fun p : ℝ × ℝ => (p.1 * p.2, p.2 - p.1) :=
  (measurable_fst.mul measurable_snd).prodMk (measurable_snd.sub measurable_fst)

/-- 复合到 Borel：投影 + 常值幂（连续函数经 Borel 传递）。注意
`Measurable.pow` 是 f^g 双函数版，常值指数走 `pow_const`。 -/
example : Measurable fun p : ℝ × ℝ => (p.1 - p.2) ^ 2 :=
  (measurable_fst.sub measurable_snd).pow_const 2

/-! ## 矩形与预像：一张显式账 -/

/-- 矩形可测：Icc ×ˢ Icc ∈ B ⊗ B（`MeasurableSet.prod`）。 -/
example : MeasurableSet (Set.Icc (0:ℝ) 1 ×ˢ Set.Icc (0:ℝ) 1) :=
  MeasurableSet.prod measurableSet_Icc measurableSet_Icc

/-- 对角线式预像：(x, −x) 落进单位方块 ⟺ x = 0——集合层的显式账
（几何直觉的机器落款）。 -/
example : (fun x : ℝ => (x, -x)) ⁻¹' (Set.Icc (0:ℝ) 1 ×ˢ Set.Icc (0:ℝ) 1) = {0} := by
  ext x
  simp only [Set.mem_preimage, Set.mem_prod, Set.mem_Icc, Set.mem_singleton_iff]
  constructor
  · rintro ⟨⟨h1, -⟩, h3, -⟩
    linarith
  · intro hx
    subst hx
    norm_num

/-- 同一集合由"可测映射的预像"路线再次判为可测——两条判据
（集合层 `MeasurableSet.prod` / 函数层 `Measurable.preimage`）
交汇。 -/
example : MeasurableSet ((fun x : ℝ => (x, -x)) ⁻¹' (Set.Icc (0:ℝ) 1 ×ˢ Set.Icc (0:ℝ) 1)) :=
  MeasurableSet.preimage
    (MeasurableSet.prod measurableSet_Icc measurableSet_Icc)
    (measurable_id.prodMk measurable_id.neg)

/-! ## 任意族：坐标泛函 -/

/-- 序列空间 ℝ^ℕ 上的有限坐标泛函可测（`measurable_pi_apply`），
其组合 p ↦ f 0 + f 1 亦可测——第 17.4 节"每个事件只依赖可数
坐标"的函数侧影子。 -/
example : Measurable fun (f : ℕ → ℝ) => f 0 + f 1 :=
  (measurable_pi_apply 0).add (measurable_pi_apply 1)

/-- `measurable_pi_iff`：到乘积空间的映射可测 ⟺ 每条坐标可测
（配对判据的任意族完全体）。 -/
example (g : ℝ → ℕ → ℝ) (h : ∀ n, Measurable fun x => g x n) :
    Measurable g := measurable_pi_iff.mpr h
