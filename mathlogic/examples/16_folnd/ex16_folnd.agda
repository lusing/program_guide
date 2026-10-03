-- ex16 —— FOL 自然演绎（Agda 版）：量词规则与 Drinker 的构造面
module ex16_folnd where

open import Data.Nat using (ℕ; zero)
open import Data.Empty using (⊥; ⊥-elim)
open import Data.Product using (Σ; _,_; ∃)
open import Relation.Nullary using (¬_)

-- ---------- (1) 量词 de Morgan 的构造方向（零公理） ----------

all→¬∃¬ : (P : ℕ → Set) → (∀ x → P x) → ¬ (∃ λ x → ¬ (P x))
all→¬∃¬ P hall (x , npx) = npx (hall x)

∃¬→¬∀ : (P : ℕ → Set) → (∃ λ x → ¬ (P x)) → ¬ (∀ x → P x)
∃¬→¬∀ P (x , npx) hall = npx (hall x)

-- ---------- (3) Drinker 的 ¬¬ 版（构造性） ----------

-- 直觉上可证：若 ∀x.Px 则 0 就是 Drinker（前提真 + 结论即假设）
drinker-when-all : (P : ℕ → Set) → (∀ x → P x) →
                   ∃ λ x → P x → ∀ y → P y
drinker-when-all P hall = zero , λ _ → hall

-- 直觉上可证：若 ∃x.¬Px 则那个 x 也是 Drinker（前提假使蕴含空真）
drinker-when-ex¬ : (P : ℕ → Set) → (∃ λ x → ¬ (P x)) →
                   ∃ λ x → P x → ∀ y → P y
drinker-when-ex¬ P (x , npx) = x , λ hpx → ⊥-elim (npx hpx)

-- 完整 Drinker（∃x.Px→∀y.Py 无条件）在构造逻辑里不可证——
-- 需要对「∀x.Px 或 ∃x.¬Px」的判定（量词排中）。Agda 无经典公理
-- 可 Require——如实登记为「写出不来的定理」（13 章 Kripke 的
-- FOL 版反模型同理）。Coq/Lean/Isabelle/HOL4 通道承担完整版。

-- 坑位速记（Agda 侧）：
-- - Σ 与 ∃ 的选择：谓词论域 ℕ 时 ∃ λx → … 展开即 Σ ℕ …；
-- - drinker-when-ex¬ 的空真：⊥-elim 从 npx hpx 抽出任意目标
--   （∀y.Py 也不例外）；
-- - 构造边界如实登记——「条件 Drinker」两方向是能写的全部。
