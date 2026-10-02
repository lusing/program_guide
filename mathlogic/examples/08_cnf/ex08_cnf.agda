-- ex08 —— 范式：NNF 与 CNF（Agda 版）
module ex08_cnf where

open import Data.Bool using (Bool; true; false; not; _∧_; _∨_)
open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; cong₂; sym; trans; module ≡-Reasoning)
open ≡-Reasoning

-- ---------- 语言与语义 ----------

data Form : Set where
  fvar : ℕ → Form
  _∧f_ : Form → Form → Form
  _∨f_ : Form → Form → Form
  ¬f_  : Form → Form
  ⊤f ⊥f : Form

eval : (ℕ → Bool) → Form → Bool
eval e (fvar n) = e n
eval e (a ∧f b) = eval e a ∧ eval e b
eval e (a ∨f b) = eval e a ∨ eval e b
eval e (¬f a)   = not (eval e a)
eval e ⊤f       = true
eval e ⊥f       = false

fsize : Form → ℕ
fsize (fvar n)   = 1
fsize (a ∧f b)   = 1 + fsize a + fsize b
fsize (a ∨f b)   = 1 + fsize a + fsize b
fsize (¬f a)     = 1 + fsize a
fsize ⊤f         = 1
fsize ⊥f         = 1

-- ---------- 布尔恒等式（4/8 路真值表） ----------

demorgan₁ : (x y : Bool) → (not x ∨ not y) ≡ not (x ∧ y)
demorgan₁ true  true  = refl
demorgan₁ true  false = refl
demorgan₁ false true  = refl
demorgan₁ false false = refl

demorgan₂ : (x y : Bool) → (not x ∧ not y) ≡ not (x ∨ y)
demorgan₂ true  true  = refl
demorgan₂ true  false = refl
demorgan₂ false true  = refl
demorgan₂ false false = refl

distrib : (x y z : Bool) → (x ∨ (y ∧ z)) ≡ ((x ∨ y) ∧ (x ∨ z))
distrib true  true  true  = refl
distrib true  true  false = refl
distrib true  false true  = refl
distrib true  false false = refl
distrib false true  true  = refl
distrib false true  false = refl
distrib false false true  = refl
distrib false false false = refl

distrib-flip : (x y z : Bool) → ((y ∧ z) ∨ x) ≡ ((y ∨ x) ∧ (z ∨ x))
distrib-flip true  true  true  = refl
distrib-flip true  true  false = refl
distrib-flip true  false true  = refl
distrib-flip true  false false = refl
distrib-flip false true  true  = refl
distrib-flip false true  false = refl
distrib-flip false false true  = refl
distrib-flip false false false = refl

not-not : (x : Bool) → not (not x) ≡ x
not-not true  = refl
not-not false = refl
-- ---------- NNF ----------

mutual
  nnf : Form → Form
  nnf (fvar n)   = fvar n
  nnf (a ∧f b)   = nnf a ∧f nnf b
  nnf (a ∨f b)   = nnf a ∨f nnf b
  nnf (¬f a)     = nneg a
  nnf ⊤f         = ⊤f
  nnf ⊥f         = ⊥f

  nneg : Form → Form
  nneg (fvar n)   = ¬f (fvar n)
  nneg (a ∧f b)   = nneg a ∨f nneg b
  nneg (a ∨f b)   = nneg a ∧f nneg b
  nneg (¬f a)     = nnf a
  nneg ⊤f         = ⊥f
  nneg ⊥f         = ⊤f

mutual
  nnf-correct : (e : ℕ → Bool) (f : Form) → eval e (nnf f) ≡ eval e f
  nnf-correct e (fvar n) = refl
  nnf-correct e (a ∧f b) =
    cong₂ _∧_ (nnf-correct e a) (nnf-correct e b)
  nnf-correct e (a ∨f b) =
    cong₂ _∨_ (nnf-correct e a) (nnf-correct e b)
  nnf-correct e (¬f a) = nneg-correct e a
  nnf-correct e ⊤f = refl
  nnf-correct e ⊥f = refl

  nneg-correct : (e : ℕ → Bool) (f : Form) →
                 eval e (nneg f) ≡ not (eval e f)
  nneg-correct e (fvar n) = refl
  nneg-correct e (a ∧f b) = begin
    eval e (nneg a) ∨ eval e (nneg b)
      ≡⟨ cong₂ _∨_ (nneg-correct e a) (nneg-correct e b) ⟩
    not (eval e a) ∨ not (eval e b)
      ≡⟨ demorgan₁ (eval e a) (eval e b) ⟩
    not (eval e a ∧ eval e b) ∎
  nneg-correct e (a ∨f b) = begin
    eval e (nneg a) ∧ eval e (nneg b)
      ≡⟨ cong₂ _∧_ (nneg-correct e a) (nneg-correct e b) ⟩
    not (eval e a) ∧ not (eval e b)
      ≡⟨ demorgan₂ (eval e a) (eval e b) ⟩
    not (eval e a ∨ eval e b) ∎
  nneg-correct e (¬f a) = begin
    eval e (nnf a)          ≡⟨ nnf-correct e a ⟩
    eval e a                ≡⟨ sym (not-not (eval e a)) ⟩
    not (not (eval e a))    ∎
  nneg-correct e ⊤f = refl
  nneg-correct e ⊥f = refl

-- ---------- CNF ----------

-- ---------- 边界注记 ----------

-- CNF/dist 部分：Agda 的 case tree 按参数序建树——「先约束 p 形状」的
-- 子句会让 var-p 调用整个卡死，换序后 var-q 同病（两侧 ∧ 形状约束互卡）。
-- 完整 CNF 正确性见 Coq 通道（fuel 化 + 0 兜底）与 Lean 通道（构造子显式分派）。

nnf-demo : (e : ℕ → Bool) →
           eval e (nnf (¬f (fvar 0 ∧f fvar 1)))
             ≡ not (eval e (fvar 0 ∧f fvar 1))
nnf-demo e = nnf-correct e (¬f (fvar 0 ∧f fvar 1))
-- ---------- 坑位速记（Agda 侧） ----------
-- - eval e (x ∨f y) 对 rewrite 不可见（在 eval 的 match 里）——
--   用 ≡-Reasoning 链 + cong₂ 组装，iota 步由 defeq 免单；
-- - dist 的重叠子句顺序敏感：具体模式在前，兜底在后；
-- - 布尔恒等式先立成引理（4/8 路真值表），主证明只做链式引用。
