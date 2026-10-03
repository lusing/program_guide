-- ex14 —— FOL 语法与代入（Agda 版）
module ex14_folsyntax where

open import Data.Nat using (ℕ; zero; suc; _≡ᵇ_)
open import Data.Bool using (Bool; true; false; if_then_else_; not)
open import Data.Empty using (⊥)
open import Data.List using (List; []; _∷_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Binary.PropositionalEquality
  using (_≡_; refl; cong; sym)

-- ---------- 语法 ----------

data Term : Set where
  tvar : ℕ → Term
  fapp : ℕ → Term → Term

data Form : Set where
  atom : ℕ → Term → Form
  fimp : Form → Form → Form
  fneg : Form → Form
  fall : ℕ → Form → Form

-- ---------- 自由变元 ----------

fv-term : Term → List ℕ
fv-term (tvar x) = x ∷ []
fv-term (fapp f t) = fv-term t

-- ---------- 代入 ----------

substT : Term → ℕ → Term → Term
substT (tvar y) x s = if (y ≡ᵇ x) then s else (tvar y)
substT (fapp f t) x s = fapp f (substT t x s)

substF : Form → ℕ → Term → Form
substF (atom p t) x s = atom p (substT t x s)
substF (fimp a b) x s = fimp (substF a x s) (substF b x s)
substF (fneg a) x s = fneg (substF a x s)
substF (fall y a) x s with (y ≡ᵇ x)
... | true  = fall y a
... | false = fall y (substF a x s)

-- ---------- 语义 ----------

Fenv = ℕ → ℕ → ℕ

eterm : Fenv → (ℕ → ℕ) → Term → ℕ
eterm fe e (tvar x) = e x
eterm fe e (fapp f t) = fe f (eterm fe e t)

eupd : (ℕ → ℕ) → ℕ → ℕ → ℕ → ℕ
eupd e x v m = if (m ≡ᵇ x) then v else e m

-- ---------- 旗舰：项代入与语义代入交换 ----------

substT-eval : (fe : Fenv) (t : Term) (e : ℕ → ℕ) (x : ℕ) (s : Term) →
  eterm fe e (substT t x s)
  ≡ eterm fe (eupd e x (eterm fe e s)) t
substT-eval fe (tvar y) e x s with (y ≡ᵇ x)
-- 外层 with 已把目标里的 (y ≡ᵇ x) 替换为 true/false：
-- true  → LHS = eterm fe e s，RHS 的 eupd 走 if true → refl
-- false → LHS = e y，RHS 的 eupd 走 else → e y → refl
substT-eval fe (tvar y) e x s | true  = refl
substT-eval fe (tvar y) e x s | false = refl
substT-eval fe (fapp f t) e x s =
  cong (fe f) (substT-eval fe t e x s)

-- 展开读法：
-- y ≡ᵇ x = true：substT 后是 s，LHS = eterm fe e s；
--   RHS = eupd e x v y 归约（内层 with 再判一次 y ≡ᵇ x = true）→ v ✓
-- y ≡ᵇ x = false：代入不动，LHS = e y；RHS 的 eupd 走 else → e y ✓ refl。

-- ---------- capture 规则现场 ----------

substF-shadow : substF (fall 3 (atom 0 (tvar 3))) 3 (tvar 7)
                ≡ fall 3 (atom 0 (tvar 3))
substF-shadow with (3 ≡ᵇ 3)
... | true  = refl
... | false = shadow-impossible
  where
  shadow-impossible : fall 3 (atom 0 (tvar 3)) ≡ fall 3 (atom 0 (tvar 3))
  shadow-impossible = refl

-- 坑位速记（Agda 侧）：
-- - 内外两处 (y ≡ᵇ x) 的 with 判定各自归约——true 分支内层
--   with 的同值分支 refl、异值 λ()；
-- - with (3 ≡ᵇ 3) 字面量直接归约 true——shadow 现场直收；
-- - 环境级 RHS：eterm fe (eupd e x v) t（与 Coq 版同坑）。