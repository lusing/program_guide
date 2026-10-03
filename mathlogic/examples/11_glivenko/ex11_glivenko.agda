-- ex11 —— 直觉主义与 Glivenko 现象（Agda 版）
module ex11_glivenko where

open import Data.Empty using (⊥; ⊥-elim)
open import Data.Product using (_×_; _,_)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Nullary using (¬_)

-- ---------- 构件一：三重否定坍缩 ----------

n3 : {A : Set} → ¬ (¬ (¬ A)) → ¬ A
n3 h a = h (λ na → na a)

-- ---------- 构件二：¬¬ 单调 ----------

nn-mono : {A B : Set} → (A → B) → ¬ (¬ A) → ¬ (¬ B)
nn-mono f ha hb = ha (λ a → hb (f a))

-- ---------- 现象：经典原理的 ¬¬ 化 ----------

nn-lem : {A : Set} → ¬ (¬ (A ⊎ ¬ A))
nn-lem h = h (inj₂ (λ a → h (inj₁ a)))

nn-dne : {A : Set} → ¬ (¬ (¬ (¬ A) → A))
nn-dne h = h (λ hnn → ⊥-elim (hnn (λ a → h (λ _ → a))))

nn-demorgan : {A B : Set} → ¬ (A × B) → ¬ (¬ (¬ A ⊎ ¬ B))
nn-demorgan h hn =
  nnA (λ a → nnB (λ b → h (a , b)))
  where
    nnA = λ na → hn (inj₁ na)
    nnB = λ nb → hn (inj₂ nb)

-- 坑位速记（Agda 侧）：
-- - nn-dne 的内层：把 ¬A 喂给 hnn 得 ⊥；¬A 由「向 h 喂常函数」造出——
--   λ _ → a 把 A 的证据转成 ¬¬A → A；
-- - where 里的局部定义按依赖顺序排（nnA/nnB 先声明后使用）；
-- - 全部条款点式书写——无 tactic 可依赖，但每行就是 Curry–Howard 证。
