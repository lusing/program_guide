/- ex12 —— Curry–Howard 与析取性质（Lean 4 版） -/

namespace Ex12

inductive Ty where
  | base (n : Nat) : Ty
  | arr (a b : Ty) : Ty
  | sum (a b : Ty) : Ty

inductive Tm where
  | var (x : Nat) : Tm
  | lam (T : Ty) (body : Tm) : Tm
  | app (t1 t2 : Tm) : Tm
  | inl (T : Ty) (t : Tm) : Tm
  | inr (T : Ty) (t : Tm) : Tm
  | case_ (t t1 t2 : Tm) : Tm

open Tm

abbrev Ctx := List Ty

def upd : Ctx → Nat → Ty → Ctx
  | [], 0, T => [T]
  | Γ0 :: Γr, 0, T => T :: Γ0 :: Γr
  | [], n+1, T => .base 0 :: upd [] n T
  | Γ0 :: Γ, n+1, T => Γ0 :: upd Γ n T

def get : Ctx → Nat → Option Ty
  | [], _ => none
  | T :: _, 0 => some T
  | _ :: Γ, n+1 => get Γ n

inductive HasType : Ctx → Tm → Ty → Prop
  | tvar {Γ x T} (h : get Γ x = some T) : HasType Γ (.var x) T
  | tlam {Γ T body T2} (h : HasType (T :: Γ) body T2) :
      HasType Γ (.lam T body) (.arr T T2)
  | tapp {Γ t1 t2 T1 T2} (h1 : HasType Γ t1 (.arr T1 T2)) (h2 : HasType Γ t2 T1) :
      HasType Γ (.app t1 t2) T2
  | tinl {Γ t T1 T2} (h : HasType Γ t T1) : HasType Γ (.inl T2 t) (.sum T1 T2)
  | tinr {Γ t T1 T2} (h : HasType Γ t T2) : HasType Γ (.inr T1 t) (.sum T1 T2)
  | tcase {Γ t t1 t2 T S1 S2}
      (h : HasType Γ t (.sum S1 S2))
      (h1 : HasType (S1 :: Γ) t1 T) (h2 : HasType (S2 :: Γ) t2 T) :
      HasType Γ (.case_ t t1 t2) T

/-- 值：正规证明的语法形式 -/
inductive Value : Tm → Prop
  | vlam {T body} : Value (.lam T body)
  | vinl {T t} : Value (.inl T t)
  | vinr {T t} : Value (.inr T t)

/-- 中性项 -/
inductive Neutral : Tm → Prop
  | nvar (x) : Neutral (.var x)
  | napp {t1 t2} (h : Neutral t1) : Neutral (.app t1 t2)
  | ncase {t t1 t2} (h : Neutral t) : Neutral (.case_ t t1 t2)

theorem getNilNone (x : Nat) : get [] x = none := by cases x <;> rfl

/-- 闭中性项不存在（T 在 neutral 之后——IH 对 T 全称） -/
theorem neutralNotTypedNil : ∀ t, Neutral t →
    ∀ T, ¬ HasType [] t T := by
  intro t hn
  induction hn with
  | nvar x =>
      intro T ht
      cases ht with
      | tvar h' => rw [getNilNone] at h'; exact absurd h' (by simp)
  | napp h1 ih1 =>
      intro T ht
      cases ht with | tapp h1' _ => exact ih1 _ h1'
  | ncase h ih =>
      intro T ht
      cases ht with | tcase h' _ _ => exact ih _ h'

/-- 旗舰一：闭值函数必是 λ -/
theorem canonicalArrow {t T1 T2} (hv : Value t)
    (ht : HasType [] t (.arr T1 T2)) :
    ∃ T' body, t = .lam T' body := by
  cases hv with
  | vlam => exact ⟨_, _, rfl⟩
  | vinl => exact absurd ht (by intro h; cases h)
  | vinr => exact absurd ht (by intro h; cases h)

/-- 旗舰二：析取性质——闭值 ∨ 证明必单侧 -/
theorem disjunctionProperty {t T1 T2} (hv : Value t)
    (ht : HasType [] t (.sum T1 T2)) :
    (∃ t', HasType [] t' T1 ∧ t = .inl T2 t') ∨
    (∃ t', HasType [] t' T2 ∧ t = .inr T1 t') := by
  cases hv with
  | vlam => exact absurd ht (by intro h; cases h)
  | vinl =>
      cases ht with
      | tinl h => exact Or.inl ⟨_, h, rfl⟩
  | vinr =>
      cases ht with
      | tinr h => exact Or.inr ⟨_, h, rfl⟩

#print axioms canonicalArrow
#print axioms disjunctionProperty

/- 坑位速记（Lean 侧）：
   - cases ht 的命名构造子（tapp h1' _ 带名绑定）比编号稳；
   - absurd + by intro h; cases h 一行处理「值形状与类型构造子
     错位」——inversion 在 Lean 里就是 cases + 生成等式矛盾。 -/

end Ex12
