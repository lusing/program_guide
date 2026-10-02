-- ex01 —— 全景与 hello-logic（Agda 版）
-- 与 Coq/Lean 同一组定理；Agda 无经典公理可用，哨兵章只立「证不出」的事实。

module ex01_intro where

open import Data.Empty using (⊥)
open import Relation.Nullary using (¬_)

-- 命题层先用 Set 一层（教学取舍；深水区在第 11 章再谈层级）

mp : {P Q : Set} → (P → Q) → P → Q
mp = λ f p → f p

imp-trans : {P Q R : Set} → (P → Q) → (Q → R) → P → R
imp-trans f g p = g (f p)

¬¬-intro : {P : Set} → P → ¬ (¬ P)
¬¬-intro p ¬p = ¬p p

-- 经典哨兵：¬ ¬ P → P。
-- Agda 的正确姿势是「声明不可证」而不是 postulate——
-- 用反模型说话（第 13 章 Kripke 两世界框架）；
-- 这里先立一个可以证的邻居：Peirce 的「弱化版」也证不出，见 04 章。

-- 坑位速记（Agda 侧）：
-- - ¬_ 是 Relation.Nullary 的 (A → ⊥)；¬ (¬ P) 的括号不能省；
-- - 子句体里看不见未绑定的隐式参数——本文件全部走点式定义，天然免疫；
-- - Set 只有一层，P Q R 无需 Level。
