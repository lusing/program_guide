-- ex04 —— 经典加成（Agda 版）：矩阵完整，本体缺位
-- Agda 无经典公理可 Require——矩阵（构造蕴涵）全给，本体留给 13 章反模型。

module ex04_classical where

open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Data.Product using (_×_; _,_)
open import Data.Empty using (⊥; ⊥-elim)
open import Relation.Nullary using (¬_)

-- ---------- 类型别名（命题层走 Set） ----------

LEM = (P : Set) → P ⊎ ¬ P
DNE = (P : Set) → ¬ (¬ P) → P
Peirce = (P Q : Set) → ((P → Q) → P) → P

-- ---------- ¬¬LEM 白送（经典性的「半个」事实） ----------

¬¬lem : (P : Set) → ¬ ¬ (P ⊎ ¬ P)
¬¬lem P h = h (inj₂ (λ p → h (inj₁ p)))

-- ---------- 矩阵 ----------

lem→dne : LEM → DNE
lem→dne lem P ¬¬p with lem P
... | inj₁ p  = p
... | inj₂ ¬p = ⊥-elim (¬¬p ¬p)

dne→lem : DNE → LEM
dne→lem dne P = dne (P ⊎ ¬ P) (¬¬lem P)

lem→peirce : LEM → Peirce
lem→peirce lem P Q f with lem P
... | inj₁ p  = p
... | inj₂ ¬p = ⊥-elim (¬p (f (λ p → ⊥-elim (¬p p))))

peirce→dne : Peirce → DNE
peirce→dne peirce P ¬¬p =
  peirce P ⊥ (λ ¬p → ⊥-elim (¬¬p ¬p))

clavius : DNE → (P : Set) → (¬ P → P) → P
clavius dne P f = dne P (λ ¬p → ¬p (f ¬p))

-- ---------- 本体缺位 ----------

-- 下面这些在 Agda 里【写不出来】：
--   lem : LEM
--   dne : DNE
-- 证不出 ≠ 不可证——13 章的 Kripke 两世界框架给出真反模型，
-- 那才是「不可证」的机器证据（把「无证明」升级为「有反例」）。

-- 坑位速记（Agda 侧）：
-- - with lem P 的分派里 inj₁/inj₂ 分支直接给值；
-- - ⊥-elim 吃任何目标——经典矩阵的「矛盾出口」全靠它；
-- - ¬¬lem 是构造可证的最强「半个 LEM」——dne→lem 的桥。
