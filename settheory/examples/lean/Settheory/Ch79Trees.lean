import Mathlib.Tactic
import Mathlib.Data.Fin.VecNotation

/-!
# 第 79 章 · 树、苏斯林树、马丁公理与划分定理（冯琦 §2.5–2.6）

无穷树的两条大定理都靠「沿父链秩递减」吃饭：柯尼希引理（定理 2.41）在
有限分叉树里逐次选择「有无穷多个后继」的子节点，严格下降的是节点在选择
序列中的位置；阿朗谢树构造（定理 2.42）则保证树枝的并是 ω₁ 中单射，长度
必小于 ω₁。本文件把有限侧的公共骨架机器化：用「父函数 + 自然数秩」表示
一棵有限树，`ancestor x n` 沿父关系上溯 n 步。主定理 `ancestor_rank`
说上溯 n 步后秩至少下降 n；由此立刻得到两件事——上溯步数超过秩必断
（`ancestor_terminates`，这就是树递归终止、柯尼希构造每步合法的有限侧
依据），以及节点不可能是自己的真祖先（`no_self_ancestor`，无环）。
-/

namespace Settheory.Ch79

/-- 父函数秩树：每个节点带一个自然数秩；除根外每个节点有唯一父节点，
且父节点秩严格小。`root` 的父节点为空。 -/
structure RankedTree (α : Type*) where
  rank : α → ℕ
  parent : α → Option α
  root : α
  parent_root : parent root = none
  rank_lt_parent : ∀ {x y : α}, parent x = some y → rank y < rank x

/-- 沿父关系上溯 n 步：0 步停在 x；n+1 步先上溯 n 步再取父节点。
T 显式写成第一个参数：点记号 `T.ancestor` 才能把它当成接收者。 -/
def RankedTree.ancestor {α : Type*} (T : RankedTree α) (x : α) : ℕ → Option α
  | 0 => some x
  | n+1 => (T.ancestor x n).bind T.parent

/-- 若上溯 n 步到达 z，则 rank z + n ≤ rank x：秩沿父链每步至少减 1。
归纳步对上溯 n 步的结果分情况：none 不可能继续；some w 时拆出中间
节点 w，用 `rank_lt_parent` 再走一格。 -/
theorem RankedTree.ancestor_rank {α : Type*} (T : RankedTree α) (x : α) :
    ∀ {n z}, T.ancestor x n = some z → T.rank z + n ≤ T.rank x
  | 0, z, h => by
    simp only [RankedTree.ancestor] at h
    obtain rfl : x = z := Option.some_inj.mp h
    omega
  | n+1, z, h => by
    cases h₁ : T.ancestor x n with
    | none =>
      simp [RankedTree.ancestor, h₁] at h
    | some w =>
      have h₂ : T.parent w = some z := by simpa [RankedTree.ancestor, h₁] using h
      have hr : T.rank z < T.rank w := T.rank_lt_parent h₂
      have ih : T.rank w + n ≤ T.rank x := T.ancestor_rank x (n := n) h₁
      omega

/-- 上溯 rank x + 1 步必断：秩在有限步内耗尽。
直接对上溯结果分情况，none 即结论；some z 与 ancestor_rank 矛盾。 -/
theorem RankedTree.ancestor_terminates {α : Type*} (T : RankedTree α) (x : α) :
    T.ancestor x (T.rank x + 1) = none := by
  cases hz : T.ancestor x (T.rank x + 1) with
  | none => rfl
  | some z =>
    have := T.ancestor_rank x hz
    omega

/-- 节点不可能是自己的真祖先：父链严格降秩，有限环无处可藏。 -/
theorem RankedTree.no_self_ancestor {α : Type*} (T : RankedTree α) (x : α)
    {n : ℕ} (hn : 0 < n) : T.ancestor x n ≠ some x := by
  intro h
  have := T.ancestor_rank x h
  omega

/-- 三节点链 0←1←2 的具体实例（根 0，秩 = 层数）。 -/
def chain3 : RankedTree (Fin 3) where
  rank := ![0, 1, 2]
  parent := ![none, some 0, some 1]
  root := 0
  parent_root := rfl
  rank_lt_parent := by decide

/-- 从节点 2 上溯 2 步到根 0，上溯 3 步断裂——ancestor 步算的样本核对。 -/
example : RankedTree.ancestor chain3 2 2 = some 0 := by decide
example : RankedTree.ancestor chain3 2 3 = none := by decide

end Settheory.Ch79
