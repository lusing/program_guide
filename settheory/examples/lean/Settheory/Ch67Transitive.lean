import Mathlib.Logic.Function.Basic
import Mathlib.Tactic

/-!
# 第 67 章 · 传递集合与形式理论（冯琦 引言+§1.1-1.2）

同一律（公理 1）= `Set.ext`；康托尔对角线（定理 1.4）；Hilbert 推导
检查器——表达式归纳类型 + 公理模式/MP 识别，验证 P→P 五步链。
-/

namespace Settheory.Ch67

-- ---------- 同一律（公理 1）：双包含即相等 ----------

example (A B : Set ℕ) (h1 : A ⊆ B) (h2 : B ⊆ A) : A = B :=
  Set.ext fun _x => ⟨fun hx => h1 hx, fun hx => h2 hx⟩

-- 命题 1.1 的两个方向合起来：相等 ⟷ 双包含
example (A B : Set ℕ) : A = B → A ⊆ B ∧ B ⊆ A := by
  rintro rfl
  exact ⟨fun _ hx => hx, fun _ hx => hx⟩

-- ---------- 康托尔对角线（定理 1.4 的核心：无满射到幂集） ----------

theorem noSurjOnPowerset (α : Type*) :
    ¬ ∃ f : α → Set α, Function.Surjective f := by
  rintro ⟨f, hf⟩
  -- 对角集合 D = {a | a ∉ f a}（书页 36 的 A = {a ∈ x | a ∉ f(a)}）
  obtain ⟨z, hz⟩ := hf {a | a ∉ f a}
  have key : z ∈ f z ↔ z ∉ f z := by
    conv_lhs => rw [hz]
    exact Iff.rfl
  by_cases h : z ∈ f z
  · exact absurd h (key.mp h)
  · exact h (key.mpr h)

-- ---------- 表达式（定义 1.1 的命题片段） ----------

inductive Fml : Type
  | var (n : Nat)
  | imp (a b : Fml)
  | neg (a : Fml)
deriving DecidableEq

namespace Fml

def eqb : Fml → Fml → Bool
  | var m, var n => m == n
  | imp a₁ b₁, imp a₂ b₂ => eqb a₁ a₂ && eqb b₁ b₂
  | neg a, neg b => eqb a b
  | _, _ => false

end Fml

open Fml

/-- 公理 (c)：P → (Q → P) 的实例识别（Q 无约束） -/
def isAxC : Fml → Bool
  | imp p (imp _ r) => Fml.eqb p r
  | _ => false

/-- 公理 (a)：((P→(Q→R)) → ((P→Q) → (P→R))) 的实例识别 -/
def isAxA : Fml → Bool
  | imp (imp p (imp q r)) (imp (imp p₂ q₂) (imp p₃ r₃)) =>
      Fml.eqb p p₂ && Fml.eqb p p₃ && Fml.eqb q q₂ && Fml.eqb r r₃
  | _ => false

-- ---------- 推导检查器（定义 1.22 + 1.23 的机械实现） ----------

inductive Just : Type
  | axA | axC | mp (i j : Nat)

open Just

/-- 每步：公理实例，或由前面第 i 步（X→Y）与第 j 步（X）分离得 Y -/
def checkAux : List (Fml × Just) → List (Fml × Just) → Bool
  | _, [] => true
  | pre, (f, axA) :: rest => isAxA f && checkAux (pre ++ [(f, axA)]) rest
  | pre, (f, axC) :: rest => isAxC f && checkAux (pre ++ [(f, axC)]) rest
  | pre, (f, mp i j) :: rest =>
      match pre[i]?, pre[j]? with
      | some (imp x y, _), some (x', _) =>
          Fml.eqb x x' && Fml.eqb f y && checkAux (pre ++ [(f, mp i j)]) rest
      | _, _ => false

def check (d : List (Fml × Just)) : Bool := checkAux [] d

-- ---------- P → P 的五步推导（67.6 正文） ----------

def p : Fml := var 0

def chain : List (Fml × Just) :=
  [(imp p (imp (imp p p) p), axC),
   (imp (imp p (imp (imp p p) p)) (imp (imp p (imp p p)) (imp p p)), axA),
   (imp (imp p (imp p p)) (imp p p), mp 1 0),
   (imp p (imp p p), axC),
   (imp p p, mp 2 3)]

theorem chain_ok : check chain = true := by decide

-- 篡改：交换最后一步 MP 的实参（大前提拿成了小前提）——被拒绝
theorem chain_corrupted_rejected :
    check (chain.take 4 ++ [(imp p p, mp 3 2)]) = false := by decide

end Settheory.Ch67
