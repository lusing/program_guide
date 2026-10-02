/- ex06 —— 矢列演算 G（Lean 4 版）
   演算归纳定义 + 「G 天生经典」现场；可靠性旗舰见 Coq 版。 -/

namespace Ex06

inductive SForm where
  | svar (n : Nat) : SForm
  | sand (a b : SForm) : SForm
  | sor (a b : SForm) : SForm
  | simp (a b : SForm) : SForm
  | sneg (a : SForm) : SForm

open SForm

inductive GProv : List SForm → List SForm → Prop
  | gax {Γ Δ} (p : SForm) (h₁ : p ∈ Γ) (h₂ : p ∈ Δ) : GProv Γ Δ
  | gLNeg {Γ Δ} (p) (h : GProv Γ (p :: Δ)) : GProv (sneg p :: Γ) Δ
  | gRNeg {Γ Δ} (p) (h : GProv (p :: Γ) Δ) : GProv Γ (sneg p :: Δ)
  | gLAnd {Γ Δ} (a b) (h : GProv (a :: b :: Γ) Δ) : GProv (sand a b :: Γ) Δ
  | gRAnd {Γ Δ} (a b) (h₁ : GProv Γ (a :: Δ)) (h₂ : GProv Γ (b :: Δ)) :
      GProv Γ (sand a b :: Δ)
  | gLOr {Γ Δ} (a b) (h₁ : GProv (a :: Γ) Δ) (h₂ : GProv (b :: Γ) Δ) :
      GProv (sor a b :: Γ) Δ
  | gROr {Γ Δ} (a b) (h : GProv Γ (a :: b :: Δ)) : GProv Γ (sor a b :: Δ)
  | gLImp {Γ Δ} (a b) (h₁ : GProv Γ (a :: Δ)) (h₂ : GProv (b :: Γ) Δ) :
      GProv (simp a b :: Γ) Δ
  | gRImp {Γ Δ} (a b) (h : GProv (a :: Γ) (b :: Δ)) : GProv Γ (simp a b :: Δ)

open GProv

/-- G 天生经典：⊢ ¬p ∨ p 三步（ROr → RNeg → Ax）。
    顺序注记：规则只在表头引入，先出来的是 ¬p ∨ p。 -/
theorem gLemVar (n : Nat) : GProv [] [sor (sneg (svar n)) (svar n)] := by
  apply GProv.gROr (a := sneg (svar n)) (b := svar n)
  apply GProv.gRNeg (p := svar n)
  exact gax _ (List.Mem.head _) (List.Mem.head _)

/-- ⊢ p → p：矢列版的同一律 -/
theorem gImpId (n : Nat) : GProv [] [simp (svar n) (svar n)] := by
  apply GProv.gRImp (a := svar n) (b := svar n)
  exact gax _ (List.Mem.head _) (List.Mem.head _)

/- 坑位速记（Lean 侧）：
   - apply 带命名参数 (a := …) (b := …) 固定规则实例化方向——
     结论里的 :: Δ 模式让 a b Δ 全靠统一，方向不定；
   - gax 的 Γ Δ 隐式给 _ 即可（由目标定）。 -/

end Ex06
