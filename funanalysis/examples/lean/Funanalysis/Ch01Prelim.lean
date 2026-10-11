import Mathlib.Topology.Baire.Lemmas
import Mathlib.Topology.Baire.CompleteMetrizable

/-!
# 第 01 章 · 预备知识：Baire 纲与滤子

对应 `docs/01-prelim.md`。本文件把 Conway 附录 A 中两个后面反复用到的
工具放进机器：

1. **Baire 纲定理**——完备度量空间中可数个开稠密集之交仍稠密；
   它是第 18-19 章（开映射定理、一致有界原理）的引擎。
2. **滤子（filter）**——mathlib 用 `Filter` 统一了"网/序列/邻域"三种
   极限语言；这里验证两个基本趋近事实。
-/

-- **Baire 纲定理（开稠密交集形式）**：Baire 空间中可数交保持稠密
#check @dense_iInter_of_isOpen_nat

-- **实例**：完备度量空间（如 ℝ）是 Baire 空间
example : BaireSpace ℝ := by infer_instance

/-!
## Baire 纲定理的"闭集版"

Conway 附录与 III.12 使用的形式是：非空完备度量空间不能写成
可数个"内部为空的闭集"之并。这正好是开稠密交集形式的逆否命题。
我们完整证明它，作为滤子式推理的热身。
-/

theorem fa_baire_closed {X : Type*} [MetricSpace X] [CompleteSpace X] [Nonempty X]
    (f : ℕ → Set X) (hf₁ : ∀ n, IsClosed (f n)) (hf₂ : ∀ n, interior (f n) = ∅) :
    (⋃ n, f n) ≠ Set.univ := by
  -- 假设并集穷尽全空间
  intro h
  -- 每个 (f n)ᶜ 开且稠密（内部为空 ⟺ 余集稠密）
  have hdense : Dense (⋂ n, (f n)ᶜ) :=
    dense_iInter_of_isOpen_nat
      (fun n => (hf₁ n).isOpen_compl)
      (fun n => interior_eq_empty_iff_dense_compl.mp (hf₂ n))
  -- 余集之交 = 并集之余 = ∅
  have hcomp : (⋃ n, f n)ᶜ = ∅ := by rw [h, Set.compl_univ]
  rw [Set.compl_iUnion] at hcomp
  rw [hcomp] at hdense
  -- 但 ∅ 不稠密（空间非空）
  rw [dense_iff_closure_eq, closure_empty] at hdense
  obtain ⟨x⟩ := ‹Nonempty X›
  exact absurd (show x ∈ (∅ : Set X) from hdense.symm ▸ Set.mem_univ x) (by simp)

/-!
## 滤子：统一的极限语言

`Filter.Tendsto f l l'` 读作"f 沿 l 终于进入 l' 的每个集合"。
序列极限、函数极限、连续性全部是它的特例。
-/

#check @Filter.Tendsto
#check @Filter.Eventually

-- 数列 n/(n+1) → 1：先证 1/(n+1) → 0，再用常量平移
example : Filter.Tendsto (fun n : ℕ => (n : ℝ) / (n + 1)) Filter.atTop (nhds 1) := by
  have h0 : Filter.Tendsto (fun n : ℕ => 1 / (n + 1 : ℝ)) Filter.atTop (nhds 0) :=
    tendsto_one_div_add_atTop_nhds_zero_nat
  have h1 : Filter.Tendsto (fun n : ℕ => 1 - 1 / (n + 1 : ℝ)) Filter.atTop
      (nhds (1 - 0 : ℝ)) := h0.const_sub 1
  have hkey : (fun n : ℕ => (n : ℝ) / (n + 1)) = fun n : ℕ => 1 - 1 / (n + 1 : ℝ) := by
    funext n; field_simp; linarith
  rw [hkey]
  simpa using h1
