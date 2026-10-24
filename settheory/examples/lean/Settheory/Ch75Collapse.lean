import Mathlib.SetTheory.ZFC.Rank
import Mathlib.SetTheory.ZFC.VonNeumann
import Mathlib.Tactic

/-!
# 第 75 章 · 传递化：刚性与有秩关系（冯琦 §1.10）

mathlib 官方锚点：`ZFSet.rank` 一族（命题 1.21：rank_lt_of_mem、
rank_singleton、rank_empty）、`V_` 累积层次（rank_vonNeumann、
mem_vonNeumann、exists_mem_vonNeumann——定理 1.61 "V = V*" 与
"每个集合住在第 rank+1 层"的官方形态）、`isTransitive_vonNeumann`
（引理 1.11(1)）。定理 1.98（秩映射定理）的一般形态即
`IsWellFounded.rank`——`ZFSet.rank` 正是 ∈ 的良基秩。
有限坍缩器与四个现场由 Coq/Agda/Julia/Python/Prolog 五通道承载。
-/

namespace Settheory.Ch75

open ZFSet

-- ---------- 命题 1.21：秩的基本恒等式 ----------

/-- b ∈ a → RK(b) < RK(a)（命题 1.21(1)）。 -/
theorem rank_lt {x y : ZFSet} (h : y ∈ x) : rank y < rank x := rank_lt_of_mem h

/-- RK(∅) = 0。 -/
theorem rank_empty' : rank (∅ : ZFSet) = 0 := rank_empty

/-- RK({x}) = succ(RK(x))——S∘RK = RK∘S 的 singleton 化身
（命题 1.21(2)：后继与秩可换）。 -/
theorem rank_singleton' (x : ZFSet) : rank {x} = Order.succ (rank x) :=
  rank_singleton x

/-- RK(𝒫(x)) = succ(RK(x))：幂集恰爬一层。 -/
theorem rank_powerset' (x : ZFSet) : rank (powerset x) = Order.succ (rank x) :=
  rank_powerset x

-- ---------- 定义 1.64/定理 1.61：V_ 塔与 V = V* ----------

/-- V_{α+1} = 𝒫(V_α)（定义 1.64 后继款）。 -/
theorem V_succ (o : Ordinal) : V_ (o + 1) = powerset (V_ o) :=
  vonNeumann_add_one o

/-- V_α 传递（引理 1.11(1)）。 -/
theorem V_transitive (o : Ordinal) : IsTransitive (V_ o) :=
  isTransitive_vonNeumann o

/-- 定理 1.61（V = V*）：每个集合都属于某个 V_α。 -/
theorem exists_mem_V (x : ZFSet) : ∃ o, x ∈ V_ o := exists_mem_vonNeumann x

/-- "每个集合住在第 rank+1 层"的精确版：x ∈ V_α ⟺ RK(x) < α
（引理 1.12 的官方形态）。 -/
theorem mem_V_iff {x : ZFSet} {o : Ordinal} : x ∈ V_ o ↔ rank x < o :=
  mem_vonNeumann

/-- RK(V_α) = α——塔的第 α 层秩恰为 α（命题 1.21 的塔版）。 -/
theorem rank_V (o : Ordinal) : rank (V_ o) = o := rank_vonNeumann o

/-- x ⊆ V_{RK(x)}：秩函数给每个集合分层（定理 1.98 的分层读法）。 -/
theorem subset_V_self (x : ZFSet) : x ⊆ V_ (rank x) := subset_vonNeumann_self x

end Settheory.Ch75
