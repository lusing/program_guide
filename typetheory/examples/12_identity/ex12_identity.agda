----------------------------------------------------------------
-- 12 相等类型与 J（Nordström ch.8）—— Agda 侧手工课
-- Agda 的 J = 对 refl 的模式匹配；四件套每件一两行
----------------------------------------------------------------

open import Data.Nat using (ℕ; zero; suc; _+_)
open import Relation.Binary.PropositionalEquality using (_≡_; refl)

-- ---- 对称：refl 匹配即得（J 的第一赠品） ----
sym' : ∀ {A : Set} {a b : A} → a ≡ b → b ≡ a
sym' refl = refl

-- ---- 传递 ----
trans' : ∀ {A : Set} {a b c : A} → a ≡ b → b ≡ c → a ≡ c
trans' refl h2 = h2

-- ---- 同余 ----
cong' : ∀ {A B : Set} (f : A → B) {a b : A} → a ≡ b → f a ≡ f b
cong' f refl = refl

-- ---- 替换 / 搬运（Set 版 transport，Agda 无 Prop 门槛） ----
subst' : ∀ {A : Set} (P : A → Set) {a b : A} → a ≡ b → P a → P b
subst' P refl pa = pa

transport : ∀ {A : Set} (P : A → Set) {a b : A} → a ≡ b → P a → P b
transport = subst'

-- ---- 实测：1+1 的定义相等来回搬运 ----
one-one : 1 + 1 ≡ 2
one-one = refl

back-and-forth : 2 ≡ 2
back-and-forth = sym' (sym' one-one)

-- transport 搬运向量（长度证据跟值走）
data Vec (A : Set) : ℕ → Set where
  []  : Vec A zero
  _∷_ : ∀ {n} → A → Vec A n → Vec A (suc n)

shift-proof : ∀ {A : Set} → Vec A (1 + 1) → Vec A 2
shift-proof v = transport (Vec _) one-one v

-- ---- 内涵 vs 外延：J 的边界 ----
-- 处处相等推不出函数相等：下面这样的定义无法通过检查
-- funext-bad : ∀ {A B : Set} (f g : A → B) → (∀ x → f x ≡ g x) → f ≡ g
-- funext-bad f g h = ???  -- 对 h x 逐一归纳走不到 f ≡ g：
--                       refl 只吃定义相等。
-- Agda 世界里 funext 的出路：(1) V 形宇宙里当公理；
-- (2) 同伦路线（函数外延是泛等的定理——21 章见）。

-- ---- J 与 K：一墙之隔 ----
-- K 是「refl 唯一性」：∀ (P : a ≡ a → Set) → P refl → ∀ p → P p
-- K 可以由「对 p 匹配」直接得到——但那要求所有 refl 相等，
-- 即恒等类型无高维结构。Agda 用 --without-K 关掉这条推理，
-- HoTT 世界（19 章起）必须关。本章文件未开该旗标（默认即可用 K）。
