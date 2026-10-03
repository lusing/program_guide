-- ex13 —— Kripke 语义：LEM 的两世界反例（Agda 版）
module ex13_kripke where

open import Data.Empty using (⊥)
open import Data.Nat using (ℕ; zero)
open import Data.Sum using (_⊎_; inj₁; inj₂)
open import Relation.Nullary using (¬_)
open import Relation.Binary.PropositionalEquality using (_≡_)

data Form : Set where
  fvar : ℕ → Form
  _→k_ : Form → Form → Form
  _∨k_ : Form → Form → Form
  ¬k_  : Form → Form

-- 两世界与可达关系（0 ⊑ 1）
data World : Set where
  w0 w1 : World

data _⊑_ : World → World → Set where
  r00 : w0 ⊑ w0
  r01 : w0 ⊑ w1
  r11 : w1 ⊑ w1

⊑-trans : ∀ {a b c} → a ⊑ b → b ⊑ c → a ⊑ c
⊑-trans r00 r' = r'
⊑-trans r01 r11 = r01
⊑-trans r11 r11 = r11

-- 原子知识：世界 0 无，世界 1 有
data Knows : World → ℕ → Set where
  k1 : ∀ {n} → Knows w1 n

knows-mono : ∀ {w w' n} → w ⊑ w' → Knows w n → Knows w' n
knows-mono r00 k = k
knows-mono r01 ()
knows-mono r11 k = k

-- 强制关系（函数式定义）
_⊩_ : World → Form → Set
w ⊩ fvar n = Knows w n
w ⊩ (a →k b) = ∀ w' → w ⊑ w' → w' ⊩ a → w' ⊩ b
w ⊩ (a ∨k b) = (w ⊩ a) ⊎ (w ⊩ b)
w ⊩ (¬k a) = ∀ w' → w ⊑ w' → w' ⊩ a → ⊥

-- ---------- 单调性（文档注记） ----------

-- 函数式 ⊩ 下 monotone 需对公式归纳展开——Coq 通道有完整版
-- （monotone 定理），此处聚焦 LEM 反例本体。

-- ---------- 旗舰：LEM 在世界 0 不被强制 ----------

lem-counter : ¬ (w0 ⊩ ((fvar 0) ∨k (¬k (fvar 0))))
lem-counter (inj₁ ())
lem-counter (inj₂ h) = h w1 r01 k1

-- 展开读法：
-- - 左支：w0 ⊩ fvar 0 即 Knows w0 0——数据类型无构造子，空模式；
-- - 右支：¬p 在 w0 被强制则对一切可达世界（含 w1）吸收 p 证据
--   得 ⊥——喂 r01 与 k1 即矛盾。

-- ---------- DNE 同倒 ----------

-- DNE（¬¬p→p）在两世界框架【不是】反例：w0 ⊮ ¬¬p，
-- 蕴含在 w0 空真成立。DNE 的 Kripke 反例需要原子知识
-- 「未来真假交替」的框架（Mints §7.2 的三世界例）——文档说明。

-- 坑位速记（Agda 侧）：
-- - 「无知」的类型化：Knows w0 n 无构造子——空模式 () 直接收；
-- - 喂可达世界：r01 是 0 ⊑ 1 的证据，与 k1 一起把 ¬ 分支
--   变成 ⊥；
-- - monotone 需公式归纳（函数式 ⊩ 下要 f 归纳展开）——
--   Coq 通道有完整版，此处聚焦反例。
