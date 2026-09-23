------------------------------------------------------------------------
-- Ex01_intro · 01 章示例：认识 Agda
--
-- 本文件只用「裸」的 Agda 就能整体类型检查通过：
--   cd agda && agda examples/Ex01_intro.agda
-- 它演示 Curry–Howard 对应的最小样本：证明就是一个函数。
------------------------------------------------------------------------

module Ex01_intro where

-- ℕ 是 Nat 的 Unicode 写法（ASCII 可打 \N 后按空格），来自标准库。
open import Data.Nat using (ℕ; _+_; _*_)

-- Agda 内建命题等式：_≡_（ASCII 写法 \==）。
open import Agda.Builtin.Equality

-------- 证明 = 函数 --------

-- 恒等函数「顺便」证明了「A 蕴含 A」；
-- 类型 {A : Set} → A → A 读作「对任意类型 A，A → A 成立」。
identity : {A : Set} → A → A
identity x = x

-- modus ponens（肯定前件）：「P 蕴含 Q」加上「P 成立」得到「Q 成立」——
-- 逻辑推理就是函数应用。
modus-ponens : {P Q : Set} → (P → Q) → P → Q
modus-ponens f p = f p

-- 一个具体的等式证明。证明体只有 refl 一个词：
-- 因为 2 + 3 会归约（计算）成 5，两边「定义相等」，refl 即可。
-- 交互式会话里的 Compute (2 + 3) 得到的 = 5，在这里等价于：
_ : 2 + 3 ≡ 5
_ = refl

-- 把上面两个「定理」用起来，证明才算「被使用」：
_ : 2 + 3 ≡ 5
_ = modus-ponens identity refl

-- 乘法的计算也被 refl 一口气「看穿」：
answer : ℕ
answer = 6 * 7

_ : answer ≡ 42
_ = refl

-------- 逃生门：postulate --------

-- 终止性检查不允许我们写「算不出结果」的函数，
-- 但 postulate 允许我们不给出任何实现就承认一个居民存在。
-- 下面的 magic 没有任何计算内容——它是我们「假设」出来的自然数。
postulate
  magic : ℕ

-- postulate 出来的东西照样参与类型推理：自反性仍然成立。
_ : magic ≡ magic
_ = refl
