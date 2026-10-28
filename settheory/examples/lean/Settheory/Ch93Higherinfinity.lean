import Mathlib.Tactic

/-!
# 第 93 章 · 高阶无穷导引：有限强度 DAG

四个节点依次表示 ZFC、加入可测基数、加入超紧基数、以及同时采用
超紧与武丁见证的联合假设。边只记录本书选用的相对强度阅读路线，
不是全部大基数的完备排序，更不是相容性的机器证明。
-/

namespace Settheory.Ch93

inductive Node where
  | zfc | measurable | supercompact | woodinWitness
  deriving DecidableEq, Repr

def Node.rank : Node → ℕ
  | .zfc => 0
  | .measurable => 1
  | .supercompact => 2
  | .woodinWitness => 3

inductive Step : Node → Node → Prop where
  | zfcMeasurable : Step .zfc .measurable
  | measurableSupercompact : Step .measurable .supercompact
  | supercompactWoodin : Step .supercompact .woodinWitness

inductive Reach : Node → Node → Prop where
  | refl (x : Node) : Reach x x
  | tail {x y z : Node} : Reach x y → Step y z → Reach x z

theorem Reach.trans {x y z : Node} (hxy : Reach x y) : Reach y z → Reach x z
  | .refl _ => hxy
  | .tail hyz hstep => (Reach.trans hxy hyz).tail hstep

theorem Step.rank_lt {x y : Node} (h : Step x y) : x.rank < y.rank := by
  cases h <;> decide

theorem Reach.rank_le {x y : Node} (h : Reach x y) : x.rank ≤ y.rank := by
  induction h with
  | refl => exact Nat.le_refl _
  | tail _ hs ih => exact Nat.le_trans ih (Nat.le_of_lt hs.rank_lt)

/-- 有向边不能沿可达关系返回：有限秩严格增加，故图无环。 -/
theorem Step.not_reach_back {x y : Node} (h : Step x y) : ¬ Reach y x := by
  intro back
  exact (Nat.not_lt_of_ge back.rank_le) h.rank_lt

/-- 本章导读使用的路径：ZFC → 可测 → 超紧 → 超紧与武丁见证的联合假设。 -/
theorem guidePath : Reach .zfc .woodinWitness :=
  (((Reach.refl .zfc).tail .zfcMeasurable).tail
    .measurableSupercompact).tail .supercompactWoodin

example : ¬ Reach .woodinWitness .supercompact :=
  Step.not_reach_back .supercompactWoodin

end Settheory.Ch93
