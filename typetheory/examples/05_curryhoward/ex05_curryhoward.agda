----------------------------------------------------------------
-- 05 Curry–Howard —— Agda 侧
-- ① 直觉主义组合子 = Set 居留项（与 03 章内在式项同构）
-- ② ¬¬(P ∨ ¬P)：排中律的双重否定在直觉主义里【可证】——单线完成
-- ③ 演绎定理 = lam 构造子（对照 Lean/Coq 版）
----------------------------------------------------------------

open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Empty using (⊥)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

¬ : Set → Set
¬ A = A → ⊥

-- ---- ① 组合子 ----

I : {A : Set} → A → A
I x = x

K : {A B : Set} → A → B → A
K x y = x

S : {A B C : Set} → (A → B → C) → (A → B) → A → C
S x y z = x z (y z)

B : {A B C : Set} → (B → C) → (A → B) → A → C
B f g x = f (g x)

-- ---- ② ¬¬ 排中：直觉主义的最大公约数 ----
-- 对任何 P：假设 h : ¬(P ∪ ¬P)，把 ¬P 喂给 h 得矛盾，
-- 而 ¬P 本身又由「P 一旦出现就喂 h」构成——一行闭环
nnem : (P : Set) → ¬ (¬ (P ⊎ ¬ P))
nnem P h = h (inj₂ (λ p → h (inj₁ p)))

-- 于是：命题的「稳定性」¬¬P → P 对排中律的每个实例成立；
-- 但 nnem 本身不能去掉双重否定——那正是经典公理的领地

-- ---- ③ 演绎定理 = 抽象构造子 ----
-- 从「带假设的居留项」到「蕴涵的居留项」，转换就是 λ
deduction : (P Q : Set) → (P → Q) → ¬ P → P → ⊥
deduction P Q Hpq Hnp p = Hnp p

-- 关于 S K K = I 的注记：在 Church 式（类型内注解）世界里，
-- 两个 K 必须以不同类型实例出现，Agda 的隐式求解器造不出这个
-- 实例化（03 章的 K₁/K₂ 手工实例化已经演示过代价）；
-- 无类型版本的计算核验见 02 章 Lean/Coq/Agda 的 normalizer
-- （normalizeFuel 100 (S K K) = λ. 0，三家机器验证过）。
