-- ex03 —— 自然演绎 NJp（Agda 版）：规则即 λ 项
module ex03_njp where

open import Data.Product using (_×_; _,_; proj₁; proj₂)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥)
open import Relation.Nullary using (¬_)

-- ---------- 规则的函数化身（λ 直写） ----------

∧-comm : {P Q : Set} → P × Q → Q × P
∧-comm (p , q) = q , p

∨-comm : {P Q : Set} → P ⊎ Q → Q ⊎ P
∨-comm (inj₁ p) = inj₂ p
∨-comm (inj₂ q) = inj₁ q

de-morgan₁ : {P Q : Set} → ¬ (P ⊎ Q) → ¬ P × ¬ Q
de-morgan₁ h = (λ p → h (inj₁ p)) , (λ q → h (inj₂ q))

de-morgan₂ : {P Q : Set} → ¬ P × ¬ Q → ¬ (P ⊎ Q)
de-morgan₂ (np , nq) (inj₁ p) = np p
de-morgan₂ (np , nq) (inj₂ q) = nq q

mt : {P Q : Set} → (P → Q) → ¬ Q → ¬ P
mt f nq p = nq (f p)

⊥-elim : {P : Set} → ⊥ → P
⊥-elim ()

K : {P Q : Set} → P → Q → P
K p _ = p

-- ---------- Curry-Howard 现场：curry/uncurry 是 →I/E 的代数 ----------

curry : {P Q R : Set} → (P × Q → R) → (P → Q → R)
curry f p q = f (p , q)

uncurry : {P Q R : Set} → (P → Q → R) → (P × Q → R)
uncurry f (p , q) = f p q

-- 坑位速记（Agda 侧）：
-- - ¬_ 展开即 → ⊥；mt 的证据链就是函数复合；
-- - ⊥-elim 对 () 模式：⊥ 无构造子，荒谬模式直接收尾；
-- - de-morgan₂ 的 ¬ (P ⊎ Q) 目标是函数——子句按参数模式（inj₁/inj₂）分支。
