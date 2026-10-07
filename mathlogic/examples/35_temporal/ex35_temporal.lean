/- ex24 —— 时序逻辑与模型检查（Lean 4 版）：CTL 语义 + AG 展开 -/
namespace Ex35

inductive CTL where
  | cAtom (p : Nat) : CTL
  | cNot (a : CTL) : CTL
  | cAnd (a b : CTL) : CTL
  | cEX (a : CTL) : CTL
  | cEU (a b : CTL) : CTL

open CTL

abbrev KTrans := Nat → List Nat
abbrev KLabel := Nat → Nat → Bool

def ksat (k : KTrans) (l : KLabel) (s : Nat) : CTL → Prop
  | cAtom p => l s p
  | cNot a => ¬ ksat k l s a
  | cAnd a b => ksat k l s a ∧ ksat k l s b
  | cEX a => ∃ s', s' ∈ k s ∧ ksat k l s' a
  | cEU a b => ∃ n, ∃ path : List Nat, path[0]? = some s ∧ path.length = n + 1 ∧
      (∀ i, i < n → ksat k l (path[i]?.getD 0) a) ∧
      ksat k l (path[n]?.getD 0) b

/-- AG（有限深度版）：全部可达路径上每步满足 a -/
def agfin2 (k : KTrans) (l : KLabel) (s : Nat) : Nat → CTL → Prop
  | 0, a => ksat k l s a
  | d+1, a => ksat k l s a ∧ ∀ s', s' ∈ k s → agfin2 k l s' d a

/-- 旗舰：AG 的展开等价 -/
theorem agfinUnfold (k : KTrans) (l : KLabel) (s : Nat) (d : Nat) (a : CTL) :
    agfin2 k l s (d+1) a ↔
    ksat k l s a ∧ ∀ s', s' ∈ k s → agfin2 k l s' d a := by
  rfl

/-- EX 的存在见证 -/
theorem exWitness (k : KTrans) (l : KLabel) (s : Nat) (a : CTL)
    (h : ksat k l s (cEX a)) : ∃ s', s' ∈ k s ∧ ksat k l s' a := h

/-- 单步算子的单调性（不动点构件） -/
def exStep (k : KTrans) (Z : Nat → Prop) (s : Nat) : Prop :=
  ∃ s', s' ∈ k s ∧ Z s'

theorem exStepMono (k : KTrans) (Z1 Z2 : Nat → Prop)
    (hsub : ∀ s, Z1 s → Z2 s) : ∀ s, exStep k Z1 s → exStep k Z2 s := by
  intro s ⟨s', hin, hz⟩
  exact ⟨s', hin, hsub s' hz⟩

/-- 现场演示：EX 的传递一步 -/
example (k : KTrans) (l : KLabel) (s : Nat) (a : CTL)
    (h : ksat k l s (cEX a)) : ksat k l s (cEX a) := h

end Ex35
