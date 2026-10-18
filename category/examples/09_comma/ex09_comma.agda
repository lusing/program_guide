------------------------------------------------------------------------
-- ex09 —— 逗号范畴（Simmons 3.3.4）
-- (Id_leCat ↓ K_1)：对象 = (c, 哑元, Le c 1) ——定义地化简成
-- 主下截面 ↓1。箭头的交换方块拼装见 Coq 版；本文件主打对象对应。
------------------------------------------------------------------------

open import Level using (Level; 0ℓ) renaming (suc to lsuc)
open import Data.Nat using (ℕ; zero; suc)
open import Data.Unit using (⊤; tt)
open import Data.Product using (Σ; _×_; _,_; proj₁; proj₂)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- 03 章同款最小基建
data Le : ℕ → ℕ → Set where
  lerefl : ∀ {n} → Le n n
  lestep : ∀ {m n} → Le m n → Le m (suc n)

le-trans : ∀ {a b c} → Le a b → Le b c → Le a c
le-trans p lerefl = p
le-trans p (lestep q) = lestep (le-trans p q)

-- 逗号对象 (Id ↓ K_1)：B 侧是终范畴（哑元 tt），K_1 恒取 1
record CommaObj : Set where
  constructor mkCommaObj
  field
    cobj : ℕ
    cbob : ⊤                     -- 哑元
    carr : Le cobj 1             -- α : Id c → K₁ b = 1

-- 主下截面 ↓1
SectionDown1 : Set
SectionDown1 = Σ ℕ (λ x → Le x 1)

open CommaObj

toSection : CommaObj → SectionDown1
toSection o = cobj o , carr o

fromSection : SectionDown1 → CommaObj
fromSection (x , α) = mkCommaObj x tt α

-- 哑元被扔掉：往返（截面方向）定义性成立
round-section : ∀ s → toSection (fromSection s) ≡ s
round-section s = refl

-- 两个具体截面元素：0 ≤ 1 与 1 ≤ 1
sec0 : SectionDown1
sec0 = zero , lestep lerefl

sec1 : SectionDown1
sec1 = suc zero , lerefl

demo : cobj (fromSection sec0) ≡ zero
demo = refl
