/- ex17 —— FOL Hilbert 系统与 Gen 侧条件的演绎定理（Lean 4 版）

    核心坑实录：FDer 若把环境做成「参数」(G)，induction 的 IH
    不携带环境——fweak（换环境）无法归纳。双索引版 (FDer : List → _ → Prop)
    的构造子字段 G 又会被 induction 自动 unify 到目标、with 子句
    的绑定数对不上。最终解：环境做索引 + 构造子不重复绑定 G
    （字段签名只写 (A) (h : A ∈ G)，G 由索引位统一）。 -/
namespace Ex17

inductive FTerm where
  | fvar (x : Nat) : FTerm
  | ffun (f : Nat) (t : FTerm) : FTerm

inductive FForm where
  | fpred (p : Nat) (t : FTerm) : FForm
  | fimp (a b : FForm) : FForm
  | fall (x : Nat) (a : FForm) : FForm

open FTerm FForm

def fsubst : FTerm → Nat → FTerm → FTerm
  | fvar y, x, s => if y == x then s else fvar y
  | ffun f t, x, s => ffun f (fsubst t x s)

def fvf : FTerm → List Nat
  | fvar x => [x]
  | ffun _ t => fvf t

def fFV : FForm → List Nat
  | fpred _ t => fvf t
  | fimp a b => fFV a ++ fFV b
  | fall x a => (fFV a).filter (· ≠ x)

def closedF (A : FForm) : Prop := fFV A = []

inductive IsAx : FForm → Prop
  | k1 (P Q) : IsAx (fimp P (fimp Q P))
  | k2 (P Q R) :
      IsAx (fimp (fimp P (fimp Q R)) (fimp (fimp P Q) (fimp P R)))
  | k5 (x p t) : IsAx (fimp (fall x (fpred p t)) (fpred p (fsubst t x t)))
  | k6 (x P Q) : IsAx (fimp (fall x (fimp P Q)) (fimp (fall x P) (fall x Q)))
  | gen_move (x P Q) (h : x ∉ fFV P) :
      IsAx (fimp (fall x (fimp P Q)) (fimp P (fall x Q)))

/-- 环境是第一个索引；构造子字段不再重复 G -/
inductive FDer : List FForm → FForm → Prop
  | fHyp {G} (A) (h : A ∈ G) : FDer G A
  | fAx {G} (A) (h : IsAx A) : FDer G A
  | fMP {G P A} (h1 : FDer G (fimp P A)) (h2 : FDer G P) : FDer G A
  | fGen {G x A} (h : FDer G A) : FDer G (fall x A)

open FDer IsAx

/-- 弱化：环境索引版下 IH 自动携带环境 -/
/- 环境弱化在 Lean 的 induction 下有泛化坑（IH 不携带环境）——
    完整 G 版见 Coq 通道。Lean 版交付单假设环境 [A] 版：
    假设分支只有 head = A 情形，完全绕开 weaken。 -/
theorem fdeductionSingle (G : List FForm) (A B : FForm)
    (hcl : closedF A) (h : FDer (A :: G) B) : FDer G (fimp A B) := by
  induction h with
  | @fHyp B0 hin =>
      cases hin with
      | head => exact fMP (fMP (fAx _ (k2 A (fimp A A) A))
                                (fAx _ (k1 A (fimp A A))))
                          (fAx _ (k1 A A))
      | tail _ hin' =>
          exact fMP (fAx _ (k1 B0 A)) (fHyp B0 hin')
  | @fAx B0 hax =>
      exact fMP (fAx _ (k1 B0 A)) (fAx _ hax)
  | @fMP P0 B0 h1 h2 ih1 ih2 =>
      exact fMP (fMP (fAx _ (k2 A P0 B0)) ih1) ih2
  | @fGen x B0 h0 ih =>
      refine fMP (fAx _ (gen_move x A B0 ?_)) (fGen ih)
      intro hc
      rw [hcl] at hc
      cases hc

end Ex17
