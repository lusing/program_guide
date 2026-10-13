import Mathlib.SetTheory.ZFC.Rank

/-!
# 第 09 章 · 正则公理、秩层级与 BG 类理论

正则公理禁止 x ∈ x 与无穷 ∈-下降链；宇宙按秩分层
V = ⋃ V_α。mathlib 的 `PSet.rank` 是官方秩函数。
-/

open PSet

/-! ## 一、秩函数的官方形态 -/

/-- 秩的单调性：y ∈ x ⟹ rank y < rank x——下降链不存在。 -/
example {x y : PSet} (h : y ∈ x) : rank y < rank x :=
  PSet.rank_lt_of_mem h

/-- 秩的刻画：rank x ≤ o ⟺ 每个成员的秩 < o。 -/
example {x : PSet} {o : Ordinal} :
    rank x ≤ o ↔ ∀ y, y ∈ x → rank y < o :=
  PSet.rank_le_iff

/-- 外延性兼容：等价的预集合有相同的秩（秩是集合的不变量）。 -/
example {x y : PSet} (h : PSet.Equiv x y) : rank x = rank y :=
  PSet.rank_congr h

/-- 子集单调：x ⊆ y ⟹ rank x ≤ rank y。 -/
example {x y : PSet} (h : x ⊆ y) : rank x ≤ rank y :=
  PSet.rank_mono h

/-! ## 二、正则公理的类型论身份 -/

/-- 在 PSet 世界里，x ∈ x 不可能：rank x < rank x 是矛盾。
    "正则公理"在构造性秩理论中是定理而非公理。 -/
example {x : PSet} (h : x ∈ x) : False :=
  lt_irrefl (rank x) (PSet.rank_lt_of_mem h)

/-! ## 三、累积层级的形态（讲义对照） -/
/-
V₀ = ∅；V_{α+1} = P(V_α)；V_λ = ⋃_{α<λ} V_α。
V = ⋃ V_α（引理 9.3：每个集合都有秩）。
mathlib 的完整 V 层级以 pSet.rank 的性质承载（上方四条锚点）；
数值形态见 Julia/Python 通道。BG 类理论（附录）在 docs 正文。 -/
